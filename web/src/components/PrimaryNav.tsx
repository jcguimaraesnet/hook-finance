import { NavLink } from "react-router-dom";

const ITEMS = [
  { to: "/consulta", label: "Consulta", icon: "📊" },
  { to: "/detalhe", label: "Detalhe", icon: "📋" },
  { to: "/lancamento", label: "Lançamento", icon: "➕" },
  { to: "/acerto", label: "Acerto", icon: "🤝" },
] as const;

export function PrimaryNav() {
  return (
    <nav
      className="
        fixed bottom-0 inset-x-0 grid grid-cols-4 bg-[#262626] z-50 border-t border-[#3a3a3a] gap-1 p-1
        tablet:static tablet:rounded-lg tablet:border-t-0 tablet:mb-3
      "
      style={{ paddingBottom: "max(0.25rem, env(safe-area-inset-bottom))" }}
      aria-label="Páginas principais"
    >
      {ITEMS.map((it) => (
        <NavLink
          key={it.to}
          to={it.to}
          className={({ isActive }) =>
            [
              "px-1 py-2 text-center text-[0.7rem] font-semibold tablet:text-[0.85rem] tablet:px-2 tablet:py-3 rounded-md transition truncate",
              isActive
                ? "bg-accent text-accent-fg"
                : "text-white",
            ].join(" ")
          }
        >
          {it.icon} {it.label}
        </NavLink>
      ))}
    </nav>
  );
}
