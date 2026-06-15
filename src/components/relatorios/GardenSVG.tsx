// Ilustração placeholder usada quando o relatório ainda não tem foto.
export function GardenSVG({ depois }: { depois?: boolean }) {
  const common = {
    viewBox: "0 0 100 100",
    preserveAspectRatio: "xMidYMid slice",
    className: "block h-full w-full",
  } as const;

  if (depois) {
    return (
      <svg {...common}>
        <rect width="100" height="100" fill="#6FA15A" />
        <path d="M0 68h100v32H0z" fill="#4E7D3E" />
        <circle cx="30" cy="52" r="17" fill="#3E6B33" />
        <circle cx="64" cy="46" r="21" fill="#477A3A" />
        <rect x="28" y="60" width="4" height="16" fill="#5A4530" />
        <rect x="62" y="64" width="5" height="14" fill="#5A4530" />
      </svg>
    );
  }
  return (
    <svg {...common}>
      <rect width="100" height="100" fill="#D8CBB0" />
      <path d="M0 70h100v30H0z" fill="#C2B188" />
      <path d="M30 70c2-14 4-22 5-30M40 70c0-12 1-20 2-26M50 72c-1-10 0-18 1-22" stroke="#A89766" strokeWidth="2" fill="none" />
    </svg>
  );
}
