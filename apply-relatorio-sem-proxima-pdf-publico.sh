#!/usr/bin/env bash
# Plant Jardinagem — remove próxima visita do relatório + link público do PDF no envio
set -e
if [ ! -f package.json ]; then echo "Rode na raiz do projeto."; exit 1; fi
echo "Aplicando mudanças do relatório..."

mkdir -p "src/types"
cat > "src/types/index.ts" <<'__PLANT_EOF__'
export type Status = "Finalizado" | "Em andamento" | "Agendado" | "Atrasado";

export interface Report {
  id: string;
  condo: string;
  data: string;
  duracao: string;
  status: Status;
  servicos: string[];
  equipamentos: string[];
  epi: string[];
  observacoes: string;
  proximaVisita?: string;
  fotosAntes: string[];
  fotosDepois: string[];
  arquivado?: boolean;
}

export interface Cliente {
  id: string;
  nome: string;
  sindico?: string;
  telefone?: string;
}

export interface Agendamento {
  id: string;
  clienteId?: string;
  condo: string;
  data: string;        // dd/mm/aaaa
  observacao: string;
  concluido: boolean;
}

export interface Proposta {
  id: string;
  clienteId?: string;
  condo: string;          // nome do cliente (texto livre)
  data: string;           // dd/mm/aaaa
  valorMensal: number;
  visitasMensais: number;
  equipe: number;
  servicos: string[];     // itens de manutenção selecionados
  execucao: string[];     // cláusulas de execução selecionadas (texto final)
  prazoMeses: number;
  validadeDias: number;
}

export type Papel = "admin" | "funcionario";
__PLANT_EOF__
echo "  ok  src/types/index.ts"

mkdir -p "src/components/relatorios"
cat > "src/components/relatorios/ReportPreview.tsx" <<'__PLANT_EOF__'
"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import type { Report } from "@/types";
import { EMPRESA } from "@/lib/constants";
import { listClientes } from "@/lib/clientes";
import { soDigitos } from "@/lib/utils";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { GardenSVG } from "./GardenSVG";

export function ReportPreview({ r }: { r: Report }) {
  const router = useRouter();
  const [toast, setToast] = useState("");
  const [telSindico, setTelSindico] = useState("");
  const fire = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(""), 2200);
  };

  useEffect(() => {
    listClientes()
      .then((cs) => {
        const cli = cs.find((c) => c.nome.toLowerCase() === r.condo.toLowerCase());
        setTelSindico(cli?.telefone ? soDigitos(cli.telefone) : "");
      })
      .catch(() => setTelSindico(""));
  }, [r.condo]);

  const fotos = [
    ...r.fotosAntes.map((s) => ({ s, depois: false })),
    ...r.fotosDepois.map((s) => ({ s, depois: true })),
  ];

  const enviarWhats = () => {
    const url = `${window.location.origin}/api/relatorios/${r.id}/pdf`;
    const texto = encodeURIComponent(
      `Relatório de serviço — ${r.condo} (${r.data}).\nAcesse o relatório em PDF: ${url}`
    );
    const destino = telSindico ? `https://wa.me/55${telSindico}?text=${texto}` : `https://wa.me/?text=${texto}`;
    window.open(destino, "_blank");
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
            <div className="grid h-10 w-10 flex-none place-items-center rounded-[10px] bg-papel p-1">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src="/logo.png" alt="Plant Jardinagem" className="h-full w-full object-contain" />
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
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2"><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></svg>
            </div>
            <div>
              <div className="font-mono text-[11px] uppercase tracking-wide text-tintaMuda">Duração do serviço</div>
              <div className="text-[15px] font-bold text-verde-900">{r.duracao}</div>
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

mkdir -p "src/components/relatorios"
cat > "src/components/relatorios/ReportCard.tsx" <<'__PLANT_EOF__'
"use client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import type { Report } from "@/types";
import { Badge } from "@/components/ui/Badge";
import { KebabMenu, type MenuItem } from "@/components/ui/KebabMenu";
import { ImageOff } from "lucide-react";
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
          <Thumb url={r.fotosDepois[0]} label="DEPOIS" />
        </div>
        <div className="p-3.5">
          <div className="flex items-start justify-between gap-2.5">
            <h3 className="font-display text-[17px] font-semibold text-verde-900">{r.condo}</h3>
            <Badge status={r.status} small />
          </div>
          <p className="mt-0.5 text-[13px] text-tintaMuda">
            {r.servicos.slice(0, 2).join(" · ")} · {r.duracao}
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

function Thumb({ url, label }: { url?: string; label: string }) {
  return (
    <div className="relative h-24 overflow-hidden">
      {url ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={url} alt="" className="absolute inset-0 h-full w-full object-cover" />
      ) : (
        <div className="absolute inset-0 flex flex-col items-center justify-center gap-1 bg-surface2">
          <ImageOff size={22} strokeWidth={1.5} className="text-salvia" />
          <span className="font-mono text-[9px] uppercase tracking-wider text-tintaMuda">Sem foto</span>
        </div>
      )}
      <span className="absolute left-1.5 top-1.5 rounded-full bg-[rgba(28,38,32,.72)] px-1.5 py-[3px] font-mono text-[9px] font-semibold tracking-wider text-white">
        {label}
      </span>
    </div>
  );
}
__PLANT_EOF__
echo "  ok  src/components/relatorios/ReportCard.tsx"

