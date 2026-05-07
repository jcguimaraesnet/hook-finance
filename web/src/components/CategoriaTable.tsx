import { Card, CardHeader } from "./Card";
import { formatMoney, formatPct } from "@/utils/format";
import type { Row } from "@/api/types";

interface Props {
  rows: Row[];
}

export function CategoriaTable({ rows }: Props) {
  const cartao = rows.filter((r) => r.origem === "Cartão");
  const byCat: Record<string, number> = {};
  for (const r of cartao) {
    const k = r.categoria || "(sem categoria)";
    byCat[k] = (byCat[k] || 0) + r.valor;
  }
  const totalCheio = Object.values(byCat).reduce((s, v) => s + v, 0);
  const list = Object.entries(byCat)
    .map(([cat, cheio]) => ({
      cat,
      cheio,
      metade: cheio / 2,
      pct: totalCheio ? cheio / totalCheio : 0,
    }))
    .sort((a, b) => b.cheio - a.cheio);

  return (
    <Card>
      <CardHeader title="Cartão compartilhado (por categoria)" />
      <div className="overflow-x-auto">
        <table className="w-full border-collapse text-[0.78rem] tabular-nums">
          <thead>
            <tr>
              <th className="text-left text-[0.65rem] uppercase tracking-wider text-muted font-semibold py-1.5 px-2 border-b border-border">
                Categoria
              </th>
              <th className="text-right text-[0.65rem] uppercase tracking-wider text-muted font-semibold py-1.5 px-2 border-b border-border">
                Valor (R$)
              </th>
              <th className="text-right text-[0.65rem] uppercase tracking-wider text-muted font-semibold py-1.5 px-2 border-b border-border">
                Compart. (R$)
              </th>
              <th className="text-right text-[0.65rem] uppercase tracking-wider text-muted font-semibold py-1.5 px-2 border-b border-border">
                %
              </th>
            </tr>
          </thead>
          <tbody>
            {list.map((r) => (
              <tr key={r.cat}>
                <td className="text-left py-1.5 px-2 border-b border-border whitespace-nowrap">
                  {r.cat}
                </td>
                <td className="text-right py-1.5 px-2 border-b border-border whitespace-nowrap">
                  {formatMoney(r.cheio)}
                </td>
                <td className="text-right py-1.5 px-2 border-b border-border whitespace-nowrap">
                  {r.cat === "Pessoal" ? "—" : formatMoney(r.metade)}
                </td>
                <td className="text-right py-1.5 px-2 border-b border-border whitespace-nowrap">
                  {formatPct(r.pct)}
                </td>
              </tr>
            ))}
            <tr>
              <td className="text-left font-bold py-1.5 px-2 border-t-2 border-fg">
                Total Geral
              </td>
              <td className="text-right font-bold py-1.5 px-2 border-t-2 border-fg">
                {formatMoney(totalCheio)}
              </td>
              <td className="text-right font-bold py-1.5 px-2 border-t-2 border-fg">
                —
              </td>
              <td className="text-right font-bold py-1.5 px-2 border-t-2 border-fg">
                {totalCheio ? formatPct(1) : "—"}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </Card>
  );
}
