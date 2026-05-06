import { useAppStore } from "@/store/useAppStore";
import { useMonthData } from "@/hooks/useMonthData";
import { formatMoney } from "@/utils/format";
import type { Row } from "@/api/types";

const PREFERRED_ORDER = ["Julio", "Dani", "Alzira"];

interface PersonGroup {
  total: number;
  items: Row[];
}

export function DetalhePage() {
  const currentMonth = useAppStore((s) => s.currentMonth);
  const setCurrentMonth = useAppStore((s) => s.setCurrentMonth);
  const allMonths = useAppStore((s) => s.allMonths);
  const monthQ = useMonthData(currentMonth);

  const rows = monthQ.data?.rows ?? [];
  const byPerson: Record<string, PersonGroup> = {};
  for (const r of rows) {
    if (r.categoria !== "Pessoal") continue;
    if (!r.rateio || r.rateio === "Metade") continue;
    if (!byPerson[r.rateio]) byPerson[r.rateio] = { total: 0, items: [] };
    byPerson[r.rateio].total += r.valor;
    byPerson[r.rateio].items.push(r);
  }
  const others = Object.keys(byPerson)
    .filter((p) => !PREFERRED_ORDER.includes(p))
    .sort();
  const ordered = [...PREFERRED_ORDER, ...others].filter((p) => byPerson[p]);

  return (
    <>
      <div className="sticky top-[-1px] bg-bg z-20 mb-3">
        <div className="flex flex-col gap-1 bg-white border border-border rounded-lg p-2.5">
          <label
            htmlFor="filter-data-detalhe"
            className="text-[0.7rem] text-muted"
          >
            Data
          </label>
          <select
            id="filter-data-detalhe"
            disabled={!allMonths.length}
            value={currentMonth ?? ""}
            onChange={(e) => setCurrentMonth(e.target.value)}
            className="w-full text-sm px-2 py-1.5 border border-border rounded-md bg-white text-fg disabled:opacity-60"
          >
            {allMonths.length === 0 ? (
              <option>—</option>
            ) : (
              allMonths.map((m) => (
                <option key={m} value={m}>
                  {m}
                </option>
              ))
            )}
          </select>
        </div>
      </div>

      {monthQ.isLoading && (
        <div className="flex flex-col gap-2">
          <div className="skeleton h-12" />
          <div className="skeleton h-12" />
          <div className="skeleton h-12" />
        </div>
      )}

      {!monthQ.isLoading && ordered.length === 0 && (
        <p className="text-sm text-muted text-center py-8">
          Sem despesas pessoais neste mês.
        </p>
      )}

      <div className="flex flex-col gap-2">
        {ordered.map((person) => {
          const data = byPerson[person];
          const items = [...data.items].sort((a, b) =>
            String(b.dataRef).localeCompare(String(a.dataRef)),
          );
          return (
            <details
              key={person}
              className="bg-white border border-border rounded-lg overflow-hidden"
            >
              <summary className="cursor-pointer select-none flex items-center justify-between gap-2 py-2.5 px-3 font-semibold list-none [&::-webkit-details-marker]:hidden">
                <span className="flex items-center gap-2">
                  <span className="text-muted text-sm transition-transform">
                    ▸
                  </span>
                  <span className="text-[0.95rem]">{person}</span>
                </span>
                <span className="tabular-nums text-[0.95rem]">
                  R$ {formatMoney(data.total)}
                </span>
              </summary>
              <div className="px-3 pb-3 border-t border-border">
                <div className="overflow-x-auto">
                  <table className="w-full border-collapse text-[0.78rem] tabular-nums mt-2">
                    <thead>
                      <tr>
                        <th className="text-left text-[0.65rem] uppercase tracking-wider text-muted font-semibold py-1.5 px-2 border-b border-border">
                          Data
                        </th>
                        <th className="text-left text-[0.65rem] uppercase tracking-wider text-muted font-semibold py-1.5 px-2 border-b border-border">
                          Descrição
                        </th>
                        <th className="text-right text-[0.65rem] uppercase tracking-wider text-muted font-semibold py-1.5 px-2 border-b border-border">
                          Valor (R$)
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {items.map((it, i) => (
                        <tr key={i}>
                          <td className="text-left py-1.5 px-2 border-b border-border whitespace-nowrap">
                            {it.dataRef}
                          </td>
                          <td className="text-left py-1.5 px-2 border-b border-border whitespace-nowrap">
                            {it.descricao}
                          </td>
                          <td className="text-right py-1.5 px-2 border-b border-border whitespace-nowrap">
                            {formatMoney(it.valor)}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </details>
          );
        })}
      </div>
    </>
  );
}
