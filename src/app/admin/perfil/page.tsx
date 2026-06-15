"use client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useReports } from "@/components/relatorios/store";
import { SEED_CLIENTES } from "@/data/seed";
import { EMPRESA } from "@/lib/constants";
import { soDigitos } from "@/lib/utils";

export default function PerfilPage() {
  const router = useRouter();
  const { arquivados } = useReports();

  return (
    <div className="pb-28">
      <header className="flex items-center gap-3 px-[18px] pb-1.5 pt-[18px]">
        <button onClick={() => router.back()} className="grid h-[34px] w-[34px] place-items-center rounded-full border border-linha bg-surface text-[22px] leading-none text-verde-800">‹</button>
        <h1 className="font-display text-[22px] font-semibold text-verde-900">Perfil</h1>
      </header>

      {/* Cartão do admin */}
      <div className="mx-[18px] mt-1.5 flex items-center gap-3.5 rounded-2xl border border-linha bg-surface p-4 shadow-s2">
        <div className="grid h-14 w-14 flex-none place-items-center rounded-full bg-verde-700 text-lg font-bold text-white">CL</div>
        <div className="min-w-0">
          <div className="font-display text-[17px] font-semibold text-verde-900">Claiton</div>
          <div className="truncate text-[13px] text-tintaMuda">{EMPRESA.nome}</div>
          <div className="font-mono text-[11px] text-tintaMuda">CNPJ {EMPRESA.cnpj}</div>
        </div>
      </div>

      {/* Arquivados */}
      <Link
        href="/admin/perfil/arquivados"
        className="mx-[18px] mt-3 flex items-center gap-3 rounded-2xl border border-linha bg-surface p-4 shadow-s1"
      >
        <div className="grid h-10 w-10 flex-none place-items-center rounded-[10px] bg-salviaSurface text-verde-700">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 7h18v4H3z M5 11v9h14v-9 M9 15h6" /></svg>
        </div>
        <div className="flex-1">
          <div className="text-[15px] font-semibold text-tinta">Arquivados</div>
          <div className="text-[12px] text-tintaMuda">Relatórios fora da lista principal</div>
        </div>
        <span className="rounded-full bg-verde-50 px-2.5 py-1 font-mono text-[12px] font-semibold text-verde-700">{arquivados.length}</span>
        <span className="text-tintaMuda">›</span>
      </Link>

      {/* Clientes */}
      <h2 className="px-[18px] pb-2 pt-6 font-mono text-[11px] uppercase tracking-wider text-verde-600">Clientes</h2>
      <div className="mx-[18px] overflow-hidden rounded-2xl border border-linha bg-surface shadow-s1">
        {SEED_CLIENTES.map((c, i) => (
          <div key={c.id} className={`flex items-center gap-3 p-3.5 ${i > 0 ? "border-t border-linha" : ""}`}>
            <div className="grid h-10 w-10 flex-none place-items-center rounded-[10px] bg-salviaSurface text-[13px] font-bold text-verde-700">
              {c.nome.replace(/^(dos |da |de )/i, "").slice(0, 2).toUpperCase()}
            </div>
            <div className="min-w-0 flex-1">
              <div className="truncate text-[15px] font-semibold text-tinta">{c.nome}</div>
              <div className="truncate text-[12px] text-tintaMuda">
                {c.sindico ? `Síndico ${c.sindico}` : "Síndico não cadastrado"}
                {c.telefone ? ` · ${c.telefone}` : ""}
              </div>
            </div>
            {c.telefone && (
              <a
                href={`https://wa.me/55${soDigitos(c.telefone)}`}
                target="_blank"
                rel="noopener noreferrer"
                aria-label={`WhatsApp de ${c.nome}`}
                className="grid h-9 w-9 flex-none place-items-center rounded-full bg-verde-50 text-verde-700"
              >
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 16v3a2 2 0 01-2 2 19 19 0 01-8-3 19 19 0 01-6-6 19 19 0 01-3-8 2 2 0 012-2h3a2 2 0 012 2c0 1 .2 2 .5 3a2 2 0 01-.5 2L9 11a16 16 0 006 6l1-1a2 2 0 012-.5c1 .3 2 .5 3 .5a2 2 0 012 2z" /></svg>
              </a>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
