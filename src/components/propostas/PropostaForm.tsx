"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import type { Cliente } from "@/types";
import { listClientes } from "@/lib/clientes";
import { createProposta } from "@/lib/propostas";
import { fmtData } from "@/lib/utils";
import { ESCOPO_OPCOES, ESCOPO_PADRAO } from "@/lib/proposta-conteudo";
import { Field, inputClass } from "@/components/ui/Field";
import { Button } from "@/components/ui/Button";

const hojeISO = () => {
  const d = new Date();
  const p = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
};

export function PropostaForm() {
  const router = useRouter();
  const [clientes, setClientes] = useState<Cliente[]>([]);
  const [condo, setCondo] = useState("");
  const [dataISO, setDataISO] = useState(hojeISO());
  const [valor, setValor] = useState("3200");
  const [escopo, setEscopo] = useState(ESCOPO_PADRAO);
  const [prazo, setPrazo] = useState("24");
  const [validade, setValidade] = useState("30");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    listClientes().then((c) => {
      setClientes(c);
      setCondo((atual) => atual || c[0]?.nome || "");
    });
  }, []);

  const salvar = async () => {
    if (!condo) return;
    setSaving(true);
    try {
      const cli = clientes.find((c) => c.nome === condo);
      const nova = await createProposta({
        condo,
        clienteId: cli?.id,
        data: fmtData(dataISO),
        valorMensal: Number(valor) || 0,
        escopo,
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
        <Field label="Condomínio">
          <select value={condo} onChange={(e) => setCondo(e.target.value)} className={inputClass}>
            {clientes.map((c) => (
              <option key={c.id}>{c.nome}</option>
            ))}
          </select>
        </Field>

        <Field label="Modelo de escopo">
          <select value={escopo} onChange={(e) => setEscopo(e.target.value)} className={inputClass}>
            {ESCOPO_OPCOES.map((o) => (
              <option key={o.valor} value={o.valor}>{o.label}</option>
            ))}
          </select>
        </Field>

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
      </div>

      <div className="fixed inset-x-0 bottom-0 z-30 mx-auto flex max-w-md gap-3 border-t border-linha bg-surface px-[18px] py-3">
        <Button variant="ghost" onClick={() => router.back()}>Cancelar</Button>
        <Button block disabled={saving} onClick={salvar}>{saving ? "Salvando…" : "Gerar proposta"}</Button>
      </div>
    </div>
  );
}
