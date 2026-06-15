"use client";
import { useRouter } from "next/navigation";
import { useReports } from "@/components/relatorios/store";
import { ReportCard } from "@/components/relatorios/ReportCard";

export default function ArquivadosPage() {
  const router = useRouter();
  const { arquivados } = useReports();

  return (
    <div className="pb-28">
      <header className="flex items-center gap-3 px-[18px] pb-1.5 pt-[18px]">
        <button onClick={() => router.back()} className="grid h-[34px] w-[34px] place-items-center rounded-full border border-linha bg-surface text-[22px] leading-none text-verde-800">‹</button>
        <h1 className="font-display text-[22px] font-semibold text-verde-900">Arquivados</h1>
      </header>

      {arquivados.length === 0 ? (
        <div className="px-8 py-16 text-center">
          <p className="font-display text-lg font-semibold text-verde-900">Nada arquivado</p>
          <p className="mt-1 text-sm text-tintaMuda">Relatórios que você arquivar aparecem aqui. Use o menu ⋮ no card.</p>
        </div>
      ) : (
        <div className="flex flex-col gap-3.5 px-[18px] pt-1.5">
          {arquivados.map((r) => <ReportCard key={r.id} r={r} archived />)}
        </div>
      )}
    </div>
  );
}
