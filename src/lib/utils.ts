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

/** número -> "R$ 3.200,00" */
export function fmtBRL(n: number): string {
  return (n || 0).toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
}

const MESES_EXTENSO = [
  "janeiro", "fevereiro", "março", "abril", "maio", "junho",
  "julho", "agosto", "setembro", "outubro", "novembro", "dezembro",
];

/** dd/mm/aaaa -> "21 de julho de 2025" */
export function dataExtenso(display: string): string {
  const d = parseBR(display);
  if (!d) return display;
  return `${d.getDate()} de ${MESES_EXTENSO[d.getMonth()]} de ${d.getFullYear()}`;
}