mkdir -p "src/components/relatorios"
cat > "src/components/relatorios/ReportForm.tsx" <<'__PLANT_EOF__'
"use client";
import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import type { Report, Status } from "@/types";
import { SERVICOS, EQUIPAMENTOS, EPIS, STATUS_STYLES } from "@/lib/constants";
import { listClientes } from "@/lib/clientes";
import { uploadFoto } from "@/lib/fotos";
import { fmtData, toISO } from "@/lib/utils";
import { useReports } from "./store";
import { Field, inputClass } from "@/components/ui/Field";
import { Chip } from "@/components/ui/Chip";
import { Button } from "@/components/ui/Button";

const STATUS_LIST = Object.keys(STATUS_STYLES) as Status[];

export function ReportForm({ report }: { report?: Report }) {
  const editing = Boolean(report);
  const router = useRouter();
  const { add, update } = useReports();
  const antesRef = useRef<HTMLInputElement>(null);
  const depoisRef = useRef<HTMLInputElement>(null);

  const [condo, setCondo] = useState(report?.condo ?? "");
  const [clientes, setClientes] = useState<string[]>([]);

  useEffect(() => {
    listClientes().then((cs) => {
      const nomes = cs.map((c) => c.nome);
      setClientes(nomes);
      setCondo((atual) => atual || nomes[0] || "");
    });
  }, []);
  const [data, setData] = useState(report ? toISO(report.data) : "2025-09-08");
  const [duracao, setDuracao] = useState(report?.duracao ?? "5 horas");
  const [servicos, setServicos] = useState<string[]>(report?.servicos ?? ["Corte e Poda", "Limpeza Geral do Jardim"]);
  const [equip, setEquip] = useState<string[]>(report?.equipamentos ?? ["Roçadeira", "Soprador"]);
  const [epi, setEpi] = useState<string[]>(report?.epi ?? ["Luvas", "Botas"]);
  const [obs, setObs] = useState(report?.observacoes ?? "");
  const [status, setStatus] = useState<Status>(report?.status ?? "Finalizado");
  const [fotosAntes, setFotosAntes] = useState<string[]>(report?.fotosAntes ?? []);
  const [fotosDepois, setFotosDepois] = useState<string[]>(report?.fotosDepois ?? []);
  const [enviando, setEnviando] = useState(0);

  const [saving, setSaving] = useState(false);

  const toggle = (list: string[], set: (v: string[]) => void, v: string) =>
    set(list.includes(v) ? list.filter((x) => x !== v) : [...list, v]);

  const addPhotos = async (
    e: React.ChangeEvent<HTMLInputElement>,
    set: React.Dispatch<React.SetStateAction<string[]>>
  ) => {
    const files = Array.from(e.target.files ?? []);
    e.target.value = ""; // permite reescolher o mesmo arquivo
    setEnviando((n) => n + files.length);
    for (const f of files) {
      try {
        const url = await uploadFoto(f);
        set((prev) => [...prev, url]);
      } catch (err) {
        console.error("Falha ao enviar foto:", err);
      } finally {
        setEnviando((n) => n - 1);
      }
    }
  };

  const salvar = async () => {
    setSaving(true);
    const payload = {
      condo,
      data: fmtData(data),
      duracao,
      status,
      servicos,
      equipamentos: equip,
      epi,
      observacoes: obs,
      fotosAntes,
      fotosDepois,
    };
    try {
      if (report) {
        await update(report.id, payload);
        router.push(`/admin/relatorios/${report.id}`);
      } else {
        const novo = await add(payload);
        router.push(`/admin/relatorios/${novo.id}`);
      }
    } catch (e) {
      setSaving(false);
      alert("Não foi possível salvar: " + (e instanceof Error ? e.message : "erro desconhecido"));
    }
  };

  return (
    <div className="pb-28">
      <header className="flex items-center gap-3 px-[18px] pb-1.5 pt-[18px]">
        <button onClick={() => router.back()} className="grid h-[34px] w-[34px] place-items-center rounded-full border border-linha bg-surface text-[22px] leading-none text-verde-800">‹</button>
        <h1 className="font-display text-[22px] font-semibold text-verde-900">
          {editing ? "Editar relatório" : "Novo relatório"}
        </h1>
      </header>

      <div className="px-[18px] pt-1.5">
        <Field label="Condomínio">
          <select value={condo} onChange={(e) => setCondo(e.target.value)} className={inputClass}>
            {(condo && !clientes.includes(condo) ? [condo, ...clientes] : clientes).map((x) => (
              <option key={x}>{x}</option>
            ))}
          </select>
        </Field>

        <div className="flex gap-3">
          <div className="flex-1">
            <Field label="Data do serviço">
              <input type="date" value={data} onChange={(e) => setData(e.target.value)} className={inputClass} />
            </Field>
          </div>
          <div className="flex-1">
            <Field label="Duração">
              <input value={duracao} onChange={(e) => setDuracao(e.target.value)} placeholder="5 horas" className={inputClass} />
            </Field>
          </div>
        </div>

        <Field label="Fotos — antes" hint="Toque para adicionar do celular.">
          <PhotoRow list={fotosAntes} onAdd={() => antesRef.current?.click()} onRemove={(i) => setFotosAntes((p) => p.filter((_, x) => x !== i))} />
          <input ref={antesRef} type="file" accept="image/*" multiple hidden onChange={(e) => addPhotos(e, setFotosAntes)} />
        </Field>

        <Field label="Fotos — depois">
          <PhotoRow depois list={fotosDepois} onAdd={() => depoisRef.current?.click()} onRemove={(i) => setFotosDepois((p) => p.filter((_, x) => x !== i))} />
          <input ref={depoisRef} type="file" accept="image/*" multiple hidden onChange={(e) => addPhotos(e, setFotosDepois)} />
        </Field>

        <Field label="Serviços realizados">
          <div className="flex flex-wrap gap-2">
            {SERVICOS.map((s) => <Chip key={s} active={servicos.includes(s)} onClick={() => toggle(servicos, setServicos, s)}>{s}</Chip>)}
          </div>
        </Field>

        <Field label="Equipamentos">
          <div className="flex flex-wrap gap-2">
            {EQUIPAMENTOS.map((s) => <Chip key={s} active={equip.includes(s)} onClick={() => toggle(equip, setEquip, s)}>{s}</Chip>)}
          </div>
        </Field>

        <Field label="EPI utilizados">
          <div className="flex flex-wrap gap-2">
            {EPIS.map((s) => <Chip key={s} active={epi.includes(s)} onClick={() => toggle(epi, setEpi, s)}>{s}</Chip>)}
          </div>
        </Field>

        <Field label="Observações" hint="Ex: reforçar rega nas gramas novas.">
          <textarea rows={3} value={obs} onChange={(e) => setObs(e.target.value)} className={`${inputClass} resize-y`} />
        </Field>

        <Field label="Status">
          <div className="flex flex-wrap gap-2">
            {STATUS_LIST.map((s) => <Chip key={s} active={status === s} onClick={() => setStatus(s)}>{s}</Chip>)}
          </div>
        </Field>
      </div>

      <div className="fixed inset-x-0 bottom-0 z-30 mx-auto flex max-w-md gap-3 border-t border-linha bg-surface px-[18px] pb-4 pt-3">
        <Button variant="ghost" onClick={() => router.back()}>Cancelar</Button>
        <Button block disabled={saving || enviando > 0} onClick={salvar}>
          {enviando > 0 ? `Enviando ${enviando} foto(s)…` : saving ? "Salvando…" : editing ? "Salvar alterações" : "Salvar relatório"}
        </Button>
      </div>
    </div>
  );
}

