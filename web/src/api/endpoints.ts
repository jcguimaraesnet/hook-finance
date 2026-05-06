import { apiGet, apiPost } from "./client";
import type {
  HistoricalSummaryResponse,
  LastEntriesResponse,
  MonthDataResponse,
  MutationResponse,
  UpdateEntryFields,
} from "./types";

export function getMonthData(month?: string | null): Promise<MonthDataResponse> {
  return apiGet<MonthDataResponse>("monthData", { month: month || undefined });
}

export function getHistoricalSummary(): Promise<HistoricalSummaryResponse> {
  return apiGet<HistoricalSummaryResponse>("historicalSummary");
}

export function getLastEntries(n = 10): Promise<LastEntriesResponse> {
  return apiGet<LastEntriesResponse>("lastEntries", { n });
}

export function updateEntry(
  row: number,
  fields: UpdateEntryFields,
): Promise<MutationResponse> {
  return apiPost<MutationResponse>("updateEntry", { row, fields });
}

export function deleteEntry(row: number): Promise<MutationResponse> {
  return apiPost<MutationResponse>("deleteEntry", { row });
}
