"use client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import type { Report } from "@/types";
import { Badge } from "@/components/ui/Badge";
import { KebabMenu, type MenuItem } from "@/components/ui/KebabMenu";
import { GardenSVG } from "./GardenSVG";
import { useReports } from "./store";

export function ReportCard({ r, archived }: { r: Report; archived?: boolean }) {
  const router = useRouter();
  const { archive, unarchive, remove } = useReports();

  const excluir = () => {
    if (confirm(`Excluir o relatório de ${r.condo}? Esta ação não pode ser desfeita.`)) remove(r.id);
  };

  const menu: MenuItem[] = archived
    ? [
        { label: "Editar", onSelect: () => router.push(`/admin/relatorios/${r.id}/editar`) },
        { label: "Desarquivar", onSelect: () => unarchive(r.id) },
        { label: "Excluir", onSelect: excluir, danger: true },
      ]
    : [
        { label: "Editar", onSelect: () => router.push(`/admin/relatorios/${r.id}/editar`) },
        { label: "Arquivar", onSelect: () => archive(r.id), danger: true },
      ];

  return (
    <div className="relative rounded-2xl border border-linha bg-surface shadow-s2">
      {/* Link "esticado" cobre o card sem aninhar botões dentro de <a>. */}
      <Link
        href={`/admin/relatorios/${r.id}`}
        aria-label={`Abrir ${r.condo}`}
        className="absolute inset-0 z-0 rounded-2xl"
      />

      <div className="pointer-events-none">
        <div className="grid grid-cols-2 gap-0.5 overflow-hidden rounded-t-2xl bg-linha">
          <Thumb url={r.fotosAntes[0]} label="ANTES" />
          <Thumb url={r.fotosDepois[0]} label="DEPOIS" depois />
        </div>
        <div className="p-3.5">
          <div className="flex items-start justify-between gap-2.5">
            <h3 className="font-display text-[17px] font-semibold text-verde-900">{r.condo}</h3>
            <Badge status={r.status} small />
          </div>
          <p className="mt-0.5 text-[13px] text-tintaMuda">
            {r.servicos.slice(0, 2).join(" · ")} · {r.duracao}
          </p>
          <p className="mt-2.5 flex items-center gap-1.5 text-[13px] font-semibold text-verde-700">
            <CalIcon /> Próxima visita {r.proximaVisita || "—"}
          </p>
        </div>
      </div>

      {/* Menu fica acima do link esticado. */}
      <div className="absolute right-2 top-2 z-10">
        <KebabMenu items={menu} />
      </div>
    </div>
  );
}

function Thumb({ url, label, depois }: { url?: string; label: string; depois?: boolean }) {
  return (
    <div className="relative h-24 overflow-hidden">
      {url ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={url} alt="" className="absolute inset-0 h-full w-full object-cover" />
      ) : (
        <GardenSVG depois={depois} />
      )}
      <span className="absolute left-1.5 top-1.5 rounded-full bg-[rgba(28,38,32,.72)] px-1.5 py-[3px] font-mono text-[9px] font-semibold tracking-wider text-white">
        {label}
      </span>
    </div>
  );
}

function CalIcon() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <rect x="3" y="4" width="18" height="18" rx="2" /><path d="M3 9h18M8 2v4M16 2v4" />
    </svg>
  );
}
