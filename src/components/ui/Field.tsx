export function Field({
  label,
  hint,
  children,
}: {
  label: string;
  hint?: string;
  children: React.ReactNode;
}) {
  return (
    <div className="mb-4">
      <label className="mb-1.5 block text-[13px] font-semibold text-tinta">{label}</label>
      {children}
      {hint && <p className="mt-1.5 text-xs text-tintaMuda">{hint}</p>}
    </div>
  );
}

export const inputClass =
  "w-full rounded-[10px] border-[1.5px] border-linha bg-surface px-3.5 py-3 text-tinta outline-none focus:border-verde-500 focus:ring-4 focus:ring-verde-100";
