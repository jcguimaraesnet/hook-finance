import { useState } from "react";
import { useAppStore } from "@/store/useAppStore";
import { useLastEntries } from "@/hooks/useLastEntries";
import { useMonthData } from "@/hooks/useMonthData";
import { formatMoney, parcelaTotal } from "@/utils/format";
import { EditModal } from "@/components/EditModal";
import type { Entry } from "@/api/types";

export function LancamentoPage() {
  const currentMonth = useAppStore((s) => s.currentMonth);
  const lastQ = useLastEntries(10);
  const monthQ = useMonthData(currentMonth);
  const [editing, setEditing] = useState<Entry | null>(null);

  const entries = lastQ.data?.entries ?? [];

  return (
    <>
      {editing ? (
        <EditModal
          entry={editing}
          rowsForCategoriaSuggestions={monthQ.data?.rows ?? []}
          onClose={() => setEditing(null)}
        />
      ) : (
        <>
          {lastQ.isLoading && (
            <div className="flex flex-col gap-2">
              <div className="skeleton h-12" />
              <div className="skeleton h-12" />
              <div className="skeleton h-12" />
            </div>
          )}

          {!lastQ.isLoading && entries.length === 0 && (
            <p className="text-sm text-muted text-center py-8">
              Sem lançamentos.
            </p>
          )}

          <div className="flex flex-col gap-2">
            {entries.map((e) => {
              const totalP = parcelaTotal(e.parcela);
              return (
                <button
                  key={e.row}
                  type="button"
                  onClick={() => setEditing(e)}
                  className="text-left bg-white border border-border rounded-lg p-2.5 grid grid-cols-[1fr_auto] gap-1 hover:bg-[#fbf8f1]"
                >
                  <div className="text-[0.7rem] text-muted col-span-2">
                    {e.dataRef} · {e.origem}
                  </div>
                  <div className="text-[0.9rem] font-semibold text-fg truncate">
                    {e.descricao}
                  </div>
                  <div className="text-[0.95rem] font-semibold tabular-nums text-right">
                    R$ {formatMoney(e.valor)}
                  </div>
                  <div className="col-span-2 flex gap-1.5 flex-wrap text-[0.7rem] text-muted">
                    {e.categoria && (
                      <span className="bg-[#f0ece2] rounded-full px-2 py-0.5">
                        {e.categoria}
                      </span>
                    )}
                    {e.rateio && (
                      <span className="bg-[#f0ece2] rounded-full px-2 py-0.5">
                        {e.rateio}
                      </span>
                    )}
                    {totalP > 1 && (
                      <span className="bg-accent text-accent-fg font-semibold rounded-full px-2 py-0.5">
                        {e.parcela}
                      </span>
                    )}
                  </div>
                </button>
              );
            })}
          </div>
        </>
      )}
    </>
  );
}
