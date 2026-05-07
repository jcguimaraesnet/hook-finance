import { describe, expect, it } from "vitest";
import { moneyK, formatMoney } from "./money";

describe("formatMoney", () => {
  it("formata número pt-BR com 2 casas", () => {
    // Note: Intl pode usar U+00A0 (NBSP) ou espaço comum dependendo do runtime;
    // testamos por padrão via match para tolerar.
    expect(formatMoney(1234.5)).toMatch(/^1\.234,50$/);
    expect(formatMoney(0)).toBe("0,00");
  });
});

describe("moneyK", () => {
  it("< 1000 formata locale", () => {
    expect(moneyK(500)).toBe("500");
    expect(moneyK(0)).toBe("0");
    expect(moneyK(999)).toBe("999");
  });

  it(">= 1000 abrevia em k", () => {
    expect(moneyK(1000)).toBe("1k");
    expect(moneyK(1500)).toBe("1,5k");
    expect(moneyK(20000)).toBe("20k");
    expect(moneyK(1234)).toBe("1,2k");
  });

  it("NaN/null retorna ''", () => {
    expect(moneyK(NaN)).toBe("");
    // @ts-expect-error testando o defensive check
    expect(moneyK(null)).toBe("");
  });

  it("preserva sinal negativo", () => {
    expect(moneyK(-1500)).toBe("-1,5k");
  });
});
