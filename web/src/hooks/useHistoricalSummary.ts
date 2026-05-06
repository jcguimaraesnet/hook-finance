import { useQuery } from "@tanstack/react-query";
import * as api from "@/api/endpoints";
import { useAppStore } from "@/store/useAppStore";

export function useHistoricalSummary() {
  const token = useAppStore((s) => s.token);
  return useQuery({
    queryKey: ["historicalSummary"],
    queryFn: () => api.getHistoricalSummary(),
    enabled: !!token,
    staleTime: 5 * 60_000, // histórico muda raro; cache 5min
  });
}
