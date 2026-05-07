import { Routes, Route, Navigate, useLocation } from "react-router-dom";
import { useEffect } from "react";
import { useAppStore } from "@/store/useAppStore";
import { PrimaryNav } from "@/components/PrimaryNav";
import { InstallPrompt } from "@/components/InstallPrompt";
import { StickyHeader } from "@/components/StickyHeader";
import { LoginPage } from "@/pages/LoginPage";
import { ConsultaPage } from "@/pages/ConsultaPage";
import { DetalhePage } from "@/pages/DetalhePage";
import { LancamentoPage } from "@/pages/LancamentoPage";
import { AcertoPage } from "@/pages/AcertoPage";

export default function App() {
  const token = useAppStore((s) => s.token);
  if (!token) return <LoginPage />;
  return <AppShell />;
}

function AppShell() {
  const location = useLocation();
  const setActivePage = useAppStore((s) => s.setActivePage);
  const seg = location.pathname.split("/")[1] || "consulta";
  const isLancamento = seg === "lancamento";

  useEffect(() => {
    if (["consulta", "detalhe", "lancamento", "acerto"].includes(seg)) {
      setActivePage(seg as "consulta" | "detalhe" | "lancamento" | "acerto");
    }
  }, [seg, setActivePage]);

  return (
    <div className="min-h-dvh max-w-[880px] mx-auto px-3 pb-20 tablet:pb-3">
      <div className="pt-3 tablet:sticky tablet:top-0 tablet:z-30 tablet:bg-bg">
        <PrimaryNav />
        {isLancamento ? (
          <StickyHeader key="fixed" disabled />
        ) : (
          <StickyHeader key="shared" />
        )}
      </div>
      <InstallPrompt />
      <Routes>
        <Route path="/" element={<Navigate to="/consulta" replace />} />
        <Route path="/consulta" element={<ConsultaPage />} />
        <Route path="/detalhe" element={<DetalhePage />} />
        <Route path="/lancamento" element={<LancamentoPage />} />
        <Route path="/acerto" element={<AcertoPage />} />
        <Route path="*" element={<Navigate to="/consulta" replace />} />
      </Routes>
    </div>
  );
}
