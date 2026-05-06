interface Props {
  title: string;
  note?: string;
}

export function PlaceholderPage({ title, note }: Props) {
  return (
    <div className="bg-white border border-[--color-border] rounded-lg p-4 text-center">
      <h2 className="text-base font-semibold text-[--color-fg] m-0">{title}</h2>
      {note && <p className="text-sm text-[--color-muted] mt-2">{note}</p>}
    </div>
  );
}
