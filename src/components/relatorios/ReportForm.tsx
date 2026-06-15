"use client";
import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import type { Report, Status } from "@/types";
import { CONDOS, SERVICOS, EQUIPAMENTOS, EPIS, STATUS_STYLES } from "@/lib/constants";
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

  const [condo, setCondo] = useState(report?.condo ?? CONDOS[0]);
  const [data, setData] = useState(report ? toISO(report.data) : "2025-09-08");
  const [duracao, setDuracao] = useState(report?.duracao ?? "5 horas");
  const [servicos, setServicos] = useState<string[]>(report?.servicos ?? ["Corte e Poda", "Limpeza Geral do Jardim"]);
  const [equip, setEquip] = useState<string[]>(report?.equipamentos ?? ["Roçadeira", "Soprador"]);
  const [epi, setEpi] = useState<string[]>(report?.epi ?? ["Luvas", "Botas"]);
  const [obs, setObs] = useState(report?.observacoes ?? "");
  const [proxima, setProxima] = useState(report ? toISO(report.proximaVisita) : "2025-09-22");
  const [status, setStatus] = useState<Status>(report?.status ?? "Finalizado");
  const [fotosAntes, setFotosAntes] = useState<string[]>(report?.fotosAntes ?? []);
  const [fotosDepois, setFotosDepois] = useState<string[]>(report?.fotosDepois ?? []);

  const [saving, setSaving] = useState(false);

  const toggle = (list: string[], set: (v: string[]) => void, v: string) =>
    set(list.includes(v) ? list.filter((x) => x !== v) : [...list, v]);

  const addPhotos = (
    e: React.ChangeEvent<HTMLInputElement>,
    set: React.Dispatch<React.SetStateAction<string[]>>
  ) => {
    Array.from(e.target.files ?? []).forEach((f) => {
      const reader = new FileReader();
      reader.onload = () => set((prev) => [...prev, reader.result as string]);
      reader.readAsDataURL(f);
    });
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
      proximaVisita: fmtData(proxima),
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
            {CONDOS.map((x) => <option key={x}>{x}</option>)}
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

        <Field label="Próxima visita">
          <input type="date" value={proxima} onChange={(e) => setProxima(e.target.value)} className={inputClass} />
        </Field>

        <Field label="Status">
          <div className="flex flex-wrap gap-2">
            {STATUS_LIST.map((s) => <Chip key={s} active={status === s} onClick={() => setStatus(s)}>{s}</Chip>)}
          </div>
        </Field>
      </div>

      <div className="fixed inset-x-0 bottom-0 z-30 mx-auto flex max-w-md gap-3 border-t border-linha bg-surface px-[18px] pb-4 pt-3">
        <Button variant="ghost" onClick={() => router.back()}>Cancelar</Button>
        <Button block disabled={saving} onClick={salvar}>
          {saving ? "Salvando…" : editing ? "Salvar alterações" : "Salvar relatório"}
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
