import "./chartjs-setup";
import { Bar } from "react-chartjs-2";
import type { ChartOptions } from "chart.js";
import { Card, CardHeader } from "./Card";
import { formatMoney, moneyK } from "@/core/format/money";
import type { Row } from "@/core/types";

interface Props {
  rows: Row[];
}

function rateioLabel(r: string): string {
  return r === "Metade" ? "Compartilhado" : r;
}

export function RateioChart({ rows }: Props) {
  const cartao = rows.filter((r) => r.origem === "Cartão");
  const byRateio: Record<string, number> = {};
  for (const r of cartao) {
    const k = r.rateio || "(sem rateio)";
    byRateio[k] = (byRateio[k] || 0) + r.valor;
  }
  const data = Object.entries(byRateio)
    .map(([rateio, valor]) => ({ rateio, valor }))
    .sort((a, b) => b.valor - a.valor);

  const chartData = {
    labels: data.map((d) => rateioLabel(d.rateio)),
    datasets: [
      {
        data: data.map((d) => d.valor),
        backgroundColor: "#a07b5e",
        maxBarThickness: 32,
      },
    ],
  };

  const options: ChartOptions<"bar"> = {
    indexAxis: "y",
    responsive: true,
    maintainAspectRatio: false,
    layout: { padding: { right: 64 } },
    plugins: {
      legend: { display: false },
      tooltip: {
        callbacks: {
          label: (ctx) => formatMoney(ctx.parsed.x ?? 0),
        },
      },
      datalabels: {
        display: true,
        clip: false,
        labels: {
          name: {
            anchor: "start",
            align: "right",
            offset: 6,
            color: "white",
            font: { weight: 700, size: 11 },
            formatter: (_v, ctx) =>
              ctx.chart.data.labels?.[ctx.dataIndex] as string,
          },
          value: {
            anchor: "end",
            align: "right",
            offset: 6,
            color: "#262626",
            font: { weight: 600, size: 11 },
            formatter: (v: number | null) => formatMoney(v ?? 0),
          },
        },
      },
    },
    scales: {
      x: { ticks: { callback: (v) => moneyK(Number(v)) } },
      y: { ticks: { display: false }, grid: { display: false } },
    },
  };

  return (
    <Card>
      <CardHeader title="Cartão (por pessoa)" />
      <div className="relative h-[280px] tablet:h-[280px] pc:h-[300px]">
        <Bar data={chartData} options={options} />
      </div>
    </Card>
  );
}
