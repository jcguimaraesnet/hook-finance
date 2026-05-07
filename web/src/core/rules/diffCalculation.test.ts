import { describe, expect, it } from "vitest";
import { diffCalculation } from "./diffCalculation";
import type { Row } from "../types";

function row(overrides: Partial<Row>): Row {
  return {
    data: "06/05/2026",
    dataRef: "03/04/2026 14:32",
    descricao: "TEST",
    valor: 0,
    origem: "Cartão",
    categoria: "",
    rateio: "",
    cardLast4: "",
    parcela: "",
    acerto: "",
    ...overrides,
  };
}

describe("diffCalculation", () => {
  describe("quando o mês tem Pix", () => {
    it("considera todas as Pix do mês (não filtra por acerto)", () => {
      const rows: Row[] = [
        row({ origem: "Pix (contas)", rateio: "Julio", valor: 1000, acerto: "Sim" }),
        row({ origem: "Pix (contas)", rateio: "Dani", valor: 700, acerto: "" }),
      ];
      // Julio: meu=1000, outro=700 => diff = 300
      expect(diffCalculation(rows, "Julio")).toBe(300);
      // Dani: meu=700, outro=1000 => diff = -300
      expect(diffCalculation(rows, "Dani")).toBe(-300);
    });

    it("ignora linhas Cartão e Contas/Empregados quando há Pix", () => {
      const rows: Row[] = [
        row({ origem: "Pix (contas)", rateio: "Julio", valor: 500 }),
        row({ origem: "Cartão", rateio: "Metade", valor: 200 }),
        row({ origem: "Contas", rateio: "Dani", valor: 100 }),
      ];
      expect(diffCalculation(rows, "Julio")).toBe(500);
      expect(diffCalculation(rows, "Dani")).toBe(-500);
    });

    it("aplica splitForPerson em Pix com rateio Metade", () => {
      const rows: Row[] = [
        row({ origem: "Pix (contas)", rateio: "Metade", valor: 200 }),
      ];
      // Metade => meu=100, outro=100 => diff = 0
      expect(diffCalculation(rows, "Julio")).toBe(0);
    });
  });

  describe("quando o mês NÃO tem Pix", () => {
    it("considera Contas + Empregados", () => {
      const rows: Row[] = [
        row({ origem: "Contas", rateio: "Julio", valor: 300 }),
        row({ origem: "Empregados", rateio: "Dani", valor: 150 }),
      ];
      // Julio: meu=300, outro=150 => diff = 150
      expect(diffCalculation(rows, "Julio")).toBe(150);
      expect(diffCalculation(rows, "Dani")).toBe(-150);
    });

    it("ignora Cartão e outras origens", () => {
      const rows: Row[] = [
        row({ origem: "Cartão", rateio: "Julio", valor: 1000 }),
        row({ origem: "Pessoal", rateio: "Julio", valor: 500 }),
        row({ origem: "Contas", rateio: "Julio", valor: 100 }),
      ];
      expect(diffCalculation(rows, "Julio")).toBe(100);
    });
  });

  it("mês completamente vazio retorna 0", () => {
    expect(diffCalculation([], "Julio")).toBe(0);
    expect(diffCalculation([], "Dani")).toBe(0);
  });

  it("preserva sinal do valor (negativos)", () => {
    const rows: Row[] = [
      row({ origem: "Pix (contas)", rateio: "Julio", valor: -100 }),
    ];
    expect(diffCalculation(rows, "Julio")).toBe(-100);
    expect(diffCalculation(rows, "Dani")).toBe(100);
  });
});
