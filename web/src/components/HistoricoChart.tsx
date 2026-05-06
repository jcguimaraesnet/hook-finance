import "./chartjs-setup";
import { Line } from "react-chartjs-2";
import type { ChartOptions } from "chart.js";
import { Card, CardHeader } from "./Card";
import { formatMoney, moneyK } from "@/utils/format";
import { brDateToMMYYYY } from "@/utils/dates";

interface Series {
  label: string;
  data: number[];
  color: string;
  align: "top" | "bottom";
}

interface Props {
  title: string;
  months: string[]; // "DD/MM/YYYY"
  series: Series[];
  showLegend?: boolean;
}

export function HistoricoChart({ title, months, series, showLegend = true }: Props) {
  const chartData = {
    labels: months,
    datasets: series.map((s) => ({
      label: s.label,
      data: s.data,
      borderColor: s.color,
      backgroundColor: s.color,
      tension: 0.2,
      borderWidth: 1.5,
      pointRadius: 2.5,
      pointHoverRadius: 5,
      datalabels: { align: s.align, offset: 6 },
    })),
  };

  const options: ChartOptions<"line"> = {
    responsive: true,
    maintainAspectRatio: false,
    layout: { padding: { top: 24 } },
    plugins: {
      legend: { display: showLegend },
      tooltip: {
        callbacks: {
          label: (ctx) => `${ctx.dataset.label}: ${formatMoney(ctx.parsed.y ?? 0)}`,
        },
      },
      datalabels: {
        display: true,
        anchor: "end",
        align: "top",
        offset: 4,
        color: (ctx) => (ctx.dataset.borderColor as string) ?? "#000",
        font: { size: 10, weight: 600 },
        formatter: (v: number | null) => moneyK(v ?? 0),
      },
    },
    scales: {
      x: {
        ticks: {
          autoSkip: false,
          maxRotation: 0,
          callback: function (_value, index) {
            if (index % 2 !== 0) return "";
            const label = (this as { getLabelForValue: (i: number) => string })
              .getLabelForValue(index);
            return brDateToMMYYYY(label);
          },
        },
      },
      y: { ticks: { callback: (v) => moneyK(Number(v)) } },
    },
  };

  return (
    <Card>
      <CardHeader title={title} />
      <div className="relative h-[320px] tablet:h-[300px]">
        <Line data={chartData} options={options} />
      </div>
    </Card>
  );
}
