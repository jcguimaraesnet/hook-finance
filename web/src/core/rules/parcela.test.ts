import { describe, expect, it } from "vitest";
import { parcelaTotal, isParcelado } from "./parcela";

describe("parcelaTotal", () => {
  it("retorna 1 para vazio/null", () => {
    expect(parcelaTotal("")).toBe(1);
    expect(parcelaTotal(null)).toBe(1);
    expect(parcelaTotal(undefined)).toBe(1);
  });

  it("extrai N de '1/N'", () => {
    expect(parcelaTotal("1/3")).toBe(3);
    expect(parcelaTotal("1/12")).toBe(12);
  });

  it("formato legado (número solo) também funciona", () => {
    expect(parcelaTotal("3")).toBe(3);
    expect(parcelaTotal("12")).toBe(12);
  });

  it("formato inválido cai em 1 (defensivo)", () => {
    expect(parcelaTotal("3/")).toBe(1);
    expect(parcelaTotal("3/0")).toBe(1);
    expect(parcelaTotal("abc")).toBe(1);
  });
});

describe("isParcelado", () => {
  it("vazio/null/undefined => false", () => {
    expect(isParcelado("")).toBe(false);
    expect(isParcelado(null)).toBe(false);
    expect(isParcelado(undefined)).toBe(false);
    expect(isParcelado("   ")).toBe(false);
  });

  it("string com conteúdo => true", () => {
    expect(isParcelado("1/3")).toBe(true);
    expect(isParcelado("3")).toBe(true);
  });
});