function PhotoRow({
  list, onAdd, onRemove, depois,
}: { list: string[]; onAdd: () => void; onRemove: (i: number) => void; depois?: boolean }) {
  return (
    <div className="flex flex-wrap gap-2">
      {list.map((src, i) => (
        <div key={i} className="relative h-16 w-16 overflow-hidden rounded-[10px] shadow-s1">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={src} alt="" className="h-full w-full object-cover" />
          <button onClick={() => onRemove(i)} className="absolute right-0.5 top-0.5 grid h-[18px] w-[18px] place-items-center rounded-full bg-[rgba(28,38,32,.8)] text-[11px] leading-none text-white">×</button>
        </div>
      ))}
      <button
        onClick={onAdd}
        className={`grid h-16 w-16 place-items-center rounded-[10px] border-[1.5px] border-dashed text-[22px] text-verde-700 ${depois ? "border-verde-400 bg-verde-50" : "border-linha bg-surface2"}`}
      >+</button>
    </div>
  );
}
__PLANT_EOF__
echo "  ok  src/components/relatorios/ReportForm.tsx"

mkdir -p "src/components/relatorios"
cat > "src/components/relatorios/Agenda.tsx" <<'__PLANT_EOF__'
"use client";
import Link from "next/link";
import type { Report } from "@/types";
import { parseBR } from "@/lib/utils";

