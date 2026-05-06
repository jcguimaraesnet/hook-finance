// Despesas fixas inseridas automaticamente na primeira compra de cada fatura nova.
// `refDay` = dia do mês (1-31). Mês e ano são preenchidos com o mês/ano da
// data de fechamento da fatura no momento da inserção.
const FIXED_EXPENSES = [
  { refDay: 6, description: "Diarista", value: 1500, origem: "Pix (contas)", categoria: "Contas", rateio: "Dani" },
  { refDay: 6, description: "Plano de Saúde (Dani)", value: 761.81, origem: "Pix (contas)", categoria: "Contas", rateio: "Dani" },
  { refDay: 6, description: "Plano de Saúde (Julio)", value: 761.81, origem: "Pix (contas)", categoria: "Contas", rateio: "Julio", acerto: "Sim" },
  { refDay: 7, description: "Mensalidade creche 1/2", value: 1741.40, origem: "Pix (contas)", categoria: "Contas", rateio: "Dani", acerto: "Sim" },
  { refDay: 7, description: "Mensalidade creche 2/2", value: 1741.40, origem: "Pix (contas)", categoria: "Contas", rateio: "Julio", acerto: "Sim" },
  { refDay: 5, description: "Ajuda de custo (Creche)", value: -620, origem: "Pix (contas)", categoria: "Contas", rateio: "Dani" },
  { refDay: 6, description: "Claro Internet - https://minhaclaroresidencial.claro.com.br", value: 0.01, origem: "Pix (contas)", categoria: "Contas", rateio: "Dani" },
  { refDay: 5, description: "Gás", value: 120.42, origem: "Pix (contas)", categoria: "Contas", rateio: "Dani", acerto: "Sim" },
  { refDay: 10, description: "Condomínio 1/2", value: 1550, origem: "Pix (contas)", categoria: "Contas", rateio: "Julio", acerto: "Sim" },
  { refDay: 10, description: "Condomínio 1/2", value: 0, origem: "Pix (contas)", categoria: "Contas", rateio: "Dani" },
  { refDay: 7, description: "Energia (débito automático)", value: 500, origem: "Pix (contas)", categoria: "Contas", rateio: "Dani" },
  { refDay: 15, description: "Guia de Previdência Social", value: 1300, origem: "Pix (contas)", categoria: "Contas", rateio: "Julio" },
  { refDay: 15, description: "Guia de Previdência Social (coloquei pra Dani pra equilibrar)", value: 1300, origem: "Pix (contas)", categoria: "Contas", rateio: "Dani" },
  { refDay: 5, description: "Dízimo", value: 500, origem: "Pix (contas)", categoria: "Contas", rateio: "Julio" },
  { refDay: 5, description: "Dízimo", value: 500, origem: "Pix (contas)", categoria: "Contas", rateio: "Dani" },
];

function appendMonthlyFixedIfNeeded_(sheet, invoiceClosing) {
  const lastRow = sheet.getLastRow();
  if (lastRow > 1) {
    const rows = sheet.getRange(2, 1, lastRow - 1, 5).getValues();
    const exists = rows.some(
      (r) =>
        formatBrDate_(r[0]) === invoiceClosing && String(r[4]).trim() === ORIGEM,
    );
    if (exists) return;
  }
  const [, mm, yyyy] = invoiceClosing.split("/");
  const fixedRows = FIXED_EXPENSES.map((e) => {
    const dd = ("0" + e.refDay).slice(-2);
    return [
      invoiceClosing,
      dd + "/" + mm + "/" + yyyy,
      e.description,
      e.value,
      e.origem,
      e.categoria,
      e.rateio,
      "", // Final do cartão (n/a para Pix)
      e.parcela || "", // Parcela (vazio = à vista; "1/N" se parcelado)
      e.acerto || "",
    ];
  });
  const blank = ["", "", "", "", "", "", "", "", "", ""];
  // Visual top-down dentro do bloco inserido:
  // [blank, ...fixed, blank, blue blank, blank]
  const block = [blank].concat(fixedRows).concat([blank, blank, blank]);
  sheet.insertRowsBefore(2, block.length);
  sheet.getRange(2, 1, block.length, 10).setValues(block);
  // Linha azul = penúltima do bloco. Inserido a partir da linha 2,
  // então fica na linha (2 + block.length - 2) = block.length.
  sheet.getRange(block.length, 1, 1, 10).setBackground("#cfe2f3");
}
