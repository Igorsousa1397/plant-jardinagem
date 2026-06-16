import { Document, Page, View, Text, Image, StyleSheet } from "@react-pdf/renderer";
import type { Proposta } from "@/types";
import { EMPRESA } from "@/lib/constants";
import { PROPOSTA, ESCOPOS, ESCOPO_PADRAO } from "@/lib/proposta-conteudo";
import { fmtBRL, dataExtenso } from "@/lib/utils";

const C = {
  sage: "#8A9A76",
  escuro: "#1A3022",
  titulo: "#13251A",
  claro: "#E9EEDD",
  linha: "#6B4A2E",
};

const s = StyleSheet.create({
  page: { backgroundColor: C.sage, paddingTop: 54, paddingBottom: 96, paddingHorizontal: 54, fontSize: 11, color: C.escuro, fontFamily: "Helvetica", lineHeight: 1.5 },
  frame: { position: "absolute", top: 22, left: 22, right: 22, bottom: 22, borderWidth: 1, borderColor: C.linha, borderRadius: 2 },
  logo: { position: "absolute", bottom: 30, right: 34, width: 60, height: 60, objectFit: "contain" },

  titulo: { fontSize: 38, fontFamily: "Helvetica-Bold", color: C.titulo, lineHeight: 1.05 },
  subtitulo: { fontSize: 14, color: C.escuro, marginTop: 2 },
  local: { fontSize: 11, color: C.claro, textAlign: "right", marginTop: 26, marginBottom: 22 },
  paragrafo: { fontSize: 11.5, color: C.escuro, marginBottom: 14 },

  refTitulo: { fontSize: 12, fontFamily: "Helvetica-Bold", color: C.escuro, marginBottom: 8 },
  refCondo: { fontSize: 11, color: C.claro },
  refSindico: { fontSize: 11, color: C.claro, marginBottom: 10 },

  h1: { fontSize: 24, fontFamily: "Helvetica-Bold", color: C.titulo, marginBottom: 18 },
  h2: { fontSize: 13, fontFamily: "Helvetica-Bold", color: C.escuro, marginTop: 14, marginBottom: 8 },
  texto: { fontSize: 11.5, color: C.escuro, marginBottom: 10 },
  investimento: { fontSize: 18, fontFamily: "Helvetica-Bold", color: C.titulo, marginBottom: 6 },

  bulletRow: { flexDirection: "row", marginBottom: 8 },
  bulletDot: { width: 14, fontSize: 11.5, color: C.escuro },
  bulletText: { flex: 1, fontSize: 11.5, color: C.escuro },

  claro: { fontSize: 11, color: C.claro, marginBottom: 8 },
  contatoBox: { marginTop: 22, alignItems: "flex-end" },
  contato: { fontSize: 11, color: C.claro },
  footer: { marginTop: 24, alignItems: "center" },
  footerTxt: { fontSize: 9.5, color: C.claro, textAlign: "center" },
});

function Bullet({ children }: { children: string }) {
  return (
    <View style={s.bulletRow}>
      <Text style={s.bulletDot}>•</Text>
      <Text style={s.bulletText}>{children}</Text>
    </View>
  );
}

export function PropostaPDF({ proposta, logoSrc }: { proposta: Proposta; logoSrc?: string }) {
  const p = proposta;
  return (
    <Document title={`Proposta - ${p.condo}`}>
      <Page size="A4" style={s.page}>
        <View style={s.frame} fixed />
        {logoSrc ? <Image src={logoSrc} style={s.logo} fixed /> : null}

        {/* Página 1 */}
        <Text style={s.titulo}>Proposta Comercial</Text>
        <Text style={s.subtitulo}>{p.condo}</Text>
        <Text style={s.local}>São Paulo, {dataExtenso(p.data)}.</Text>
        <Text style={s.paragrafo}>{PROPOSTA.intro}</Text>

        <Text style={s.refTitulo}>Referências:</Text>
        {PROPOSTA.referencias.map((r, i) => (
          <View key={i}>
            <Text style={s.refCondo}>{r.condo}</Text>
            <Text style={s.refSindico}>{r.sindico}</Text>
          </View>
        ))}

        {/* Página 2 */}
        <Text style={s.h1} break>Escopo da Proposta</Text>
        <Text style={s.h2}>I. MANUTENÇÃO</Text>
        <Text style={s.texto}>Serviços a serem executados:</Text>
        {PROPOSTA.manutencao.map((m, i) => (
          <Bullet key={i}>{m}</Bullet>
        ))}

        {/* Página 3 */}
        <Text style={s.h2} break>II. EXECUÇÃO DO SERVIÇO</Text>
        {(ESCOPOS[p.escopo] ?? ESCOPOS[ESCOPO_PADRAO]).execucao.map((l, i) => (
          <Bullet key={i}>{l}</Bullet>
        ))}
        <Text style={s.texto}>{PROPOSTA.supervisao}</Text>

        <Text style={s.h2}>III. INVESTIMENTO</Text>
        <Text style={s.investimento}>{fmtBRL(p.valorMensal)} / Mês</Text>

        <Text style={s.h2}>IV. CONDIÇÕES GERAIS DE PAGAMENTO</Text>
        <Text style={s.texto}>{PROPOSTA.condicoesPagamento}</Text>

        <Text style={s.h2}>V. PRAZO DE EXECUÇÃO DA PRESTAÇÃO DOS SERVIÇOS</Text>
        <Text style={s.texto}>
          O início e a execução da prestação dos serviços se darão após a assinatura de contrato, sendo certo que a
          referida prestação dos serviços será pelo prazo de {p.prazoMeses} meses, podendo ser prorrogado.
        </Text>

        <Text style={s.claro}>
          PRAZO DE VALIDADE DESTA PROPOSTA COMERCIAL: {p.validadeDias} dias contados da data de sua apresentação.
        </Text>
        <Text style={s.claro}>{PROPOSTA.agradecimento}</Text>

        <View style={s.contatoBox}>
          <Text style={s.contato}>Comercial</Text>
          <Text style={s.contato}>{EMPRESA.email}</Text>
          <Text style={s.contato}>contato: {EMPRESA.telefone}</Text>
          <Text style={s.contato}>{EMPRESA.instagram}</Text>
        </View>

        <View style={s.footer}>
          <Text style={s.footerTxt}>PLANT JARDINAGEM E PAISAGISMO</Text>
          <Text style={s.footerTxt}>CNPJ {EMPRESA.cnpj}</Text>
          <Text style={s.footerTxt}>{EMPRESA.endereco}</Text>
        </View>
      </Page>
    </Document>
  );
}
