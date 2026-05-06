import { useAppStore } from "@/store/useAppStore";
import type { Tab } from "@/store/useAppStore";

const TABS: { id: Tab; label: string }[] = [
  { id: "mes", label: "Mês" },
  { id: "categoria", label: "Categoria" },
  { id: "pessoal", label: "Pessoal" },
  { id: "historico", label: "Histórico" },
];

export function SubTabs() {
  const activeTab = useAppStore((s) => s.activeTab);
  const setActiveTab = useAppStore((s) => s.setActiveTab);
  return (
    <div className="grid grid-cols-4 gap-[3px] bg-white border border-border rounded-lg p-[3px] mb-3 pc:hidden">
      {TABS.map((t) => (
        <button
          key={t.id}
          type="button"
          onClick={() => setActiveTab(t.id)}
          className={
            "text-[0.8rem] font-semibold py-2 px-1 rounded-md transition " +
            (activeTab === t.id
              ? "bg-accent text-accent-fg"
              : "text-muted")
          }
        >
          {t.label}
        </button>
      ))}
    </div>
  );
}
