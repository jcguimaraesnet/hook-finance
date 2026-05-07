import { useEffect, useRef, useState } from "react";
import { useUpdateEntry, useDeleteEntry } from "@/hooks/useLastEntries";
import type { Entry, Row } from "@/api/types";
import { parcelaTotal } from "@/utils/format";
import { formatMoney } from "@/utils/format";

interface Props {
  entry: Entry | null;
  rowsForCategoriaSuggestions: Row[];
  onClose: () => void;
}

export function EditModal({ entry, rowsForCategoriaSuggestions, onClose }: Props) {
  const update = useUpdateEntry();
  const del = useDeleteEntry();

  const [descricao, setDescricao] = useState("");
  const [valor, setValor] = useState(0);
  const [categoria, setCategoria] = useState("");
  const [rateio, setRateio] = useState("");
  const [parcela, setParcela] = useState(1);
  const originalTotalRef = useRef(0);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!entry) return;
    const initialTotal = parcelaTotal(entry.parcela);
    originalTotalRef.current = (entry.valor || 0) * initialTotal;
    setDescricao(entry.descricao);
    setValor(Number(entry.valor) || 0);
    setCategoria(entry.categoria);
    setRateio(entry.rateio);
    setParcela(initialTotal);
    setError(null);
  }, [entry]);

  if (!entry) return null;

  function adjustParcela(delta: number) {
    const next = Math.max(1, Math.min(99, parcela + delta));
    setParcela(next);
    setValor(originalTotalRef.current / next);
  }

  function handleValorChange(v: number) {
    setValor(v);
    originalTotalRef.current = v * parcela;
  }

  async function handleSave(e?: React.FormEvent) {
    e?.preventDefault();
    setError(null);
    try {
      const fields = {
        descricao: descricao.trim(),
        valor: valor,
        categoria: categoria.trim(),
        rateio,
        parcela: parcela > 1 ? `1/${parcela}` : "",
      };
      const r = await update.mutateAsync({ row: entry!.row, fields });
      if (!r.ok) throw new Error(r.error || "Erro");
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  }

  async function handleDelete() {
    if (!window.confirm("Excluir este lançamento? Esta ação não pode ser desfeita."))
      return;
    setError(null);
    try {
      const r = await del.mutateAsync(entry!.row);
      if (!r.ok) throw new Error(r.error || "Erro");
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  }

  const categoriaOptions = Array.from(
    new Set(rowsForCategoriaSuggestions.map((r) => r.categoria).filter(Boolean)),
  ).sort();

  const inProgress = update.isPending || del.isPending;

  return (
    <div className="bg-white border border-border rounded-lg overflow-hidden">
      <header className="bg-accent text-accent-fg py-2.5 px-4 flex items-center justify-between border-b border-[#d4b54e]">
        <h2 className="text-base font-semibold m-0">Editar lançamento</h2>
        <button
          type="button"
          onClick={onClose}
          aria-label="Fechar"
          className="text-lg leading-none p-1.5 rounded hover:bg-black/10"
        >
          ✕
        </button>
      </header>

      <form
        onSubmit={handleSave}
        className="p-4 flex flex-col gap-3.5 max-w-[720px] w-full mx-auto"
      >
        <ReadOnlyField label="Data de referência" value={entry.dataRef || "—"} />
        <ReadOnlyField label="Origem" value={entry.origem || "—"} />

        <Field label="Descrição">
          <input
            type="text"
            value={descricao}
            onChange={(e) => setDescricao(e.target.value)}
            autoComplete="off"
            className="w-full text-base px-3 py-2.5 border border-border rounded-md bg-white text-fg"
          />
        </Field>

        <Field label="Valor (R$)">
          <input
            type="number"
            step="0.01"
            inputMode="decimal"
            value={valor}
            onChange={(e) => handleValorChange(parseFloat(e.target.value) || 0)}
            className="w-full text-base px-3 py-2.5 border border-border rounded-md bg-white text-fg"
          />
        </Field>

        <Field label="Categoria">
          <input
            type="text"
            list="categoria-options"
            value={categoria}
            onChange={(e) => setCategoria(e.target.value)}
            autoComplete="off"
            className="w-full text-base px-3 py-2.5 border border-border rounded-md bg-white text-fg"
          />
          <datalist id="categoria-options">
            {categoriaOptions.map((c) => (
              <option key={c} value={c} />
            ))}
          </datalist>
        </Field>

        <Field label="Rateio">
          <select
            value={rateio}
            onChange={(e) => setRateio(e.target.value)}
            className="w-full text-base px-3 py-2.5 border border-border rounded-md bg-white text-fg"
          >
            <option value="">(vazio)</option>
            <option value="Julio">Julio</option>
            <option value="Dani">Dani</option>
            <option value="Metade">Metade (compartilhado)</option>
            <option value="Alzira">Alzira</option>
          </select>
        </Field>

        <Field label="Parcela">
          <div className="flex items-center gap-2 flex-wrap">
            <button
              type="button"
              onClick={() => adjustParcela(-1)}
              aria-label="Diminuir parcela"
              className="bg-fg text-white rounded-md w-10 h-10 text-lg font-bold hover:opacity-85"
            >
              −
            </button>
            <span className="text-lg font-bold tabular-nums min-w-12 text-center">
              {parcela}x
            </span>
            <button
              type="button"
              onClick={() => adjustParcela(1)}
              aria-label="Aumentar parcela"
              className="bg-fg text-white rounded-md w-10 h-10 text-lg font-bold hover:opacity-85"
            >
              +
            </button>
            <span className="text-[0.78rem] text-muted basis-full ml-1">
              Total da compra:{" "}
              <span className="text-fg font-semibold">
                R$ {formatMoney(originalTotalRef.current)}
              </span>
            </span>
          </div>
        </Field>

        {error && (
          <p className="text-negative text-sm m-0">Erro: {error}</p>
        )}

        <div className="grid grid-cols-[auto_1fr_1fr] gap-2 mt-2">
          <button
            type="button"
            onClick={handleDelete}
            disabled={inProgress}
            className="bg-white text-negative border border-negative rounded-md py-2.5 px-3 font-semibold hover:opacity-90 disabled:opacity-60"
          >
            Excluir
          </button>
          <button
            type="button"
            onClick={onClose}
            disabled={inProgress}
            className="bg-white text-fg border border-border rounded-md py-2.5 px-3 font-semibold hover:opacity-90 disabled:opacity-60"
          >
            Cancelar
          </button>
          <button
            type="submit"
            disabled={inProgress}
            className="bg-fg text-white border border-fg rounded-md py-2.5 px-3 font-semibold hover:opacity-90 disabled:opacity-60"
          >
            {update.isPending ? "Salvando..." : "Salvar"}
          </button>
        </div>
      </form>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-1.5">
      <label className="text-[0.75rem] uppercase tracking-wide font-semibold text-muted">
        {label}
      </label>
      {children}
    </div>
  );
}

function ReadOnlyField({ label, value }: { label: string; value: string }) {
  return (
    <Field label={label}>
      <div className="bg-[#f0ece2] border border-border rounded-md px-3 py-2.5 text-sm">
        {value}
      </div>
    </Field>
  );
}
