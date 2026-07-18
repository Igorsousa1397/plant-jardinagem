#!/usr/bin/env bash
# Plant Jardinagem — correção completa do envio do PDF (comprime fotos + desktop baixa 1x)
set -e
if [ ! -f package.json ]; then echo "Rode na raiz do projeto."; exit 1; fi
if [ ! -d node_modules/sharp ]; then echo "Instalando sharp..."; npm install sharp; fi
echo "Aplicando correções..."

mkdir -p "src/app/api/relatorios/[id]/pdf"
cat > "src/app/api/relatorios/[id]/pdf/route.ts" <<'__PLANT_EOF__'
import { NextResponse } from "next/server";
import { renderToBuffer } from "@react-pdf/renderer";
import sharp from "sharp";
import { createClient } from "@/lib/supabase/server";
import { RelatorioPDF } from "@/components/pdf/RelatorioPDF";
import type { Report, Status } from "@/types";
import { fmtData } from "@/lib/utils";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
export const maxDuration = 60;

interface Row {
  id: string;
  condo: string;
  data: string;
  duracao: string;
  status: Status;
  servicos: string[] | null;
  equipamentos: string[] | null;
  epi: string[] | null;
  observacoes: string | null;
  proxima_visita: string | null;
  fotos_antes: string[] | null;
  fotos_depois: string[] | null;
}

// Devolve o buffer da imagem, seja ela URL (Storage) ou base64 (relatórios antigos).
async function bufferDaImagem(src: string): Promise<Buffer | undefined> {
  if (!src) return undefined;
  try {
    if (src.startsWith("data:")) {
      const base64 = src.split(",")[1] ?? "";
      return base64 ? Buffer.from(base64, "base64") : undefined;
    }
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), 8000);
    try {
      const res = await fetch(src, { cache: "no-store", signal: ctrl.signal });
      if (!res.ok) return undefined;
      return Buffer.from(await res.arrayBuffer());
    } finally {
      clearTimeout(timer);
    }
  } catch {
    return undefined;
  }
}

// Comprime a foto (redimensiona + JPEG) e devolve como data URL — mantém o PDF leve.
async function comprimirFoto(src: string): Promise<string | undefined> {
  const buf = await bufferDaImagem(src);
  if (!buf) return undefined;
  try {
    const out = await sharp(buf)
      .rotate()
      .resize(1400, 1400, { fit: "inside", withoutEnlargement: true })
      .jpeg({ quality: 72 })
      .toBuffer();
    return `data:image/jpeg;base64,${out.toString("base64")}`;
  } catch {
    return undefined;
  }
}

async function resolverFotos(urls: string[]): Promise<string[]> {
  const resolvidas = await Promise.all(urls.map(comprimirFoto));
  return resolvidas.filter((x): x is string => Boolean(x));
}

async function carregarLogo(origin: string): Promise<string | undefined> {
  try {
    const res = await fetch(`${origin}/logo.png`);
    if (!res.ok) return undefined;
    const buf = Buffer.from(await res.arrayBuffer());
    return `data:image/png;base64,${buf.toString("base64")}`;
  } catch {
    return undefined;
  }
}

export async function GET(req: Request, { params }: { params: { id: string } }) {
  const sb = createClient();
  const {
    data: { user },
  } = await sb.auth.getUser();
  if (!user) return new NextResponse("Não autorizado", { status: 401 });

  const { data, error } = await sb.from("relatorios").select("*").eq("id", params.id).maybeSingle();
  if (error || !data) return new NextResponse("Relatório não encontrado", { status: 404 });

  const r = data as Row;
  const origin = new URL(req.url).origin;

  const [logoSrc, fotosAntes, fotosDepois] = await Promise.all([
    carregarLogo(origin),
    resolverFotos(r.fotos_antes ?? []),
    resolverFotos(r.fotos_depois ?? []),
  ]);

  const report: Report = {
    id: r.id,
    condo: r.condo,
    data: fmtData(r.data),
    duracao: r.duracao,
    status: r.status,
    servicos: r.servicos ?? [],
    equipamentos: r.equipamentos ?? [],
    epi: r.epi ?? [],
    observacoes: r.observacoes ?? "",
    proximaVisita: r.proxima_visita ? fmtData(r.proxima_visita) : "",
    fotosAntes,
    fotosDepois,
  };

  try {
    const buffer = await renderToBuffer(RelatorioPDF({ report, logoSrc }));
    const slug = report.condo.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
    return new NextResponse(new Uint8Array(buffer), {
      headers: {
        "Content-Type": "application/pdf",
        "Content-Disposition": `inline; filename="relatorio-${slug}.pdf"`,
      },
    });
  } catch (e) {
    console.error("Erro ao gerar PDF do relatório:", e);
    return new NextResponse("Erro ao gerar o PDF", { status: 500 });
  }
}
__PLANT_EOF__
echo "  ok  src/app/api/relatorios/[id]/pdf/route.ts"

