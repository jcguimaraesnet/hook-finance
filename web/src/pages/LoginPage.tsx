import { useState } from "react";
import { useAppStore } from "@/store/useAppStore";
import { validateToken } from "@/api/client";

export function LoginPage() {
  const signIn = useAppStore((s) => s.signIn);
  const [value, setValue] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  // Mostra mensagem de sessão expirada quando vem da SessionExpiryGuard.
  const expired =
    typeof window !== "undefined" &&
    new URLSearchParams(window.location.search).has("expired");

  async function handleSubmit(e?: React.FormEvent) {
    e?.preventDefault();
    const v = value.trim();
    if (!v) {
      setError("Token vazio.");
      return;
    }
    setError(null);
    setSubmitting(true);
    const valid = await validateToken(v);
    setSubmitting(false);
    if (!valid) {
      setError("Token inválido.");
      return;
    }
    signIn(v);
    // Limpa querystring ?expired=1 ao entrar com sucesso.
    if (expired) {
      window.history.replaceState({}, "", window.location.pathname);
    }
  }

  return (
    <div className="grid place-items-center min-h-[70dvh]">
      <form
        onSubmit={handleSubmit}
        className="bg-white border border-border rounded-xl p-6 grid gap-3 w-full max-w-[360px]"
      >
        <h2 className="text-lg font-semibold text-fg m-0">hook-finance</h2>
        {expired && !error && (
          <p className="text-muted text-sm m-0">
            Sessão expirada após 15 minutos. Entre novamente.
          </p>
        )}
        <label htmlFor="token" className="text-sm text-muted">
          Token
        </label>
        <input
          id="token"
          type="password"
          autoComplete="off"
          value={value}
          onChange={(e) => setValue(e.target.value)}
          disabled={submitting}
          className="border border-border rounded-md px-3 py-2 text-base bg-white text-fg disabled:opacity-60"
        />
        <button
          type="submit"
          disabled={submitting}
          className="bg-fg text-white rounded-md px-3 py-2 text-base font-semibold hover:opacity-90 disabled:opacity-60"
        >
          {submitting ? "Validando..." : "Entrar"}
        </button>
        {error && (
          <p className="text-negative text-sm m-0">{error}</p>
        )}
      </form>
    </div>
  );
}
