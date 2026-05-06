import { useQuery } from "@tanstack/react-query";
import * as api from "@/api/endpoints";
import { useAppStore } from "@/store/useAppStore";

export function useMonthData(month?: string | null) {
  const token = useAppStore((s) => s.token);
  return useQuery({
    queryKey: ["monthData", month ?? "_latest_"],
    queryFn: () => api.getMonthData(month ?? null),
    enabled: !!token,
  });
}
