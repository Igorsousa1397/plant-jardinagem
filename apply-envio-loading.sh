#!/usr/bin/env bash
# Plant Jardinagem — sem about:blank no mobile + loading 'Gerando PDF'
set -e
if [ ! -f package.json ]; then echo "Rode na raiz do projeto."; exit 1; fi
echo "Atualizando envio ao síndico..."

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

  const podeCompartilharArquivo = () => {
    try {
      const nav = navigator as Navigator & { canShare?: (d?: ShareData) => boolean };
      if (!nav.canShare) return false;
      const dummy = new File([new Blob(["x"])], "t.pdf", { type: "application/pdf" });
      return nav.canShare({ files: [dummy] });
    } catch {
      return false;
    }
  };

  const enviarWhats = async () => {
    if (gerando) return;
    const texto = `Relatório de serviço — ${r.condo} (${r.data}).`;
    const slug = r.condo.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
    const destino = telSindico
      ? `https://wa.me/55${telSindico}?text=${encodeURIComponent(texto)}`
      : `https://wa.me/?text=${encodeURIComponent(texto)}`;

    const compartilha = podeCompartilharArquivo();
    // Só o desktop precisa pré-abrir a aba (evita bloqueio de popup). No celular o share resolve.
    const win = compartilha ? null : window.open("", "_blank");

    setGerando(true);
    try {
      const res = await fetch(`/api/relatorios/${r.id}/pdf`);
      if (!res.ok) throw new Error("pdf");
      const blob = await res.blob();
      const file = new File([blob], `relatorio-${slug}.pdf`, { type: "application/pdf" });

      if (compartilha) {
        // Celular: folha de compartilhamento com o PDF anexado
        const nav = navigator as Navigator & { share: (d: ShareData) => Promise<void> };
        try {
          await nav.share({ files: [file], title: `Relatório — ${r.condo}`, text: texto });
        } catch {
          /* usuário cancelou o compartilhamento */
        }
        return;
      }

      // Desktop: baixa o PDF e leva a aba pré-aberta ao WhatsApp
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = file.name;
      a.click();
      URL.revokeObjectURL(url);
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
echo "Feito. Reinicie o npm run dev (ou commit + push)."
