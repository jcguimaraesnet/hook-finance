import { useAppStore } from "@/store/useAppStore";
import { useMonthData } from "@/hooks/useMonthData";
import { formatMoney } from "@/core/format/money";
import { isParcelado } from "@/core/rules/parcela";

interface Props {
  disabled?: boolean;
}

export function StickyHeader({ disabled = false }: Props) {
  const currentMonth = useAppStore((s) => s.currentMonth);
  const allMonths = useAppStore((s) => s.allMonths);
  const setCurrentMonth = useAppStore((s) => s.setCurrentMonth);
  // Disabled mode (Lançamento): always fetch the latest invoice month, independent of shared currentMonth.
  const monthQ = useMonthData(disabled ? null : currentMonth);

  const rows = monthQ.data?.rows;
  const isLoading = monthQ.isLoading;
  const displayMonth = disabled ? (monthQ.data?.month ?? null) : currentMonth;

  const totalGeral = rows ? rows.reduce((s, r) => s + r.valor, 0) : 0;
  const totalCartao = rows
    ? rows.filter((r) => r.origem === "Cartão").reduce((s, r) => s + r.valor, 0)
    : 0;
  const totalParcelado = rows
    ? rows.filter((r) => isParcelado(r.parcela)).reduce((s, r) => s + r.valor, 0)
    : 0;

  const cellClass =
    "flex flex-col items-center text-center gap-0.5 px-1 first:border-r-0 not-first:border-l not-first:border-border";

  return (
    <div className="sticky top-[-1px] tablet:static bg-bg z-20 mb-3">
      <div className="grid grid-cols-3 gap-1 bg-white border border-border rounded-lg p-2.5 tablet:bg-transparent tablet:border-0 tablet:p-0 tablet:grid-cols-4 tablet:gap-3">
        <div className="col-span-3 flex flex-col gap-1 border-b border-border pb-1.5 mb-0.5 tablet:col-span-1 tablet:bg-white tablet:border tablet:border-border tablet:rounded-lg tablet:p-3 tablet:pb-3 tablet:mb-0">
          <label htmlFor="filter-data" className="text-[0.7rem] text-muted tablet:text-[0.8rem]">
            Data
          </label>
          <select
            id="filter-data"
            disabled={disabled || !allMonths.length}
            value={displayMonth ?? ""}
            onChange={(e) => setCurrentMonth(e.target.value)}
            className="w-full text-sm tablet:text-base px-2 py-1.5 border border-border rounded-md bg-white text-fg disabled:opacity-60"
          >
            {disabled ? (
              <option value={displayMonth ?? ""}>{displayMonth ?? "—"}</option>
            ) : allMonths.length === 0 ? (
              <option value={displayMonth ?? ""}>{displayMonth ?? "—"}</option>
            ) : (
              allMonths.map((m) => (
                <option key={m} value={m}>
                  {m}
                </option>
              ))
            )}
          </select>
        </div>
        <Tile label="Total geral" value={totalGeral} loading={isLoading} cls={cellClass} />
        <Tile label="Total cartão" value={totalCartao} loading={isLoading} cls={cellClass} />
        <Tile label="Total parcelado" value={totalParcelado} loading={isLoading} cls={cellClass} />
      </div>
    </div>
  );
}

function Tile({
  label,
  value,
  loading,
  cls,
}: {
  label: string;
  value: number;
  loading: boolean;
  cls: string;
}) {
  return (
    <div className={`${cls} tablet:bg-white tablet:border tablet:border-border tablet:rounded-lg tablet:p-3 tablet:items-start tablet:text-left tablet:border-l-0`}>
      <span className="text-[0.65rem] text-muted tablet:text-[0.75rem]">{label}</span>
      {loading ? (
        <span className="skeleton block h-4 w-16" />
      ) : (
        <strong className="text-[0.9rem] tabular-nums tablet:text-[1.1rem] pc:text-[1.2rem]">
          {formatMoney(value)}
        </strong>
      )}
    </div>
  );
}
