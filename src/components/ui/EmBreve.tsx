export function EmBreve({ titulo, descricao }: { titulo: string; descricao: string }) {
  return (
    <div className="grid min-h-screen place-items-center px-8 pb-24 text-center">
      <div>
        <h1 className="font-display text-2xl font-semibold text-verde-900">{titulo}</h1>
        <p className="mt-1.5 text-sm text-tintaMuda">{descricao}</p>
      </div>
    </div>
  );
}
