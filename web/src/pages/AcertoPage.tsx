import { useState } from "react";
import { useAppStore } from "@/store/useAppStore";
import { useMonthData } from "@/hooks/useMonthData";
import { Card } from "@/components/Card";
import { formatMoney } from "@/core/format/money";
import { splitForPerson } from "@/core/rules/splitForPerson";
import { diffCalculation } from "@/core/rules/diffCalculation";
import type { Person, Row } from "@/core/types";

function readShowDiff(person: Person): boolean {
  if (typeof sessionStorage === "undefined") return true;
  const v = sessionStorage.getItem(`hook-finance-diff-${person}`);
  return v === null ? true : v === "1";
}

export function AcertoPage() {
  const currentMonth = useAppStore((s) => s.currentMonth);
  const monthQ = useMonthData(currentMonth);
  const rows = monthQ.data?.rows ?? [];

  return (
    <>
      <div className="grid gap-3 tablet:grid-cols-2 mb-3">
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

  const [showDiff, setShowDiff] = useState(() => readShowDiff(person));
  function toggleShowDiff() {
    setShowDiff((v) => {
      const next = !v;
      try {
        sessionStorage.setItem(`hook-finance-diff-${person}`, next ? "1" : "0");
      } catch {
        // sessionStorage indisponível — ignora.
      }
      return next;
    });
  }

  const cartao = rows.filter((r) => r.origem === "Cartão");
  const cartaoCompart = cartao
    .filter((r) => r.rateio === "Metade")
    .reduce((s, r) => s + splitForPerson(r, person), 0);
  const cartaoPessoal = cartao
    .filter((r) => r.rateio === "Julio" || r.rateio === "Dani")
    .reduce((s, r) => s + splitForPerson(r, person), 0);

  const pixAllForPerson = rows.filter(
    (r) => r.origem === "Pix (contas)" && r.rateio === person,
  );
  const pixAcerto = pixAllForPerson.filter((r) => r.acerto === "Sim");
  const pixVisible = expanded ? pixAllForPerson : pixAcerto;

  // Julio: section visible if any Pix (mesmo só pra dar alvo de clique).
  // Dani: section só se há Acerto.
  const showSection = isJulio
    ? pixAllForPerson.length > 0
    : pixAcerto.length > 0;

  let total = cartaoCompart + cartaoPessoal;
  for (const r of pixVisible) total += r.valor;

  const diff = diffCalculation(rows, person);
  const diffSign = diff >= 0 ? "+" : "−";
  const diffColor = diff >= 0 ? "text-[#2c5aa0]" : "text-negative";

  return (
    <Card className="overflow-hidden">
      <h3 className="relative bg-accent text-accent-fg text-center text-[0.82rem] font-semibold py-1.5 px-2 rounded-md -mx-1 -mt-1 mb-2.5">
        <span>{person === "Julio" ? "Júlio" : "Dani"}</span>
        <span
          className={
            "absolute right-9 top-1/2 -translate-y-1/2 text-[0.68rem] font-semibold tabular-nums leading-none transition-opacity duration-200 " +
            (showDiff ? "opacity-100" : "opacity-0 pointer-events-none") +
            " " +
            diffColor
          }
          aria-hidden={!showDiff}
        >
          {diffSign} R$ {formatMoney(Math.abs(diff))}
        </span>
        <button
          type="button"
          onClick={toggleShowDiff}
          className={
            "absolute right-1 top-1/2 -translate-y-1/2 z-10 text-[0.75rem] font-bold leading-tight px-1.5 py-0.5 rounded transition " +
            (showDiff
              ? "bg-fg text-white border border-fg"
              : "bg-black/10 text-accent-fg border border-transparent hover:bg-black/20")
          }
          title="Mostrar/ocultar diferença"
          aria-label="Mostrar/ocultar diferença"
        >
          Δ
        </button>
      </h3>
      {loading ? (
        <div className="flex flex-col gap-1.5">
          <div className="skeleton h-5" />
          <div className="skeleton h-5" />
          <div className="skeleton h-5" />
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-[0.78rem] tabular-nums">
            <thead>
              <tr>
                <th className="text-left text-[0.65rem] uppercase tracking-wider text-muted font-semibold py-1.5 px-2 border-b border-border whitespace-nowrap">
                  Despesas agrupadas
                </th>
                <th className="text-right text-[0.65rem] uppercase tracking-wider text-muted font-semibold py-1.5 px-2 border-b border-border whitespace-nowrap">
                  Valor (R$)
                </th>
              </tr>
            </thead>
            <tbody>
              <SummaryRow label="Cartão (compartilhado)" value={formatMoney(cartaoCompart)} />
              <SummaryRow label="Cartão (pessoal)" value={formatMoney(cartaoPessoal)} />
              {showSection && (
                <>
                  <tr>
                    <td
                      colSpan={2}
                      className="font-semibold text-muted uppercase text-[0.65rem] tracking-wider pt-2 pb-1"
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
                      <td className="text-left py-1.5 px-2 border-b border-border truncate max-w-0">
                        {r.descricao}
                      </td>
                      <td className="text-right py-1.5 px-2 border-b border-border whitespace-nowrap w-px">
                        {formatMoney(r.valor)}
                      </td>
                    </tr>
                  ))}
                </>
              )}
              <tr>
                <td className="text-left font-bold py-1.5 px-2 border-t-2 border-fg">
                  Total Pessoal
                </td>
                <td className="text-right font-bold py-1.5 px-2 border-t-2 border-fg whitespace-nowrap">
                  {formatMoney(total)}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      )}
    </Card>
  );
}

function SummaryRow({ label, value }: { label: string; value: string }) {
  return (
    <tr>
      <td className="text-left py-1.5 px-2 border-b border-border whitespace-nowrap">
        {label}
      </td>
      <td className="text-right py-1.5 px-2 border-b border-border whitespace-nowrap">
        {value}
      </td>
    </tr>
  );
}
