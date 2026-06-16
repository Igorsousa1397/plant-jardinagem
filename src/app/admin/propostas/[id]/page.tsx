import { PropostaPreview } from "@/components/propostas/PropostaPreview";
export default function PropostaPage({ params }: { params: { id: string } }) {
  return <PropostaPreview id={params.id} />;
}