const MESES = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"];

function rotulo(d: Date): { texto: string; classe: string } {
  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);
  const alvo = new Date(d);
  alvo.setHours(0, 0, 0, 0);
  const dias = Math.round((alvo.getTime() - hoje.getTime()) / 86_400_000);
  if (dias < 0) return { texto: `Atrasado ${Math.abs(dias)}d`, classe: "bg-atencaoBg text-atencao" };
  if (dias === 0) return { texto: "Hoje", classe: "bg-atencaoBg text-atencao" };
  if (dias === 1) return { texto: "Amanhã", classe: "bg-verde-50 text-verde-700" };
  if (dias <= 7) return { texto: `em ${dias} dias`, classe: "bg-verde-50 text-verde-700" };
  return { texto: `em ${dias} dias`, classe: "bg-surface2 text-tintaMuda" };
}

export function Agenda({ reports }: { reports: Report[] }) {
  const itens = reports
    .map((r) => ({ r, d: parseBR(r.proximaVisita ?? "") }))
    .filter((e): e is { r: Report; d: Date } => e.d !== null)
    .sort((a, b) => a.d.getTime() - b.d.getTime());

  if (itens.length === 0) {
    return (
      <div className="rounded-2xl border border-linha bg-surface p-4 text-sm text-tintaMuda shadow-s1">
        Nenhuma visita agendada.
      </div>
    );
  }

  return (
    <div className="overflow-hidden rounded-2xl border border-linha bg-surface shadow-s1">
      {itens.map(({ r, d }, i) => {
        const tag = rotulo(d);
        return (
          <Link
            key={r.id}
            href={`/admin/relatorios/${r.id}`}
            className={`flex items-center gap-3 p-3.5 ${i > 0 ? "border-t border-linha" : ""}`}
          >
            <div className="flex h-12 w-12 flex-none flex-col items-center justify-center rounded-[12px] bg-verde-50 text-verde-700">
              <span className="text-[17px] font-bold leading-none">{String(d.getDate()).padStart(2, "0")}</span>
              <span className="mt-0.5 font-mono text-[10px] uppercase leading-none">{MESES[d.getMonth()]}</span>
            </div>
            <div className="min-w-0 flex-1">
              <div className="truncate text-[15px] font-semibold text-tinta">{r.condo}</div>
              <div className="truncate text-[12px] text-tintaMuda">{r.servicos.slice(0, 2).join(" · ")}</div>
            </div>
            <span className={`flex-none rounded-full px-2.5 py-1 text-[11px] font-semibold ${tag.classe}`}>
              {tag.texto}
            </span>
          </Link>
        );
      })}
    </div>
  );
}
__PLANT_EOF__
echo "  ok  src/components/relatorios/Agenda.tsx"

mkdir -p "src/app/api/relatorios/[id]/pdf"
cat > "src/app/api/relatorios/[id]/pdf/route.ts" <<'__PLANT_EOF__'
import { NextResponse } from "next/server";
import { renderToBuffer } from "@react-pdf/renderer";
import { createClient } from "@supabase/supabase-js";
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
  const admin = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } }
  );

  const { data, error } = await admin.from("relatorios").select("*").eq("id", params.id).maybeSingle();
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
echo "IMPORTANTE: adicione a env SUPABASE_SERVICE_ROLE_KEY no Vercel (e no .env.local) — veja instruções no chat."
echo "Depois: git add -A && git commit -m \"feat: remove proxima visita e envia PDF ao sindico\" && git push"
