interface Props {
  className?: string;
  height?: string;
  width?: string;
}

export function Skeleton({ className = "", height, width }: Props) {
  return (
    <span
      className={`skeleton block ${className}`}
      style={{ height: height ?? "0.95rem", width: width ?? "100%" }}
    />
  );
}
