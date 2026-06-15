"use client";
import Link from "next/link";
import { useReports } from "@/components/relatorios/store";
import { ReportCard } from "@/components/relatorios/ReportCard";
import { AgendaSection } from "@/components/agenda/AgendaSection";

export default function HomePage() {
  const { reports, loading, error } = useReports();

  return (
    <div className="pb-28">
      <header className="flex items-start justify-between px-[18px] pb-2 pt-5">
        <div>
          <div className="font-mono text-[11px] uppercase tracking-wider text-verde-600">Admin · Claiton</div>
          <h1 className="mt-0.5 font-display text-[28px] font-semibold tracking-tight text-verde-900">Home</h1>
        </div>
        <Link
          href="/admin/perfil"
          aria-label="Perfil"
          className="grid h-10 w-10 place-items-center rounded-full bg-verde-700 text-sm font-bold text-white shadow-s1"
        >
          CL
        </Link>
      </header>

      {error && (
        <p className="mx-[18px] rounded-[10px] bg-erroBg px-3 py-2 text-sm font-medium text-erro">{error}</p>
      )}

      <section className="px-[18px]">
        <h2 className="pb-2 pt-3 font-mono text-[11px] uppercase tracking-wider text-verde-600">
          Agenda · próximos clientes
        </h2>
        <AgendaSection />
      </section>

      <section className="px-[18px]">
        <h2 className="pb-2 pt-6 font-mono text-[11px] uppercase tracking-wider text-verde-600">Relatórios</h2>
        {loading ? (
          <div className="flex flex-col gap-3.5">
            <Skeleton h={180} />
            <Skeleton h={180} />
          </div>
        ) : reports.length === 0 ? (
          <p className="rounded-2xl border border-linha bg-surface p-4 text-sm text-tintaMuda">
            Nenhum relatório ainda. Toque no + para criar o primeiro.
          </p>
        ) : (
          <div className="flex flex-col gap-3.5">
            {reports.map((r) => <ReportCard key={r.id} r={r} />)}
          </div>
        )}
      </section>

      <div className="pointer-events-none fixed inset-x-0 bottom-[84px] z-30 mx-auto flex max-w-md justify-end px-[18px]">
        <Link
          href="/admin/relatorios/novo"
          aria-label="Novo relatório"
          className="pointer-events-auto grid h-14 w-14 place-items-center rounded-full bg-verde-700 text-[28px] text-white shadow-s3"
        >+</Link>
      </div>
    </div>
  );
}

function Skeleton({ h }: { h: number }) {
  return <div className="animate-pulse rounded-2xl border border-linha bg-surface2" style={{ height: h }} />;
}
