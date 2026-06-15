"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/Button";
import { Field, inputClass } from "@/components/ui/Field";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [senha, setSenha] = useState("");
  const [erro, setErro] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const entrar = async () => {
    setLoading(true);
    setErro(null);
    const sb = createClient();
    const { error } = await sb.auth.signInWithPassword({ email, password: senha });
    if (error) {
      setErro("E-mail ou senha inválidos.");
      setLoading(false);
      return;
    }
    router.push("/");
    router.refresh();
  };

  return (
    <main className="mx-auto flex min-h-screen max-w-md flex-col justify-center px-7">
      <div className="mb-8 text-center">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/logo.png" alt="Plant Jardinagem" className="mx-auto mb-5 w-40" />
        <h1 className="font-display text-2xl font-semibold text-verde-900">Entrar</h1>
        <p className="mt-1 text-sm text-tintaMuda">Acesse o painel da Plant Jardinagem.</p>
      </div>

      <Field label="E-mail">
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className={inputClass}
          autoComplete="email"
        />
      </Field>
      <Field label="Senha">
        <input
          type="password"
          value={senha}
          onChange={(e) => setSenha(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && entrar()}
          className={inputClass}
          autoComplete="current-password"
        />
      </Field>

      {erro && (
        <p className="mb-3 rounded-[10px] bg-erroBg px-3 py-2 text-sm font-medium text-erro">{erro}</p>
      )}

      <Button block disabled={loading} onClick={entrar}>
        {loading ? "Entrando…" : "Entrar"}
      </Button>
    </main>
  );
}
