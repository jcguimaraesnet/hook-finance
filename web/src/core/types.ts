// Spec: docs/specs/data/despesas-sheet.md
// Spec: docs/specs/api/endpoints.md
// Tipos espelhando os retornos do Apps Script (mapRow_, getMonthData, etc).

export interface Row {
  data: string; // "DD/MM/YYYY" — invoice closing
  dataRef: string; // "DD/MM/YYYY HH:MM" — purchase datetime
  descricao: string;
  valor: number;
  origem: string; // "Cartão" | "Pix (contas)" | "Pessoal" | "Empregados" | ...
  categoria: string;
  rateio: string; // "Julio" | "Dani" | "Metade" | "Alzira" | ""
  cardLast4: string;
  parcela: string; // "X/Y" or ""
  acerto: string; // "Sim" or ""
}

export interface Entry extends Row {
  row: number; // 1-indexed sheet row (used by updateEntry/deleteEntry)
}

export interface MonthDataResponse {
  ok: boolean;
  error?: string;
  month?: string | null;
  rows?: Row[];
}

export interface HistoricalSummaryResponse {
  ok: boolean;
  error?: string;
  months?: string[]; // descending list of all distinct months
  history?: {
    months: string[]; // ascending last 12
    totals: number[];
    julioPessoal: number[];
    daniPessoal: number[];
  };
}

export interface LastEntriesResponse {
  ok: boolean;
  error?: string;
  entries?: Entry[];
}

export interface UpdateEntryFields {
  descricao: string;
  valor: number;
  categoria: string;
  rateio: string;
  parcela: string; // "" or "1/N"
}

export interface MutationResponse {
  ok: boolean;
  error?: string;
  row?: number;
}

export type ApiResponse =
  | MonthDataResponse
  | HistoricalSummaryResponse
  | LastEntriesResponse
  | MutationResponse;

export type Person = "Julio" | "Dani";
