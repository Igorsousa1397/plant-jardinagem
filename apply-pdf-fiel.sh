#!/usr/bin/env bash
# Plant Jardinagem — PDF fiel ao modelo original do relatório
set -e
if [ ! -f package.json ]; then echo "Rode na raiz do projeto."; exit 1; fi
echo "Atualizando layout do PDF..."

mkdir -p "src/lib"
cat > "src/lib/constants.ts" <<'__PLANT_EOF__'
import type { Status } from "@/types";

export const SERVICOS = [
  "Corte e Poda",
  "Remoção de Folhas / Galhos",
  "Paisagismo",
  "Limpeza Geral do Jardim",
  "Adubação",
  "Controle de pragas",
];

export const EQUIPAMENTOS = [
  "Roçadeira",
  "Soprador",
  "Rastelo",
  "Tesoura de Poda",
  "Tesoura de Cerca Viva",
];

export const EPIS = ["Luvas", "Botas", "Óculos de Proteção"];

export const CONDOS = [
  "Alameda das Palmeiras",
  "San Denis",
  "Quinta do Moinho",
  "Quinta do Loureiro",
  "dos Girassóis",
];

// Classes literais para o JIT do Tailwind capturar
export const STATUS_STYLES: Record<Status, string> = {
  "Finalizado": "bg-sucessoBg text-sucesso",
  "Em andamento": "bg-atencaoBg text-atencao",
  "Agendado": "bg-infoBg text-info",
  "Atrasado": "bg-erroBg text-erro",
};

export const EMPRESA = {
  nome: "Plant Jardinagem e Paisagismo",
  prestador: "Plant Jardinagem - Manutenção e Paisagismo / Claiton",
  cnpj: "42.704.559/0001-42",
  telefone: "(11) 97179-2236",
  whatsapp: "5511971792236",
  email: "plantjardinagem@gmail.com",
  instagram: "@plantjardinagem",
};
__PLANT_EOF__
echo "  ok  src/lib/constants.ts"

mkdir -p "src/components/pdf"
cat > "src/components/pdf/RelatorioPDF.tsx" <<'__PLANT_EOF__'
import { Document, Page, View, Text, Image, StyleSheet } from "@react-pdf/renderer";
import type { Report } from "@/types";
import { EMPRESA } from "@/lib/constants";

const C = {
  tinta: "#1C2620",
  tintaMuda: "#5A6660",
  linha: "#D9D7CE",
};

const s = StyleSheet.create({
  page: { backgroundColor: "#FFFFFF", paddingTop: 40, paddingBottom: 56, paddingHorizontal: 48, fontSize: 11, color: C.tinta, fontFamily: "Helvetica", lineHeight: 1.4 },
  logoWrap: { alignItems: "center", marginBottom: 6 },
  logo: { width: 120, height: 120, objectFit: "contain" },
  title: { fontSize: 19, fontFamily: "Helvetica-Bold", textAlign: "center" },
  emissao: { fontSize: 11, textAlign: "center", marginTop: 6, marginBottom: 18 },

  line: { fontSize: 11, marginBottom: 7 },
  bold: { fontFamily: "Helvetica-Bold" },

  divider: { borderBottomWidth: 1, borderBottomColor: C.linha, marginTop: 6, marginBottom: 14 },
  heading: { fontSize: 13, fontFamily: "Helvetica-Bold", marginBottom: 9 },
  item: { fontSize: 11, marginBottom: 6 },
  obs: { fontSize: 11, lineHeight: 1.5 },
  emitido: { fontSize: 10, textAlign: "right", color: C.tintaMuda, marginTop: 4 },

  fotosHeading: { fontSize: 12, fontFamily: "Helvetica-Bold", textAlign: "center", marginTop: 18, marginBottom: 12 },
  grid: { flexDirection: "row", flexWrap: "wrap", gap: 8 },
  cell: { width: "31%" },
  foto: { width: "100%", height: 150, objectFit: "cover", borderRadius: 4 },

  footer: { marginTop: 24, textAlign: "center", fontSize: 9, color: C.tintaMuda, lineHeight: 1.6 },
});

function Lista({ titulo, itens }: { titulo: string; itens: string[] }) {
  if (!itens.length) return null;
  return (
    <View>
      <Text style={s.heading}>{titulo}</Text>
      {itens.map((x, i) => (
        <Text key={i} style={s.item}>{x}</Text>
      ))}
      <View style={s.divider} />
    </View>
  );
}

export function RelatorioPDF({ report, logoSrc }: { report: Report; logoSrc?: string }) {
  return (
    <Document title={`Relatório - ${report.condo}`}>
      <Page size="A4" style={s.page}>
        {logoSrc ? (
          <View style={s.logoWrap}>
            <Image src={logoSrc} style={s.logo} />
          </View>
        ) : null}
        <Text style={s.title}>Relatório de Serviço Realizado</Text>
        <Text style={s.emissao}>Data de Emissão: {report.data}</Text>

        <Text style={s.line}>
          <Text style={s.bold}>Empresa/Prestador de Serviço: </Text>
          {EMPRESA.prestador}
        </Text>
        <Text style={s.line}>CNPJ: {EMPRESA.cnpj}</Text>
        <Text style={s.line}>Whatsapp: {EMPRESA.telefone}</Text>
        <Text style={s.line}>Email: {EMPRESA.email}</Text>
        <Text style={s.line}>Instagram: {EMPRESA.instagram}</Text>
        <View style={s.divider} />

        <Text style={s.heading}>Dados do Cliente</Text>
        <Text style={s.item}>
          <Text style={s.bold}>Cliente: </Text>
          {report.condo}
        </Text>
        <View style={s.divider} />

        <Lista titulo="Serviços Realizados" itens={report.servicos} />
        <Lista titulo="Equipamentos Utilizados" itens={report.equipamentos} />
        <Lista titulo="Equipamentos EPI Utilizados" itens={report.epi} />

        <Text style={s.line}>
          <Text style={s.bold}>Duração do Serviço: </Text>
          {report.duracao}
        </Text>
        <View style={s.divider} />

        {report.observacoes ? (
          <View>
            <Text style={s.heading}>Observações</Text>
            <Text style={s.obs}>{report.observacoes}</Text>
            <View style={s.divider} />
          </View>
        ) : null}

        <Text style={s.heading}>Status</Text>
        <Text style={s.item}>{report.status.toUpperCase()}</Text>
        <View style={s.divider} />

        <Text style={s.emitido}>Emitido em: {report.data}</Text>

        {report.fotosAntes.length > 0 && (
          <View>
            <Text style={s.fotosHeading}>FOTOS ANTES</Text>
            <View style={s.grid}>
              {report.fotosAntes.map((src, i) => (
                <View key={i} style={s.cell} wrap={false}>
                  <Image src={src} style={s.foto} />
                </View>
              ))}
            </View>
          </View>
        )}

        {report.fotosDepois.length > 0 && (
          <View>
            <Text style={s.fotosHeading}>FOTOS DEPOIS</Text>
            <View style={s.grid}>
              {report.fotosDepois.map((src, i) => (
                <View key={i} style={s.cell} wrap={false}>
                  <Image src={src} style={s.foto} />
                </View>
              ))}
            </View>
          </View>
        )}

        <Text style={s.footer}>
          Fotos autorizadas pelo cliente {report.condo}
          {"\n"}© Todos os direitos reservados
        </Text>
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

  const logoSrc = await carregarLogo(new URL(req.url).origin);
  const buffer = await renderToBuffer(RelatorioPDF({ report, logoSrc }));
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

echo ""
echo "Feito. Reinicie o npm run dev (ou commit + push)."
