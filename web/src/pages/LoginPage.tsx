import { useState } from "react";
import { useAppStore } from "@/store/useAppStore";

export function LoginPage() {
  const setToken = useAppStore((s) => s.setToken);
  const [value, setValue] = useState("");
  const [error, setError] = useState<string | null>(null);

  function handleSubmit(e?: React.FormEvent) {
    e?.preventDefault();
    const v = value.trim();
    if (!v) {
      setError("Token vazio.");
      return;
    }
    setToken(v);
  }

  return (
    <div className="grid place-items-center min-h-[70dvh]">
      <form
        onSubmit={handleSubmit}
        className="bg-white border border-[--color-border] rounded-xl p-6 grid gap-3 w-full max-w-[360px]"
      >
        <h2 className="text-lg font-semibold text-[--color-fg] m-0">hook-finance</h2>
        <label htmlFor="token" className="text-sm text-[--color-muted]">
          Token
        </label>
        <input
          id="token"
          type="password"
          autoComplete="off"
          value={value}
          onChange={(e) => setValue(e.target.value)}
          className="border border-[--color-border] rounded-md px-3 py-2 text-base bg-white text-[--color-fg]"
        />
        <button
          type="submit"
          className="bg-[--color-fg] text-white rounded-md px-3 py-2 text-base font-semibold hover:opacity-90"
        >
          Entrar
        </button>
        {error && (
          <p className="text-[--color-negative] text-sm m-0">{error}</p>
        )}
      </form>
    </div>
  );
}
