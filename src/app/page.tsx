import Link from "next/link";

// Tela inicial provisória — escolha de papel.
// Depois da autenticação, redirecione conforme o perfil do usuário.
export default function Home() {
  return (
    <main className="mx-auto flex min-h-screen max-w-md flex-col justify-center gap-8 px-7">
      <div>
        <div className="mb-5 grid h-20 w-20 place-items-center rounded-full border-2 border-dourado">
          <span className="font-display text-2xl font-bold text-dourado">Plant</span>
        </div>
        <h1 className="font-display text-4xl font-semibold leading-tight text-verde-900">
          Plant<br />Jardinagem
        </h1>
        <p className="mt-2 text-tintaMuda">Relatórios, propostas, financeiro e ponto num lugar só.</p>
      </div>

      <div className="flex flex-col gap-3">
        <Link href="/admin/home" className="rounded-[10px] bg-verde-700 px-5 py-4 text-center font-semibold text-white">
          Entrar como administrador
        </Link>
        <Link href="/campo/ponto" className="rounded-[10px] px-5 py-4 text-center font-semibold text-verde-700 ring-[1.5px] ring-inset ring-verde-400">
          Sou funcionário · bater ponto
        </Link>
      </div>
    </main>
  );
}
