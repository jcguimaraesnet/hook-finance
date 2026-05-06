import type { ReactNode } from "react";

interface CardProps {
  children: ReactNode;
  className?: string;
}

export function Card({ children, className = "" }: CardProps) {
  return (
    <div className={`bg-white border border-[--color-border] rounded-lg p-3 ${className}`}>
      {children}
    </div>
  );
}

interface CardHeaderProps {
  title: string;
  onTitleClick?: () => void;
  right?: ReactNode;
}

export function CardHeader({ title, onTitleClick, right }: CardHeaderProps) {
  return (
    <h3 className="relative bg-[--color-accent] text-[--color-accent-fg] text-center text-[0.82rem] font-semibold py-1.5 px-2 rounded-md -mx-1 -mt-1 mb-2.5 flex items-center justify-center">
      {onTitleClick ? (
        <span className="cursor-pointer select-none" onClick={onTitleClick}>
          {title}
        </span>
      ) : (
        <span>{title}</span>
      )}
      {right && (
        <span className="absolute right-1 top-1/2 -translate-y-1/2">{right}</span>
      )}
    </h3>
  );
}
