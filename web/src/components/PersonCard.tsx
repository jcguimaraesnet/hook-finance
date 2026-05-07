import { useState } from "react";
import { splitForPerson } from "@/utils/splitForPerson";
import { formatMoney, formatPct } from "@/utils/format";
import { Card } from "./Card";
import type { Row, Person } from "@/api/types";

interface Props {
  person: Person;
  rows: Row[];
}

const ORDER = [
  "Cartão (compartilhado)",
  "Cartão (pessoal)",
  "Pix (contas)",
  "Pessoal",
  "Empregados",
];

function bucketKey(row: Row): string {
  if (row.origem === "Cartão") {
    return row.categoria === "Pessoal"
      ? "Cartão (pessoal)"
      : "Cartão (compartilhado)";
  }
  return row.origem;
}

export function PersonCard({ person, rows }: Props) {
  const [showDiff, setShowDiff] = useState(true);

  const byOrigem: Record<string, number> = {};
  for (const r of rows) {
    const v = splitForPerson(r, person);
    if (v === 0) continue;
    const k = bucketKey(r);
    byOrigem[k] = (byOrigem[k] || 0) + v;
  }
  const total = Object.values(byOrigem).reduce((s, v) => s + v, 0);

  const seen = new Set(ORDER);
  const allKeys = ORDER.concat(Object.keys(byOrigem).filter((k) => !seen.has(k)));

  // Diff = (this person's Pix or Contas+Empregados) - (other person's same)
  const otherPerson: Person = person === "Julio" ? "Dani" : "Julio";
  const otherByOrigem: Record<string, number> = {};
  for (const r of rows) {
    const v = splitForPerson(r, otherPerson);
    if (v === 0) continue;
    const k = bucketKey(r);
    otherByOrigem[k] = (otherByOrigem[k] || 0) + v;
  }
  const monthHasPix = rows.some((r) => r.origem === "Pix (contas)");
  const meu = monthHasPix
    ? byOrigem["Pix (contas)"] || 0
    : (byOrigem["Contas"] || 0) + (byOrigem["Empregados"] || 0);
  const outro = monthHasPix
    ? otherByOrigem["Pix (contas)"] || 0
    : (otherByOrigem["Contas"] || 0) + (otherByOrigem["Empregados"] || 0);
  const diff = meu - outro;
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
          onClick={() => setShowDiff((v) => !v)}
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
