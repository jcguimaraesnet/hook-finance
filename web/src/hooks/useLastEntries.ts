import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import * as api from "@/api/endpoints";
import { useAppStore } from "@/store/useAppStore";
import type { UpdateEntryFields } from "@/api/types";

export function useLastEntries(n = 10) {
  const token = useAppStore((s) => s.token);
  return useQuery({
    queryKey: ["lastEntries", n],
    queryFn: () => api.getLastEntries(n),
    enabled: !!token,
  });
}

export function useUpdateEntry() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ row, fields }: { row: number; fields: UpdateEntryFields }) =>
      api.updateEntry(row, fields),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["lastEntries"] });
      qc.invalidateQueries({ queryKey: ["monthData"] });
    },
  });
}

export function useDeleteEntry() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (row: number) => api.deleteEntry(row),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["lastEntries"] });
      qc.invalidateQueries({ queryKey: ["monthData"] });
    },
  });
}
