// Spec: docs/specs/conventions.md (Datas)

const MONTH_NAMES_PT = [
  "janeiro",
  "fevereiro",
  "março",
  "abril",
  "maio",
  "junho",
  "julho",
  "agosto",
  "setembro",
  "outubro",
  "novembro",
  "dezembro",
];

/** "DD/MM/YYYY" -> Date (epoch comparável). Inválido -> Date(0). */
export function parseBrDate(s: string): Date {
  const parts = String(s || "").split("/");
  if (parts.length !== 3) return new Date(0);
  const d = parseInt(parts[0], 10) || 1;
  const m = parseInt(parts[1], 10) || 1;
  const y = parseInt(parts[2], 10) || 1970;
  return new Date(y, m - 1, d);
}

/** "06/05/2026" -> "maio de 2026". */
export function monthYearLabel(brDate: string | null | undefined): string {
  if (!brDate) return "";
  const parts = brDate.split("/");
  if (parts.length !== 3) return brDate;
  const m = parseInt(parts[1], 10);
  const y = parts[2];
  const name = MONTH_NAMES_PT[m - 1] || `mês ${m}`;
  return `${name} de ${y}`;
}

/** "06/05/2026" -> "05/2026". Usado em ticks de eixo X dos gráficos. */
export function brDateToMMYYYY(brDate: string): string {
  const parts = brDate.split("/");
  if (parts.length !== 3) return brDate;
  return `${parts[1]}/${parts[2]}`;
}
