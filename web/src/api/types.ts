// Tipos vivem em @/core/types. Este arquivo é um shim de back-compat.
// Spec: docs/specs/data/despesas-sheet.md, docs/specs/api/endpoints.md
export type {
  Row,
  Entry,
  MonthDataResponse,
  HistoricalSummaryResponse,
  LastEntriesResponse,
  UpdateEntryFields,
  MutationResponse,
  ApiResponse,
  Person,
} from "@/core/types";