mkdir -p "src/components/relatorios"
cat > "src/components/relatorios/ReportPreview.tsx" <<'__PLANT_EOF__'
"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import type { Report } from "@/types";
import { EMPRESA } from "@/lib/constants";
import { listClientes } from "@/lib/clientes";
import { soDigitos } from "@/lib/utils";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { GardenSVG } from "./GardenSVG";

export function ReportPreview({ r }: { r: Report }) {
  const router = useRouter();
  const [toast, setToast] = useState("");
  const [telSindico, setTelSindico] = useState("");
  const [gerando, setGerando] = useState(false);
  const fire = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(""), 2200);
  };

  useEffect(() => {
    listClientes()
      .then((cs) => {
        const cli = cs.find((c) => c.nome.toLowerCase() === r.condo.toLowerCase());
        setTelSindico(cli?.telefone ? soDigitos(cli.telefone) : "");
      })
      .catch(() => setTelSindico(""));
  }, [r.condo]);

  const fotos = [
    ...r.fotosAntes.map((s) => ({ s, depois: false })),
    ...r.fotosDepois.map((s) => ({ s, depois: true })),
  ];

  const baixarBlob = (blob: Blob, nome: string) => {
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = nome;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    // Deixa o download começar antes de liberar a URL.
    setTimeout(() => URL.revokeObjectURL(url), 4000);
  };

  const enviarWhats = async () => {
    if (gerando) return;
    const texto = `Relatório de serviço — ${r.condo} (${r.data}).`;
    const slug = r.condo.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
    const nome = `relatorio-${slug}.pdf`;
    const destino = telSindico
      ? `https://wa.me/55${telSindico}?text=${encodeURIComponent(texto)}`
      : `https://wa.me/?text=${encodeURIComponent(texto)}`;

    const ehMobile = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
    // No desktop pré-abrimos a aba já no clique (evita bloqueio de popup).
    const win = ehMobile ? null : window.open("", "_blank");

    setGerando(true);
    try {
      const res = await fetch(`/api/relatorios/${r.id}/pdf`);
      if (!res.ok) throw new Error("pdf");
      const blob = await res.blob();
      const file = new File([blob], nome, { type: "application/pdf" });

      // Celular: folha de compartilhamento com o PDF anexado.
      const nav = navigator as Navigator & {
        canShare?: (d?: ShareData) => boolean;
        share?: (d: ShareData) => Promise<void>;
      };
      if (ehMobile && nav.canShare && nav.share && nav.canShare({ files: [file] })) {
        try {
          await nav.share({ files: [file], title: `Relatório — ${r.condo}`, text: texto });
        } catch {
          /* usuário cancelou */
        }
        return;
      }

      // Desktop: baixa o PDF e leva a aba pré-aberta ao WhatsApp Web.
      baixarBlob(blob, nome);
      fire("PDF baixado — anexe no WhatsApp");
      if (win && !win.closed) win.location.href = destino;
      else window.open(destino, "_blank");
    } catch {
      fire("Não foi possível gerar o PDF");
      if (win && !win.closed) win.location.href = destino;
    } finally {
      setGerando(false);
    }
  };

  return (
    <div className="pb-24">
      <header className="flex items-center gap-3 px-[18px] pb-1.5 pt-[18px]">
        <button onClick={() => router.push("/admin/home")} className="grid h-[34px] w-[34px] place-items-center rounded-full border border-linha bg-surface text-[22px] leading-none text-verde-800">‹</button>
        <span className="font-mono text-[11px] uppercase tracking-wider text-tintaMuda">Pré-visualização</span>
      </header>

      <article className="mx-3.5 mt-1.5 overflow-hidden rounded-[18px] border border-linha bg-surface shadow-s2">
        <div className="bg-gradient-to-br from-verde-800 to-verde-900 px-[18px] py-5 text-white">
          <div className="flex items-center gap-2.5">
            <div className="grid h-10 w-10 flex-none place-items-center rounded-[10px] bg-papel p-1">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src="/logo.png" alt="Plant Jardinagem" className="h-full w-full object-contain" />
            </div>
            <div>
              <div className="font-display text-[17px] font-semibold leading-tight">Relatório de Serviço</div>
              <div className="font-mono text-xs opacity-70">Plant Jardinagem · {r.data}</div>
            </div>
          </div>
        </div>

        <div className="px-[18px] py-4">
          <div className="mb-3 flex items-start justify-between gap-2.5">
            <h2 className="font-display text-xl font-semibold text-verde-900">{r.condo}</h2>
            <Badge status={r.status} />
          </div>

          <div className="mb-3.5 grid grid-cols-2 gap-0.5 overflow-hidden rounded-xl bg-linha">
            {fotos.length === 0 ? (
              <>
                <Cell label="ANTES"><GardenSVG /></Cell>
                <Cell label="DEPOIS"><GardenSVG depois /></Cell>
              </>
            ) : (
              fotos.map((f, i) => (
                <Cell key={i} label={f.depois ? "DEPOIS" : "ANTES"}>
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={f.s} alt="" className="h-full w-full object-cover" />
                </Cell>
              ))
            )}
          </div>

          <div className="mb-3.5 flex items-center gap-2.5 rounded-[10px] border border-verde-200 bg-verde-50 px-3 py-2.5">
            <div className="grid h-[34px] w-[34px] flex-none place-items-center rounded-[9px] bg-verde-700">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2"><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></svg>
            </div>
            <div>
              <div className="font-mono text-[11px] uppercase tracking-wide text-tintaMuda">Duração do serviço</div>
              <div className="text-[15px] font-bold text-verde-900">{r.duracao}</div>
            </div>
          </div>

          <Bloco titulo="Serviços realizados" itens={r.servicos} />
          {r.equipamentos.length > 0 && <Bloco titulo="Equipamentos" itens={r.equipamentos} />}

          {r.observacoes && (
            <div className="mt-3">
              <div className="font-mono text-[11px] uppercase tracking-wider text-tintaMuda">Observações</div>
              <p className="mt-1.5 text-sm text-tinta">{r.observacoes}</p>
            </div>
          )}

          <div className="mt-4 border-t border-linha pt-3 font-mono text-[11px] leading-relaxed text-tintaMuda">
            {EMPRESA.nome} · CNPJ {EMPRESA.cnpj}<br />
            {EMPRESA.telefone} · {EMPRESA.email}<br />
            Fotos autorizadas pelo cliente.
          </div>
        </div>
      </article>

      <div className="flex gap-3 px-[18px] py-1">
        <Button block disabled={gerando} onClick={enviarWhats}>
          {gerando ? "Gerando PDF…" : "Enviar ao síndico"}
        </Button>
      </div>

      {toast && (
        <div className="fixed bottom-24 left-1/2 z-40 -translate-x-1/2 whitespace-nowrap rounded-full bg-verde-900 px-4.5 py-2.5 text-[13px] font-semibold text-white shadow-s3">
          {toast}
        </div>
      )}
    </div>
  );
}

function Cell({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="relative aspect-square">
      {children}
      <span className="absolute left-1.5 top-1.5 rounded-full bg-[rgba(28,38,32,.72)] px-1.5 py-[3px] font-mono text-[9px] font-semibold tracking-wider text-white">
        {label}
      </span>
    </div>
  );
}

function Bloco({ titulo, itens }: { titulo: string; itens: string[] }) {
  return (
    <div className="mt-3">
      <div className="font-mono text-[11px] uppercase tracking-wider text-tintaMuda">{titulo}</div>
      <div className="mt-1.5 flex flex-wrap gap-1.5">
        {itens.map((x) => (
          <span key={x} className="rounded-full bg-salviaSurface px-3 py-1.5 text-[13px] font-semibold text-verde-700">{x}</span>
        ))}
      </div>
    </div>
  );
}
__PLANT_EOF__
echo "  ok  src/components/relatorios/ReportPreview.tsx"

echo ""
echo "IMPORTANTE: git add -A && git commit && git push, e AGUARDE o deploy na Vercel ficar Ready antes de testar."
