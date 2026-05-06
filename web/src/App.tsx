import { Routes, Route, Navigate } from "react-router-dom";

export default function App() {
  return (
    <main className="min-h-dvh max-w-[880px] mx-auto p-3">
      <Routes>
        <Route path="/" element={<Placeholder title="hook-finance" />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </main>
  );
}

function Placeholder({ title }: { title: string }) {
  return (
    <div className="grid place-items-center min-h-[60dvh] gap-3 text-center">
      <h1 className="text-2xl font-semibold text-[--color-fg]">{title}</h1>
      <p className="text-sm text-[--color-muted]">
        Esqueleto inicial — Phase B do plano. Próxima etapa: API client + páginas.
      </p>
    </div>
  );
}
