export default function CampoLayout({ children }: { children: React.ReactNode }) {
  // Visão do funcionário: só o ponto, sem a navegação do admin.
  return <div className="mx-auto min-h-screen max-w-md bg-papel">{children}</div>;
}
