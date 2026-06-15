"use client";
import { useParams } from "next/navigation";
import Link from "next/link";
import { useReports } from "@/components/relatorios/store";
import { ReportForm } from "@/components/relatorios/ReportForm";

export default function EditarRelatorioPage() {
  const { id } = useParams<{ id: string }>();
  const { get } = useReports();
  const report = get(id);

  if (!report) {
    return (
      <div className="grid min-h-screen place-items-center px-8 text-center">
        <div>
          <p className="font-display text-xl font-semibold text-verde-900">Relatório não encontrado</p>
          <Link href="/admin/home" className="mt-4 inline-block font-semibold text-verde-700">Voltar aos relatórios</Link>
        </div>
      </div>
    );
  }
  return <ReportForm report={report} />;
}
