#!/usr/bin/env bash
# Plant Jardinagem — geração de PDF do relatório (server + @react-pdf)
# IMPORTANTE: rode antes  ->  npm install @react-pdf/renderer
set -e

if [ ! -f package.json ]; then echo "Rode na raiz do projeto."; exit 1; fi
if ! grep -q "@react-pdf/renderer" package.json; then
  echo "AVISO: @react-pdf/renderer não está no package.json. Rode:  npm install @react-pdf/renderer"
fi
echo "Aplicando geração de PDF..."

mkdir -p "."
cat > "next.config.mjs" <<'__PLANT_EOF__'
/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    remotePatterns: [{ protocol: "https", hostname: "*.supabase.co" }],
  },
  experimental: {
    serverComponentsExternalPackages: ["@react-pdf/renderer"],
  },
};
export default nextConfig;
__PLANT_EOF__
echo "  ok  next.config.mjs"

mkdir -p "src/components/pdf"
cat > "src/components/pdf/RelatorioPDF.tsx" <<'__PLANT_EOF__'
import { Document, Page, View, Text, Image, StyleSheet } from "@react-pdf/renderer";
import type { Report } from "@/types";

const C = {
  verde800: "#1E3A2B", verde900: "#15281C", verde700: "#275139",
  dourado: "#C2941F", papel: "#FAF8F3", tinta: "#1C2620",
  tintaMuda: "#5A6660", linha: "#E4E2D8", verde50: "#F3F8F4",
  salvia: "#EDF0E7", sucesso: "#2E7D46",
};

const s = StyleSheet.create({
  page: { backgroundColor: "#FFFFFF", paddingBottom: 64, fontSize: 11, color: C.tinta },
  header: { backgroundColor: C.verde800, color: "#FFFFFF", padding: 24 },
  brand: { fontSize: 10, color: C.dourado, letterSpacing: 1, textTransform: "uppercase", marginBottom: 4 },
  headerTitle: { fontSize: 20, fontFamily: "Helvetica-Bold" },
  headerSub: { fontSize: 10, color: "#C5E0CE", marginTop: 2 },
  body: { padding: 24 },
  titleRow: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 14 },
  condo: { fontSize: 18, fontFamily: "Helvetica-Bold", color: C.verde900 },
  badge: { fontSize: 9, color: C.sucesso, backgroundColor: "#E6F4EA", paddingVertical: 4, paddingHorizontal: 10, borderRadius: 999 },
  fotos: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 16 },
  fotoBox: { width: "48.5%", position: "relative" },
  foto: { width: "100%", height: 150, borderRadius: 8, objectFit: "cover" },
  fotoLabel: { position: "absolute", top: 6, left: 6, fontSize: 7, color: "#FFFFFF", backgroundColor: "rgba(28,38,32,0.75)", paddingVertical: 2, paddingHorizontal: 6, borderRadius: 999 },
  infoRow: { flexDirection: "row", gap: 12, marginBottom: 16 },
  infoBox: { flex: 1, backgroundColor: C.verde50, borderRadius: 8, padding: 12 },
  infoLabel: { fontSize: 8, color: C.tintaMuda, letterSpacing: 0.5, marginBottom: 3 },
  infoVal: { fontSize: 13, fontFamily: "Helvetica-Bold", color: C.verde900 },
  section: { fontSize: 8, color: C.tintaMuda, letterSpacing: 0.6, textTransform: "uppercase", marginTop: 10, marginBottom: 6 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: 6 },
  chip: { fontSize: 10, color: C.verde700, backgroundColor: C.salvia, paddingVertical: 5, paddingHorizontal: 10, borderRadius: 999 },
  obs: { fontSize: 11, color: C.tinta, lineHeight: 1.4 },
  footer: { position: "absolute", bottom: 0, left: 0, right: 0, padding: 18, borderTopWidth: 1, borderTopColor: C.linha, color: C.tintaMuda, fontSize: 8, lineHeight: 1.5 },
});

