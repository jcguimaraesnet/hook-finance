import { useState } from "react";
import { splitForPerson } from "@/core/rules/splitForPerson";
import { bucketKey } from "@/core/rules/bucketKey";
import { diffCalculation } from "@/core/rules/diffCalculation";
import { BUCKET_ORDER } from "@/core/constants";
import { formatMoney, formatPct } from "@/core/format/money";
import { Card } from "./Card";
import type { Row, Person } from "@/core/types";

interface Props {
  person: Person;
  rows: Row[];
}

function readShowDiff(person: Person): boolean {
  if (typeof sessionStorage === "undefined") return true;
  const v = sessionStorage.getItem(`hook-finance-diff-${person}`);
  return v === null ? true : v === "1";
}

export function PersonCard({ person, rows }: Props) {
  const [showDiff, setShowDiff] = useState(() => readShowDiff(person));

  function toggleShowDiff() {
    setShowDiff((v) => {
      const next = !v;
      try {
        sessionStorage.setItem(`hook-finance-diff-${person}`, next ? "1" : "0");
      } catch {
        // sessionStorage indisponível (ex. modo privado iOS antigo) — ignora.
      }
      return next;
    });
  }

  const byOrigem: Record<string, number> = {};
  for (const r of rows) {
    const v = splitForPerson(r, person);
    if (v === 0) continue;
    const k = bucketKey(r);
    byOrigem[k] = (byOrigem[k] || 0) + v;
  }
  const total = Object.values(byOrigem).reduce((s, v) => s + v, 0);

  const seen = new Set<string>(BUCKET_ORDER);
  const allKeys = (BUCKET_ORDER as readonly string[]).concat(
    Object.keys(byOrigem).filter((k) => !seen.has(k)),
  );

  const diff = diffCalculation(rows, person);
  const diffSign = diff >= 0 ? "+" : "−";
  const diffColor = diff >= 0 ? "text-[#2c5aa0]" : "text-negative";

  return (
    <Card className="flex flex-col">
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
      <div className="overflow-x-auto">
        <table className="w-full border-collapse text-[0.78rem] tabular-nums">
          <thead>
            <tr>
              <th className="text-left text-[0.65rem] uppercase tracking-wider text-muted font-semibold py-1.5 px-2 border-b border-border">
                Despesas agrupadas
              </th>
              <th className="text-right text-[0.65rem] uppercase tracking-wider text-muted font-semibold py-1.5 px-2 border-b border-border">
                Valor (R$)
              </th>
              <th className="text-right text-[0.65rem] uppercase tracking-wider text-muted font-semibold py-1.5 px-2 border-b border-border">
                %
              </th>
            </tr>
          </thead>
          <tbody>
            {allKeys.map((k) => {
              if (!byOrigem[k]) return null;
              const v = byOrigem[k];
              const pct = total ? v / total : 0;
              const display = k === "Pix (contas)" ? "Pix (contas)" : k;
              return (
                <tr key={k}>
                  <td className="text-left py-1.5 px-2 border-b border-border whitespace-nowrap">
                    {display}
                  </td>
                  <td className="text-right py-1.5 px-2 border-b border-border whitespace-nowrap">
                    {formatMoney(v)}
                  </td>
                  <td className="text-right py-1.5 px-2 border-b border-border whitespace-nowrap">
                    {formatPct(pct)}
                  </td>
                </tr>
              );
            })}
            <tr>
              <td className="text-left font-bold py-1.5 px-2 border-t-2 border-fg">
                Total Pessoal
              </td>
              <td className="text-right font-bold py-1.5 px-2 border-t-2 border-fg">
                {formatMoney(total)}
              </td>
              <td className="text-right font-bold py-1.5 px-2 border-t-2 border-fg">
                {total ? formatPct(1) : "—"}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </Card>
  );
}
