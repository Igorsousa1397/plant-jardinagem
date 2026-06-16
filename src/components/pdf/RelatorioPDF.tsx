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
