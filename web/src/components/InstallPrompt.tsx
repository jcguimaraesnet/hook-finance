import { useEffect, useState } from "react";

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: "accepted" | "dismissed" }>;
}

const DISMISS_KEY = "hook-finance-install-dismissed";

export function InstallPrompt() {
  const [deferred, setDeferred] = useState<BeforeInstallPromptEvent | null>(null);

  useEffect(() => {
    if (localStorage.getItem(DISMISS_KEY) === "1") return;
    function handler(e: Event) {
      e.preventDefault();
      setDeferred(e as BeforeInstallPromptEvent);
    }
    window.addEventListener("beforeinstallprompt", handler);
    return () => window.removeEventListener("beforeinstallprompt", handler);
  }, []);

  if (!deferred) return null;

  async function handleInstall() {
    if (!deferred) return;
    await deferred.prompt();
    const choice = await deferred.userChoice;
    if (choice.outcome === "accepted") setDeferred(null);
  }

  function handleDismiss() {
    localStorage.setItem(DISMISS_KEY, "1");
    setDeferred(null);
  }

  return (
    <div className="fixed bottom-20 left-3 right-3 z-40 tablet:bottom-4 tablet:left-auto tablet:right-4 tablet:max-w-sm bg-[--color-fg] text-white rounded-lg shadow-lg p-3 flex items-center gap-3">
      <div className="flex-1 text-sm">
        <p className="font-semibold m-0">Instalar app</p>
        <p className="text-white/70 text-xs m-0 mt-0.5">
          Acesso rápido e modo standalone
        </p>
      </div>
      <button
        type="button"
        onClick={handleDismiss}
        className="text-white/60 hover:text-white px-2 py-1 text-sm"
      >
        Agora não
      </button>
      <button
        type="button"
        onClick={handleInstall}
        className="bg-[--color-accent] text-[--color-accent-fg] font-semibold px-3 py-1.5 rounded-md text-sm"
      >
        Instalar
      </button>
    </div>
  );
}
