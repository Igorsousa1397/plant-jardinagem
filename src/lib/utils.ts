export function cn(...parts: Array<string | false | null | undefined>): string {
  return parts.filter(Boolean).join(" ");
}

/** ISO (aaaa-mm-dd) -> exibição dd/mm/aaaa */
export function fmtData(iso: string): string {
  if (!iso) return "";
  const [y, m, d] = iso.split("-");
  return `${d}/${m}/${y}`;
}

/** exibição dd/mm/aaaa -> ISO (aaaa-mm-dd) para inputs type=date */
export function toISO(display: string): string {
  if (!display) return "";
  const [d, m, y] = display.split("/");
  if (!d || !m || !y) return "";
  return `${y}-${m}-${d}`;
}

/** exibição dd/mm/aaaa -> Date (ou null) */
export function parseBR(display: string): Date | null {
  if (!display) return null;
  const [d, m, y] = display.split("/").map(Number);
  if (!d || !m || !y) return null;
  return new Date(y, m - 1, d);
}

/** mantém só dígitos (para links wa.me) */
export function soDigitos(s: string): string {
  return (s || "").replace(/\D/g, "");
}
