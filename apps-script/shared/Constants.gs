const SHEET_ID = "1IbxnOnBuhLIj5i8nqepk-Bva1IhmKalyuLXIyN56V8k";
const SHEET_NAME = "Despesas";
const FIXED_SHEET_NAME = "despesas-fixas";

const INVOICE_CLOSING_DAY = 6;
const ORIGEM = "Cartão";

// Map dos 4 finais de cartão para o titular.
// Chave = últimos 4 dígitos. Valor = nome (Julio | Dani).
const CARDS = {
  "1018": "Julio",
  "9727": "Julio",
  "2236": "Julio",
  "4750": "Dani",
  "0784": "Dani",
};
