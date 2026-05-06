import { useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { useAppStore } from "@/store/useAppStore";
import * as api from "@/api/endpoints";
import { Card, CardHeader } from "@/components/Card";
import { formatMoney } from "@/utils/format";
import { splitForPerson } from "@/utils/splitForPerson";
import type { Person, Row } from "@/api/types";

export function AcertoPage() {
  const acertoMonth = useAppStore((s) => s.acertoMonth);
  const setAcertoMonth = useAppStore((s) => s.setAcertoMonth);
  const allMonths = useAppStore((s) => s.allMonths);
  const token = useAppStore((s) => s.token);

  // Quando allMonths chegar, default = mês anterior (índice 1; cai pro [0] se só houver 1).
  useEffect(() => {
    if (!acertoMonth && allMonths.length > 0) {
      setAcertoMonth(allMonths[1] || allMonths[0]);
    }
  }, [acertoMonth, allMonths, setAcertoMonth]);

  const monthQ = useQuery({
    queryKey: ["monthData", acertoMonth ?? "_acerto_pending_"],
    queryFn: () => api.getMonthData(acertoMonth ?? null),
    enabled: !!token && !!acertoMonth,
  });

  const rows = monthQ.data?.rows ?? [];

  return (
    <>
      <div className="sticky top-[-1px] bg-[--color-bg] z-20 mb-3">
        <div className="flex flex-col gap-1 bg-white border border-[--color-border] rounded-lg p-2.5">
          <label
            htmlFor="filter-data-acerto"
            className="text-[0.7rem] text-[--color-muted]"
          >
            Data
          </label>
          <select
            id="filter-data-acerto"
            disabled={!allMonths.length}
            value={acertoMonth ?? ""}
            onChange={(e) => setAcertoMonth(e.target.value)}
            className="w-full text-sm px-2 py-1.5 border border-[--color-border] rounded-md bg-white text-[--color-fg] disabled:opacity-60"
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

      <div className="grid grid-cols-1 tablet:grid-cols-2 gap-2">
        <AcertoCard person="Julio" rows={rows} loading={monthQ.isLoading} />
        <AcertoCard person="Dani" rows={rows} loading={monthQ.isLoading} />
      </div>
    </>
  );
}

interface AcertoCardProps {
  person: Person;
  rows: Row[];
  loading: boolean;
}

function AcertoCard({ person, rows, loading }: AcertoCardProps) {
  const acertoPixJulio = useAppStore((s) => s.acertoPixJulio);
  const toggleAcertoPix = useAppStore((s) => s.toggleAcertoPix);
  const isJulio = person === "Julio";
  const expanded = isJulio && acertoPixJulio;

  const cartao = rows.filter((r) => r.origem === "Cartão");
  const cartaoCompart = cartao
    .filter((r) => r.categoria !== "Pessoal")
    .reduce((s, r) => s + splitForPerson(r, person), 0);
  const cartaoPessoal = cartao
    .filter((r) => r.categoria === "Pessoal")
    .reduce((s, r) => s + splitForPerson(r, person), 0);

  const pixAll = rows.filter(
    (r) => r.origem === "Pix (contas)" && r.rateio === person,
  );
  const pixAcerto = pixAll.filter((r) => r.acerto === "Sim");
  const pixVisible = expanded ? pixAll : pixAcerto;

  // Julio: section visible if any Pix (mesmo só pra dar alvo de clique).
  // Dani: section só se há Acerto.
  const showSection = isJulio ? pixAll.length > 0 : pixAcerto.length > 0;

  let total = cartaoCompart + cartaoPessoal;
  for (const r of pixVisible) total += r.valor;

  return (
    <Card className="p-2 overflow-hidden">
      <CardHeader title={person === "Julio" ? "Júlio" : "Dani"} />
      {loading ? (
        <div className="flex flex-col gap-1.5">
          <div className="skeleton h-5" />
          <div className="skeleton h-5" />
          <div className="skeleton h-5" />
        </div>
      ) : (
        <table className="w-full border-collapse text-[0.7rem] tabular-nums">
          <tbody>
            <Row label="Cartão (compart.)" value={formatMoney(cartaoCompart)} />
            <Row label="Cartão (pessoal)" value={formatMoney(cartaoPessoal)} />
            {showSection && (
              <>
                <tr>
                  <td
                    colSpan={2}
                    className="font-semibold text-[--color-muted] uppercase text-[0.6rem] tracking-wide pt-2 pb-1"
                  >
                    {isJulio ? (
                      <span
                        className="cursor-pointer select-none"
                        onClick={() => toggleAcertoPix()}
                      >
                        Pix (contas)
                      </span>
                    ) : (
                      "Pix (contas)"
                    )}
                  </td>
                </tr>
                {pixVisible.map((r, i) => (
                  <tr key={i}>
                    <td className="text-left py-1 px-0.5 border-b border-[--color-border] truncate max-w-0">
                      {r.descricao}
                    </td>
                    <td className="text-right py-1 px-0.5 border-b border-[--color-border] whitespace-nowrap w-px">
                      {formatMoney(r.valor)}
                    </td>
                  </tr>
                ))}
              </>
            )}
            <tr>
              <td className="text-left font-bold pt-1.5 px-0.5 border-t-2 border-[--color-fg]">
                Total
              </td>
              <td className="text-right font-bold pt-1.5 px-0.5 border-t-2 border-[--color-fg] whitespace-nowrap">
                {formatMoney(total)}
              </td>
            </tr>
          </tbody>
        </table>
      )}
    </Card>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <tr>
      <td className="text-left py-1 px-0.5 border-b border-[--color-border] truncate max-w-0">
        {label}
      </td>
      <td className="text-right py-1 px-0.5 border-b border-[--color-border] whitespace-nowrap w-px">
        {value}
      </td>
    </tr>
  );
}
