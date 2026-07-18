#!/usr/bin/env bash
# Plant Jardinagem — PDF robusto v2 (timeout por foto + maxDuration + tratamento de erro)
set -e
if [ ! -f package.json ]; then echo "Rode na raiz do projeto."; exit 1; fi
echo "Atualizando rota do PDF..."

mkdir -p "src/app/api/relatorios/[id]/pdf"
cat > "src/app/api/relatorios/[id]/pdf/route.ts" <<'__PLANT_EOF__'
import { NextResponse } from "next/server";
import { renderToBuffer } from "@react-pdf/renderer";
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

// Baixa uma imagem e devolve como data URL (base64). Se já for base64, retorna como está.
async function paraBase64(src: string): Promise<string | undefined> {
  if (!src) return undefined;
  if (src.startsWith("data:")) return src;
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 8000);
  try {
    const res = await fetch(src, { cache: "no-store", signal: ctrl.signal });
    if (!res.ok) return undefined;
    const tipo = res.headers.get("content-type") || "image/jpeg";
    const buf = Buffer.from(await res.arrayBuffer());
    return `data:${tipo};base64,${buf.toString("base64")}`;
  } catch {
    return undefined;
  } finally {
    clearTimeout(timer);
  }
}

async function resolverFotos(urls: string[]): Promise<string[]> {
  const resolvidas = await Promise.all(urls.map(paraBase64));
  return resolvidas.filter((x): x is string => Boolean(x));
}

async function carregarLogo(origin: string): Promise<string | undefined> {
  return paraBase64(`${origin}/logo.png`);
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

  // Baixa logo e todas as fotos em paralelo, embutindo como base64.
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
echo "Feito. git add -A && git commit && git push (aguarde o deploy na Vercel terminar)."
