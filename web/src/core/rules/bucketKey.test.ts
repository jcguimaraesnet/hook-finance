import { describe, expect, it } from "vitest";
import { bucketKey } from "./bucketKey";
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

describe("bucketKey", () => {
  it("Cartão + Metade => Cartão (compartilhado)", () => {
    expect(bucketKey(row({ origem: "Cartão", rateio: "Metade" }))).toBe(
      "Cartão (compartilhado)",
    );
  });

  it("Cartão + Julio/Dani/Alzira => Cartão (pessoal)", () => {
    expect(bucketKey(row({ origem: "Cartão", rateio: "Julio" }))).toBe(
      "Cartão (pessoal)",
    );
    expect(bucketKey(row({ origem: "Cartão", rateio: "Dani" }))).toBe(
      "Cartão (pessoal)",
    );
    expect(bucketKey(row({ origem: "Cartão", rateio: "Alzira" }))).toBe(
      "Cartão (pessoal)",
    );
  });

  it("Cartão + rateio vazio => Cartão (pessoal)", () => {
    expect(bucketKey(row({ origem: "Cartão", rateio: "" }))).toBe(
      "Cartão (pessoal)",
    );
  });

  it("Outras origens passam literal", () => {
    expect(bucketKey(row({ origem: "Pix (contas)", rateio: "Julio" }))).toBe(
      "Pix (contas)",
    );
    expect(bucketKey(row({ origem: "Pessoal", rateio: "" }))).toBe("Pessoal");
    expect(bucketKey(row({ origem: "Empregados", rateio: "Metade" }))).toBe(
      "Empregados",
    );
    expect(bucketKey(row({ origem: "Contas", rateio: "" }))).toBe("Contas");
  });

  it("origem vazia retorna vazia", () => {
    expect(bucketKey(row({ origem: "", rateio: "Metade" }))).toBe("");
  });
});
