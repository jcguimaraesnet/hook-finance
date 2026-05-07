import { describe, expect, it } from "vitest";
import { parseBrDate, monthYearLabel, brDateToMMYYYY } from "./dates";

describe("parseBrDate", () => {
  it("parseia DD/MM/YYYY", () => {
    const d = parseBrDate("06/05/2026");
    expect(d.getFullYear()).toBe(2026);
    expect(d.getMonth()).toBe(4); // 0-indexed
    expect(d.getDate()).toBe(6);
  });

  it("retorna Date(0) para formato inválido", () => {
    expect(parseBrDate("").getTime()).toBe(new Date(0).getTime());
    expect(parseBrDate("2026-05-06").getTime()).toBe(new Date(0).getTime());
  });
});

describe("monthYearLabel", () => {
  it("converte para nome do mês em pt-BR", () => {
    expect(monthYearLabel("06/05/2026")).toBe("maio de 2026");
    expect(monthYearLabel("01/01/2026")).toBe("janeiro de 2026");
    expect(monthYearLabel("31/12/2026")).toBe("dezembro de 2026");
  });

  it("vazio retorna ''", () => {
    expect(monthYearLabel("")).toBe("");
    expect(monthYearLabel(null)).toBe("");
    expect(monthYearLabel(undefined)).toBe("");
  });
});

describe("brDateToMMYYYY", () => {
  it("extrai MM/YYYY de DD/MM/YYYY", () => {
    expect(brDateToMMYYYY("06/05/2026")).toBe("05/2026");
    expect(brDateToMMYYYY("31/12/2025")).toBe("12/2025");
  });

  it("formato inválido retorna a string original", () => {
    expect(brDateToMMYYYY("")).toBe("");
    expect(brDateToMMYYYY("abc")).toBe("abc");
  });
});
