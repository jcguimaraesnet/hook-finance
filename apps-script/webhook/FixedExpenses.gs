// Despesas fixas são lidas da aba `despesas-fixas` no momento da inserção.
// Spec: docs/specs/rules/fixed-expenses.md
// Schema da aba: docs/specs/data/despesas-fixas-sheet.md

function loadFixedExpenses_() {
  const ss = SpreadsheetApp.openById(SHEET_ID);
  const sheet = ss.getSheetByName(FIXED_SHEET_NAME);
  if (!sheet) throw new Error(`aba "${FIXED_SHEET_NAME}" não existe`);

  const last = sheet.getLastRow();
  if (last < 2) throw new Error(`aba "${FIXED_SHEET_NAME}" está vazia`);

  const rows = sheet.getRange(2, 1, last - 1, 7).getValues();
  return rows.map((r, i) => {
    const line = i + 2;
    const [dia, descricao, valor, origem, categoria, rateio, acerto] = r;

    if (!Number.isInteger(dia) || dia < 1 || dia > 31)
      throw new Error(`despesas-fixas L${line}: dia inválido (${dia})`);
    if (!descricao || typeof descricao !== "string")
      throw new Error(`despesas-fixas L${line}: descrição vazia`);
    if (typeof valor !== "number" || isNaN(valor))
      throw new Error(`despesas-fixas L${line}: valor inválido (${valor})`);
    if (!origem) throw new Error(`despesas-fixas L${line}: origem vazia`);
    if (!categoria) throw new Error(`despesas-fixas L${line}: categoria vazia`);
    if (!["Julio", "Dani", "Metade", "Alzira"].includes(String(rateio)))
      throw new Error(`despesas-fixas L${line}: rateio inválido (${rateio})`);
    const acertoStr = String(acerto || "");
    if (acertoStr !== "" && acertoStr !== "Sim")
      throw new Error(`despesas-fixas L${line}: acerto inválido (${acertoStr})`);

    return {
      refDay: dia,
      description: descricao,
      value: valor,
      origem,
      categoria,
      rateio: String(rateio),
      acerto: acertoStr,
    };
  });
}

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
  const fixed = loadFixedExpenses_();
  const [, mm, yyyy] = invoiceClosing.split("/");
  const fixedRows = fixed.map((e) => {
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
      "", // Parcela (despesas fixas nunca são parceladas)
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

// One-shot — rodar manualmente no editor do Apps Script para popular a aba
// `despesas-fixas` com a lista atual. Idempotente: aborta se a aba já tem dados.
function seedFixedExpenses_() {
  const ss = SpreadsheetApp.openById(SHEET_ID);
  const sheet = ss.getSheetByName(FIXED_SHEET_NAME);
  if (!sheet) throw new Error(`crie a aba "${FIXED_SHEET_NAME}" primeiro`);
  if (sheet.getLastRow() > 1)
    throw new Error("aba já tem dados — abortando para não duplicar");

  const headers = ["Dia", "Descrição", "Valor", "Origem", "Categoria", "Rateio", "Acerto"];
  const data = [
    [6,  "Diarista",                                                       1500,    "Pix (contas)", "Contas", "Dani",  ""   ],
    [6,  "Plano de Saúde (Dani)",                                          761.81,  "Pix (contas)", "Contas", "Dani",  ""   ],
    [6,  "Plano de Saúde (Julio)",                                         761.81,  "Pix (contas)", "Contas", "Julio", "Sim"],
    [7,  "Mensalidade creche 1/2",                                         1741.40, "Pix (contas)", "Contas", "Dani",  "Sim"],
    [7,  "Mensalidade creche 2/2",                                         1741.40, "Pix (contas)", "Contas", "Julio", "Sim"],
    [5,  "Ajuda de custo (Creche)",                                        -620,    "Pix (contas)", "Contas", "Dani",  ""   ],
    [6,  "Claro Internet - https://minhaclaroresidencial.claro.com.br",    0.01,    "Pix (contas)", "Contas", "Dani",  ""   ],
    [5,  "Gás",                                                            120.42,  "Pix (contas)", "Contas", "Dani",  "Sim"],
    [10, "Condomínio 1/2",                                                 1550,    "Pix (contas)", "Contas", "Julio", "Sim"],
    [10, "Condomínio 1/2",                                                 0,       "Pix (contas)", "Contas", "Dani",  ""   ],
    [7,  "Energia (débito automático)",                                    500,     "Pix (contas)", "Contas", "Dani",  ""   ],
    [15, "Guia de Previdência Social",                                     1300,    "Pix (contas)", "Contas", "Julio", ""   ],
    [15, "Guia de Previdência Social (coloquei pra Dani pra equilibrar)",  1300,    "Pix (contas)", "Contas", "Dani",  ""   ],
    [5,  "Dízimo",                                                         500,     "Pix (contas)", "Contas", "Julio", ""   ],
    [5,  "Dízimo",                                                         500,     "Pix (contas)", "Contas", "Dani",  ""   ],
  ];

  sheet.getRange(1, 1, 1, headers.length).setValues([headers]).setFontWeight("bold");
  sheet.getRange(2, 1, data.length, headers.length).setValues(data);
}
