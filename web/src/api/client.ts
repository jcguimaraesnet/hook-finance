import { useAppStore } from "@/store/useAppStore";

// Em dev: Vite proxy redireciona /api -> localhost:7071 (Azure Functions Core Tools)
// Em prod: Azure SWA serve /api/* direto da Function deployada na mesma origem.
const BASE = "/api/proxy";

function getToken(): string {
  return useAppStore.getState().token || "";
}

export async function apiGet<T>(
  action: string,
  params: Record<string, string | number | null | undefined> = {},
): Promise<T> {
  const url = new URL(BASE, window.location.origin);
  url.searchParams.set("action", action);
  url.searchParams.set("token", getToken());
  for (const [k, v] of Object.entries(params)) {
    if (v != null) url.searchParams.set(k, String(v));
  }
  const r = await fetch(url.toString(), { method: "GET" });
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return (await r.json()) as T;
}

export async function apiPost<T>(action: string, body: object): Promise<T> {
  // text/plain evita preflight CORS no Apps Script direto (defesa em profundidade,
  // mesmo passando pelo proxy).
  const r = await fetch(BASE, {
    method: "POST",
    headers: { "Content-Type": "text/plain" },
    body: JSON.stringify({ action, token: getToken(), ...body }),
  });
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return (await r.json()) as T;
}
