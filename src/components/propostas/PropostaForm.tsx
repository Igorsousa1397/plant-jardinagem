"use client";
import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import type { Cliente } from "@/types";
import { listClientes } from "@/lib/clientes";
import { createProposta } from "@/lib/propostas";
import { fmtData } from "@/lib/utils";
import { MANUTENCAO_OPCOES, EXECUCAO_OPCOES, EXECUCAO_PADRAO, interpola } from "@/lib/proposta-conteudo";
import { Field, inputClass } from "@/components/ui/Field";
import { Button } from "@/components/ui/Button";

const hojeISO = () => {
  const d = new Date();
  const p = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
};

function Check({ checked, onChange, children }: { checked: boolean; onChange: () => void; children: React.ReactNode }) {
  return (
    <label className="flex cursor-pointer items-start gap-2.5 py-1.5">
      <input type="checkbox" checked={checked} onChange={onChange} className="mt-0.5 h-4 w-4 flex-none accent-verde-700" />
      <span className="text-[13px] leading-snug text-tinta">{children}</span>
    </label>
  );
}

export function PropostaForm() {
  const router = useRouter();
  const [clientes, setClientes] = useState<Cliente[]>([]);
  const [cliente, setCliente] = useState("");
  const [dataISO, setDataISO] = useState(hojeISO());
  const [valor, setValor] = useState("3200");
  const [visitas, setVisitas] = useState("2");
  const [equipe, setEquipe] = useState("7");
  const [prazo, setPrazo] = useState("24");
  const [validade, setValidade] = useState("30");
  const [execSel, setExecSel] = useState<string[]>(EXECUCAO_PADRAO);
  const [manutSel, setManutSel] = useState<number[]>(MANUTENCAO_OPCOES.map((_, i) => i));
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    listClientes().then(setClientes);
  }, []);

  const nV = Number(visitas) || 0;
  const nE = Number(equipe) || 0;

  const toggleExec = (id: string) =>
    setExecSel((s) => (s.includes(id) ? s.filter((x) => x !== id) : [...s, id]));
  const toggleManut = (i: number) =>
    setManutSel((s) => (s.includes(i) ? s.filter((x) => x !== i) : [...s, i]));

  const salvar = async () => {
    if (!cliente.trim()) return;
    setSaving(true);
    try {
      const cli = clientes.find((c) => c.nome.toLowerCase() === cliente.trim().toLowerCase());
      const execucao = EXECUCAO_OPCOES.filter((o) => execSel.includes(o.id)).map((o) => interpola(o.texto, nV, nE));
      const servicos = MANUTENCAO_OPCOES.filter((_, i) => manutSel.includes(i));
      const nova = await createProposta({
        condo: cliente.trim(),
        clienteId: cli?.id,
        data: fmtData(dataISO),
        valorMensal: Number(valor) || 0,
        visitasMensais: nV,
        equipe: nE,
        servicos,
        execucao,
        prazoMeses: Number(prazo) || 0,
        validadeDias: Number(validade) || 0,
      });
      router.push(`/admin/propostas/${nova.id}`);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="pb-28">
      <header className="flex items-center gap-3 px-[18px] pb-1.5 pt-[18px]">
        <button onClick={() => router.back()} className="grid h-[34px] w-[34px] place-items-center rounded-full border border-linha bg-surface text-[22px] leading-none text-verde-800">‹</button>
        <span className="font-mono text-[11px] uppercase tracking-wider text-tintaMuda">Nova proposta</span>
      </header>

      <div className="flex flex-col gap-1 px-[18px] pt-2">
        <Field label="Cliente">
          <input
            list="clientes-list"
            value={cliente}
            onChange={(e) => setCliente(e.target.value)}
            className={inputClass}
            placeholder="Nome do cliente / condomínio"
          />
          <datalist id="clientes-list">
            {clientes.map((c) => (
              <option key={c.id} value={c.nome} />
            ))}
          </datalist>
        </Field>

        <div className="grid grid-cols-2 gap-3">
          <Field label="Visitas / mês">
            <input type="number" value={visitas} onChange={(e) => setVisitas(e.target.value)} className={inputClass} />
          </Field>
          <Field label="Equipe (pessoas)">
            <input type="number" value={equipe} onChange={(e) => setEquipe(e.target.value)} className={inputClass} />
          </Field>
        </div>

        <Field label="Valor mensal (R$)">
          <input type="number" inputMode="decimal" value={valor} onChange={(e) => setValor(e.target.value)} className={inputClass} />
        </Field>
        <Field label="Data da proposta">
          <input type="date" value={dataISO} onChange={(e) => setDataISO(e.target.value)} className={inputClass} />
        </Field>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Prazo (meses)">
            <input type="number" value={prazo} onChange={(e) => setPrazo(e.target.value)} className={inputClass} />
          </Field>
          <Field label="Validade (dias)">
            <input type="number" value={validade} onChange={(e) => setValidade(e.target.value)} className={inputClass} />
          </Field>
        </div>

        <div className="mt-2">
          <h2 className="pb-1 pt-3 font-mono text-[11px] uppercase tracking-wider text-verde-600">Execução do serviço</h2>
          <div className="rounded-2xl border border-linha bg-surface px-3.5 py-1">
            {EXECUCAO_OPCOES.map((o) => (
              <Check key={o.id} checked={execSel.includes(o.id)} onChange={() => toggleExec(o.id)}>
                {interpola(o.texto, nV, nE)}
              </Check>
            ))}
          </div>
        </div>

        <div className="mt-1">
          <h2 className="pb-1 pt-3 font-mono text-[11px] uppercase tracking-wider text-verde-600">Serviços de manutenção</h2>
          <div className="rounded-2xl border border-linha bg-surface px-3.5 py-1">
            {MANUTENCAO_OPCOES.map((m, i) => (
              <Check key={i} checked={manutSel.includes(i)} onChange={() => toggleManut(i)}>
                {m}
              </Check>
            ))}
          </div>
        </div>
      </div>

      <div className="fixed inset-x-0 bottom-0 z-30 mx-auto flex max-w-md gap-3 border-t border-linha bg-surface px-[18px] py-3">
        <Button variant="ghost" onClick={() => router.back()}>Cancelar</Button>
        <Button block disabled={saving} onClick={salvar}>{saving ? "Salvando…" : "Gerar proposta"}</Button>
      </div>
    </div>
  );
}