export function RelatorioPDF({ report }: { report: Report }) {
  const fotos = [
    ...report.fotosAntes.map((src) => ({ src, depois: false })),
    ...report.fotosDepois.map((src) => ({ src, depois: true })),
  ];

  return (
    <Document title={`Relatório - ${report.condo}`}>
      <Page size="A4" style={s.page}>
        <View style={s.header}>
          <Text style={s.brand}>Plant Jardinagem</Text>
          <Text style={s.headerTitle}>Relatório de Serviço</Text>
          <Text style={s.headerSub}>{report.data}</Text>
        </View>

        <View style={s.body}>
          <View style={s.titleRow}>
            <Text style={s.condo}>{report.condo}</Text>
            <Text style={s.badge}>{report.status}</Text>
          </View>

          {fotos.length > 0 && (
            <View style={s.fotos}>
              {fotos.map((f, i) => (
                <View key={i} style={s.fotoBox}>
                  <Image src={f.src} style={s.foto} />
                  <Text style={s.fotoLabel}>{f.depois ? "DEPOIS" : "ANTES"}</Text>
                </View>
              ))}
            </View>
          )}

          <View style={s.infoRow}>
            <View style={s.infoBox}>
              <Text style={s.infoLabel}>PRÓXIMA VISITA</Text>
              <Text style={s.infoVal}>{report.proximaVisita || "A combinar"}</Text>
            </View>
            <View style={s.infoBox}>
              <Text style={s.infoLabel}>DURAÇÃO</Text>
              <Text style={s.infoVal}>{report.duracao}</Text>
            </View>
          </View>

          <Text style={s.section}>Serviços realizados</Text>
          <View style={s.chips}>
            {report.servicos.map((x, i) => (
              <Text key={i} style={s.chip}>{x}</Text>
            ))}
          </View>

          {report.equipamentos.length > 0 && (
            <>
              <Text style={s.section}>Equipamentos</Text>
              <View style={s.chips}>
                {report.equipamentos.map((x, i) => (
                  <Text key={i} style={s.chip}>{x}</Text>
                ))}
              </View>
            </>
          )}

          {report.observacoes ? (
            <>
              <Text style={s.section}>Observações</Text>
              <Text style={s.obs}>{report.observacoes}</Text>
            </>
          ) : null}
        </View>

        <View style={s.footer} fixed>
          <Text>Plant Jardinagem e Paisagismo · CNPJ 42.704.559/0001-42</Text>
          <Text>(11) 97179-2236 · plantjardinagem@gmail.com · Fotos autorizadas pelo cliente.</Text>
        </View>
      </Page>
    </Document>
  );
}
__PLANT_EOF__
echo "  ok  src/components/pdf/RelatorioPDF.tsx"

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

export async function GET(_req: Request, { params }: { params: { id: string } }) {
  const sb = createClient();
  const {
    data: { user },
  } = await sb.auth.getUser();
  if (!user) return new NextResponse("Não autorizado", { status: 401 });

  const { data, error } = await sb.from("relatorios").select("*").eq("id", params.id).maybeSingle();
  if (error || !data) return new NextResponse("Relatório não encontrado", { status: 404 });

  const r = data as Row;
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
    fotosAntes: r.fotos_antes ?? [],
    fotosDepois: r.fotos_depois ?? [],
  };

  const buffer = await renderToBuffer(RelatorioPDF({ report }));
  const slug = report.condo.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");

  return new NextResponse(new Uint8Array(buffer), {
    headers: {
      "Content-Type": "application/pdf",
      "Content-Disposition": `inline; filename="relatorio-${slug}.pdf"`,
    },
  });
}
__PLANT_EOF__
echo "  ok  src/app/api/relatorios/[id]/pdf/route.ts"

mkdir -p "src/components/relatorios"
cat > "src/components/relatorios/ReportPreview.tsx" <<'__PLANT_EOF__'
"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import type { Report } from "@/types";
import { EMPRESA } from "@/lib/constants";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { GardenSVG } from "./GardenSVG";

export function ReportPreview({ r }: { r: Report }) {
  const router = useRouter();
  const [toast, setToast] = useState("");
  const fire = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(""), 2200);
  };

  const fotos = [
    ...r.fotosAntes.map((s) => ({ s, depois: false })),
    ...r.fotosDepois.map((s) => ({ s, depois: true })),
  ];

  const enviarWhats = () => {
    const texto = encodeURIComponent(
      `Relatório de serviço — ${r.condo} (${r.data}). Próxima visita: ${r.proximaVisita}.`
    );
    // No app real: usar o telefone do síndico
    window.open(`https://wa.me/?text=${texto}`, "_blank");
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
            <div className="grid h-10 w-10 place-items-center rounded-full border-2 border-dourado">
              <span className="font-display text-base font-bold text-dourado">Pl</span>
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
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2"><rect x="3" y="4" width="18" height="18" rx="2" /><path d="M3 9h18M8 2v4M16 2v4" /></svg>
            </div>
            <div>
              <div className="font-mono text-[11px] uppercase tracking-wide text-tintaMuda">Próxima visita</div>
              <div className="text-[15px] font-bold text-verde-900">{r.proximaVisita || "A combinar"}</div>
            </div>
            <div className="ml-auto text-right">
              <div className="font-mono text-[11px] uppercase tracking-wide text-tintaMuda">Duração</div>
              <div className="font-mono text-[15px] font-bold text-verde-900">{r.duracao}</div>
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
        <Button variant="gold" block onClick={() => window.open(`/api/relatorios/${r.id}/pdf`, "_blank")}>Gerar PDF</Button>
        <Button block onClick={enviarWhats}>Enviar ao síndico</Button>
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
echo "Feito. Reinicie o npm run dev e/ou faça commit + push para a Vercel."
