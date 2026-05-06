import { Routes, Route, Navigate, useLocation } from "react-router-dom";
import { useEffect } from "react";
import { useAppStore } from "@/store/useAppStore";
import { PrimaryNav } from "@/components/PrimaryNav";
import { LoginPage } from "@/pages/LoginPage";
import { PlaceholderPage } from "@/pages/PlaceholderPage";
import { ConsultaPage } from "@/pages/ConsultaPage";
import { DetalhePage } from "@/pages/DetalhePage";
import { LancamentoPage } from "@/pages/LancamentoPage";

export default function App() {
  const token = useAppStore((s) => s.token);
  if (!token) return <LoginPage />;
  return <AppShell />;
}

function AppShell() {
  const location = useLocation();
  const setActivePage = useAppStore((s) => s.setActivePage);

  useEffect(() => {
    const seg = location.pathname.split("/")[1] || "consulta";
    if (["consulta", "detalhe", "lancamento", "acerto"].includes(seg)) {
      setActivePage(seg as "consulta" | "detalhe" | "lancamento" | "acerto");
    }
  }, [location.pathname, setActivePage]);

  return (
    <div className="min-h-dvh max-w-[880px] mx-auto p-3 pb-20 tablet:pb-3">
      <PrimaryNav />
      <Routes>
        <Route path="/" element={<Navigate to="/consulta" replace />} />
        <Route path="/consulta" element={<ConsultaPage />} />
        <Route path="/detalhe" element={<DetalhePage />} />
        <Route path="/lancamento" element={<LancamentoPage />} />
        <Route
          path="/acerto"
          element={<PlaceholderPage title="Acerto" note="Próxima task: D.5" />}
        />
        <Route path="*" element={<Navigate to="/consulta" replace />} />
      </Routes>
    </div>
  );
}
