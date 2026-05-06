import { useEffect } from "react";
import { useAppStore } from "@/store/useAppStore";
import { useMonthData } from "@/hooks/useMonthData";
import { useHistoricalSummary } from "@/hooks/useHistoricalSummary";
import { StickyHeader } from "@/components/StickyHeader";
import { SubTabs } from "@/components/SubTabs";
import { PersonCard } from "@/components/PersonCard";
import { CategoriaTable } from "@/components/CategoriaTable";
import { RateioChart } from "@/components/RateioChart";
import { HistoricoChart } from "@/components/HistoricoChart";

const PC_QUERY = "(min-width: 750px)";

function usePCWeb(): boolean {
  const matches = typeof window !== "undefined" && window.matchMedia(PC_QUERY).matches;
  return matches;
}

export function ConsultaPage() {
  const currentMonth = useAppStore((s) => s.currentMonth);
  const setCurrentMonth = useAppStore((s) => s.setCurrentMonth);
  const setAllMonths = useAppStore((s) => s.setAllMonths);
  const activeTab = useAppStore((s) => s.activeTab);

  const monthQ = useMonthData(currentMonth);
  const historyQ = useHistoricalSummary();

  // Quando vier o monthData (sem month explícito), define currentMonth no store.
  useEffect(() => {
    if (!currentMonth && monthQ.data?.month) {
      setCurrentMonth(monthQ.data.month);
    }
  }, [currentMonth, monthQ.data?.month, setCurrentMonth]);

  // Quando vier historicalSummary, popula allMonths.
  useEffect(() => {
    if (historyQ.data?.months) setAllMonths(historyQ.data.months);
  }, [historyQ.data?.months, setAllMonths]);

  const rows = monthQ.data?.rows ?? [];
  const isPC = usePCWeb();

  const showMes = isPC || activeTab === "mes";
  const showCategoria = isPC || activeTab === "categoria";
  const showPessoal = isPC || activeTab === "pessoal";
  const showHistorico = isPC || activeTab === "historico";

  const months = historyQ.data?.history?.months ?? [];
  const totals = historyQ.data?.history?.totals ?? [];
  const julioP = historyQ.data?.history?.julioPessoal ?? [];
  const daniP = historyQ.data?.history?.daniPessoal ?? [];

  return (
    <>
      <StickyHeader rows={monthQ.data?.rows} isLoading={monthQ.isLoading} />
      <SubTabs />

      {showMes && (
        <section className="grid gap-3 tablet:grid-cols-2 mb-3">
          <PersonCard person="Julio" rows={rows} />
          <PersonCard person="Dani" rows={rows} />
        </section>
      )}

      {showCategoria && (
        <section className={isPC ? "grid gap-3 tablet:grid-cols-2 mb-3" : "mb-3"}>
          <CategoriaTable rows={rows} />
          {isPC && <RateioChart rows={rows} />}
        </section>
      )}

      {showPessoal && !isPC && (
        <section className="mb-3">
          <RateioChart rows={rows} />
        </section>
      )}

      {showHistorico && (
        <section className="grid gap-3">
          <HistoricoChart
            title="Histórico — Total geral"
            months={months}
            series={[
              { label: "Total geral", data: totals, color: "#a07b5e", align: "top" },
            ]}
            showLegend={false}
          />
          <HistoricoChart
            title="Histórico — Pessoal"
            months={months}
            series={[
              { label: "Julio", data: julioP, color: "#4a7ab8", align: "top" },
              { label: "Dani", data: daniP, color: "#c97070", align: "bottom" },
            ]}
          />
        </section>
      )}

      {monthQ.isError && (
        <p className="text-[--color-negative] text-sm text-center mt-4">
          Erro carregando dados do mês.
        </p>
      )}
    </>
  );
}
