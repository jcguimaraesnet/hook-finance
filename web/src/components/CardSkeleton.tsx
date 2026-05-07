import { Card, CardHeader } from "./Card";

interface Props {
  title: string;
  rows?: number;
  variant?: "table" | "chart";
}

export function CardSkeleton({ title, rows = 4, variant = "table" }: Props) {
  return (
    <Card>
      <CardHeader title={title} />
      {variant === "chart" ? (
        <div className="skeleton h-[280px] tablet:h-[280px] pc:h-[300px] rounded-md" />
      ) : (
        <div className="flex flex-col gap-2 py-1">
          {Array.from({ length: rows }).map((_, i) => (
            <div key={i} className="skeleton h-4" />
          ))}
        </div>
      )}
    </Card>
  );
}
