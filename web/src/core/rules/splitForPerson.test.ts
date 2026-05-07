import { describe, expect, it } from "vitest";
import { splitForPerson } from "./splitForPerson";
import type { Row } from "../types";

function row(overrides: Partial<Row>): Row {
  return {
    data: "06/05/2026",
    dataRef: "03/04/2026 14:32",
    descricao: "TEST",
    valor: 100,
    origem: "Cartão",
    categoria: "",
    rateio: "",
    cardLast4: "",
    parcela: "",
    acerto: "",
    ...overrides,
  };
}

describe("splitForPerson", () => {
  it("retorna valor cheio quando rateio === person", () => {
    expect(splitForPerson(row({ valor: 80, rateio: "Julio" }), "Julio")).toBe(80);
    expect(splitForPerson(row({ valor: 50, rateio: "Dani" }), "Dani")).toBe(50);
  });

  it("retorna valor/2 quando rateio === 'Metade' (Julio/Dani)", () => {
    expect(splitForPerson(row({ valor: 100, rateio: "Metade" }), "Julio")).toBe(50);
    expect(splitForPerson(row({ valor: 100, rateio: "Metade" }), "Dani")).toBe(50);
  });

  it("retorna 0 quando rateio é de outra pessoa", () => {
    expect(splitForPerson(row({ valor: 80, rateio: "Dani" }), "Julio")).toBe(0);
    expect(splitForPerson(row({ valor: 80, rateio: "Julio" }), "Dani")).toBe(0);
    expect(splitForPerson(row({ valor: 80, rateio: "Alzira" }), "Julio")).toBe(0);
  });

  it("retorna 0 quando rateio é vazio", () => {
    expect(splitForPerson(row({ valor: 80, rateio: "" }), "Julio")).toBe(0);
  });

  it("preserva sinal do valor (negativo => negativo)", () => {
    expect(splitForPerson(row({ valor: -100, rateio: "Julio" }), "Julio")).toBe(-100);
    expect(splitForPerson(row({ valor: -100, rateio: "Metade" }), "Dani")).toBe(-50);
  });

  it("retorna 0 para valor zero independente do rateio", () => {
    expect(splitForPerson(row({ valor: 0, rateio: "Julio" }), "Julio")).toBe(0);
    expect(splitForPerson(row({ valor: 0, rateio: "Metade" }), "Julio")).toBe(0);
  });
});
