"use client";
import { useEffect, useState } from "react";
import type { Cliente } from "@/types";
import { createCliente, updateCliente, archiveCliente } from "@/lib/clientes";
import { Field, inputClass } from "@/components/ui/Field";
import { Button } from "@/components/ui/Button";

export type SheetAlvo = "novo" | Cliente | null;

export function ClienteSheet({ alvo, onClose, onSaved }: { alvo: SheetAlvo; onClose: () => void; onSaved: () => void }) {
  const editando = alvo && alvo !== "novo" ? alvo : null;
  const [nome, setNome] = useState("");
  const [sindico, setSindico] = useState("");
  const [telefone, setTelefone] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (alvo && alvo !== "novo") {
      setNome(alvo.nome);
      setSindico(alvo.sindico ?? "");
      setTelefone(alvo.telefone ?? "");
    } else if (alvo === "novo") {
      setNome("");
      setSindico("");
      setTelefone("");
    }
  }, [alvo]);

  if (alvo === null) return null;

  const salvar = async () => {
    if (!nome.trim()) return;
    setSaving(true);
    try {
      const dados = { nome: nome.trim(), sindico: sindico.trim() || undefined, telefone: telefone.trim() || undefined };
      if (editando) await updateCliente(editando.id, dados);
      else await createCliente(dados);
      onSaved();
      onClose();
    } finally {
      setSaving(false);
    }
  };

  const excluir = async () => {
    if (!editando) return;
    if (!confirm("Excluir este cliente? Ele vai para os arquivados (os registros ligados a ele são mantidos).")) return;
    setSaving(true);
    try {
      await archiveCliente(editando.id);
      onSaved();
      onClose();
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center">
      <div className="absolute inset-0 bg-tinta/40" onClick={onClose} />
      <div className="relative z-10 w-full max-w-md rounded-t-[22px] border border-linha bg-surface p-5 pb-8 shadow-s3">
        <div className="mx-auto mb-4 h-1.5 w-10 rounded-full bg-linha" />
        <h2 className="mb-3 font-display text-[18px] font-semibold text-verde-900">{editando ? "Editar cliente" : "Novo cliente"}</h2>
        <Field label="Nome">
          <input value={nome} onChange={(e) => setNome(e.target.value)} className={inputClass} placeholder="Ex: Condomínio Alameda das Palmeiras" />
        </Field>
        <Field label="Síndico (opcional)">
          <input value={sindico} onChange={(e) => setSindico(e.target.value)} className={inputClass} placeholder="Nome do síndico" />
        </Field>
        <Field label="Telefone (opcional)">
          <input value={telefone} onChange={(e) => setTelefone(e.target.value)} className={inputClass} inputMode="tel" placeholder="(11) 90000-0000" />
        </Field>
        <div className="mt-2 flex gap-2">
          {editando && (
            <button onClick={excluir} disabled={saving} className="flex-none rounded-[10px] border border-linha bg-surface px-4 py-3 text-[15px] font-semibold text-erro disabled:opacity-50">
              Excluir
            </button>
          )}
          <Button block onClick={salvar} disabled={saving}>{saving ? "Salvando…" : "Salvar"}</Button>
        </div>
      </div>
    </div>
  );
}
