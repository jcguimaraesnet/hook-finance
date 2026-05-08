import { create } from "zustand";
import { persist } from "zustand/middleware";

export type Page = "consulta" | "detalhe" | "lancamento" | "acerto";
export type Tab = "mes" | "categoria" | "pessoal" | "historico";
export type Person = "Julio" | "Dani";

/** Spec: docs/specs/state/persistence.md — PWA usa expiração absoluta de 15min. */
export const SESSION_TIMEOUT_MS = 15 * 60 * 1000;

interface AppState {
  // Auth
  token: string | null;
  loginAt: number | null;
  signIn: (token: string) => void;
  signOut: () => void;
  isExpired: () => boolean;

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

  // UI toggles
  acertoPixJulio: boolean;
  toggleAcertoPix: () => void;
}

export const useAppStore = create<AppState>()(
  persist(
    (set, get) => ({
      token: null,
      loginAt: null,
      signIn: (token) => set({ token, loginAt: Date.now() }),
      signOut: () => set({ token: null, loginAt: null }),
      isExpired: () => {
        const { token, loginAt } = get();
        if (!token) return false;
        if (!loginAt) return true; // token persistido legado sem timestamp
        return Date.now() - loginAt > SESSION_TIMEOUT_MS;
      },

      activePage: "consulta",
      setActivePage: (p) => set({ activePage: p }),
      activeTab: "mes",
      setActiveTab: (t) => set({ activeTab: t }),

      currentMonth: null,
      setCurrentMonth: (m) => set({ currentMonth: m }),
      allMonths: [],
      setAllMonths: (months) => set({ allMonths: months }),

      acertoPixJulio: false,
      toggleAcertoPix: () => set((s) => ({ acertoPixJulio: !s.acertoPixJulio })),
    }),
    {
      name: "hook-finance-store",
      // Não persistir allMonths (recarregado a cada sessão).
      partialize: (s) => ({
        token: s.token,
        loginAt: s.loginAt,
        activePage: s.activePage,
        activeTab: s.activeTab,
        acertoPixJulio: s.acertoPixJulio,
      }),
    },
  ),
);
