import { create } from "zustand";
import { persist } from "zustand/middleware";

export type Page = "consulta" | "detalhe" | "lancamento" | "acerto";
export type Tab = "mes" | "categoria" | "pessoal" | "historico";
export type Person = "Julio" | "Dani";

interface AppState {
  // Auth
  token: string | null;
  setToken: (t: string | null) => void;

  // Navigation
  activePage: Page;
  setActivePage: (p: Page) => void;
  activeTab: Tab;
  setActiveTab: (t: Tab) => void;

  // Month state
  currentMonth: string | null;
  setCurrentMonth: (m: string | null) => void;
  allMonths: string[];
  setAllMonths: (months: string[]) => void;

  // UI toggles per person
  diffJulio: boolean;
  diffDani: boolean;
  toggleDiff: (p: Person) => void;
  acertoPixJulio: boolean;
  toggleAcertoPix: () => void;
}

export const useAppStore = create<AppState>()(
  persist(
    (set) => ({
      token: null,
      setToken: (t) => set({ token: t }),

      activePage: "consulta",
      setActivePage: (p) => set({ activePage: p }),
      activeTab: "mes",
      setActiveTab: (t) => set({ activeTab: t }),

      currentMonth: null,
      setCurrentMonth: (m) => set({ currentMonth: m }),
      allMonths: [],
      setAllMonths: (months) => set({ allMonths: months }),

      diffJulio: true,
      diffDani: true,
      toggleDiff: (p) =>
        set((s) =>
          p === "Julio" ? { diffJulio: !s.diffJulio } : { diffDani: !s.diffDani },
        ),
      acertoPixJulio: false,
      toggleAcertoPix: () => set((s) => ({ acertoPixJulio: !s.acertoPixJulio })),
    }),
    {
      name: "hook-finance-store",
      version: 1,
      // v0 → v1: liga Diff por padrão; usuário pode ocultar manualmente depois.
      migrate: (persisted, version) => {
        const p = (persisted as Partial<AppState>) ?? {};
        const next = version < 1 ? { ...p, diffJulio: true, diffDani: true } : p;
        return next as AppState;
      },
      // Não persistir allMonths (recarregado a cada sessão).
      partialize: (s) => ({
        token: s.token,
        activePage: s.activePage,
        activeTab: s.activeTab,
        diffJulio: s.diffJulio,
        diffDani: s.diffDani,
        acertoPixJulio: s.acertoPixJulio,
      }),
    },
  ),
);
