function doGet(e) {
  if (e && e.parameter && e.parameter.action === "data") {
    return jsonResponse_(readAllForApi_(e.parameter.token));
  }
  return HtmlService.createTemplateFromFile("dashboard/Index")
    .evaluate()
    .setTitle("hook-finance")
    .addMetaTag("viewport", "width=device-width, initial-scale=1")
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

function getMonthData(token, month) {
  const auth = checkToken_(token);
  if (auth) return auth;
  const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
  if (!sheet) return { ok: false, error: "sheet_not_found" };
  const last = sheet.getLastRow();
  if (last < 2) return { ok: true, month: null, rows: [] };

  const tz = Session.getScriptTimeZone();
  const fmtCache = {};
  const fmt = function (v) {
    if (v instanceof Date) {
      const t = v.getTime();
      if (fmtCache[t]) return fmtCache[t];
      const s = Utilities.formatDate(v, tz, "dd/MM/yyyy");
      fmtCache[t] = s;
      return s;
    }
    return String(v || "").trim();
  };

  const dataCol = sheet
    .getRange(2, 1, last - 1, 1)
    .getValues()
    .map((r) => fmt(r[0]));

  let targetMonth = month || "";
  if (!targetMonth) {
    let maxKey = -Infinity;
    for (let i = 0; i < dataCol.length; i++) {
      const d = dataCol[i];
      if (!d) continue;
      const key = parseBrDate_(d).getTime();
      if (!isNaN(key) && key > maxKey) {
        maxKey = key;
        targetMonth = d;
      }
    }
  }
  if (!targetMonth) return { ok: true, month: null, rows: [] };

  const matchIndexes = [];
  for (let i = 0; i < dataCol.length; i++) {
    if (dataCol[i] === targetMonth) matchIndexes.push(i + 2);
  }
  if (matchIndexes.length === 0) {
    return { ok: true, month: targetMonth, rows: [] };
  }

  const minRow = matchIndexes[0];
  const maxRow = matchIndexes[matchIndexes.length - 1];
  const slab = sheet.getRange(minRow, 1, maxRow - minRow + 1, 10).getValues();
  const rows = slab
    .filter((r) => fmt(r[0]) === targetMonth)
    .map((r) => ({
      data: fmt(r[0]),
      dataRef: typeof r[1] === "string" ? r[1] : fmt(r[1]),
      descricao: String(r[2] || ""),
      valor: Number(r[3]) || 0,
      origem: String(r[4] || ""),
      categoria: String(r[5] || ""),
      rateio: String(r[6] || ""),
      cardLast4: String(r[7] || ""),
      parcela: String(r[8] || "").trim(),
      acerto: String(r[9] || ""),
    }));

  return { ok: true, month: targetMonth, rows: rows };
}

function getHistoricalSummary(token) {
  const auth = checkToken_(token);
  if (auth) return auth;
  const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
  if (!sheet) return { ok: false, error: "sheet_not_found" };
  const last = sheet.getLastRow();
  if (last < 2) {
    return {
      ok: true,
      months: [],
      history: { months: [], totals: [], julioPessoal: [], daniPessoal: [] },
    };
  }

  const tz = Session.getScriptTimeZone();
  const fmtCache = {};
  const fmt = function (v) {
    if (v instanceof Date) {
      const t = v.getTime();
      if (fmtCache[t]) return fmtCache[t];
      const s = Utilities.formatDate(v, tz, "dd/MM/yyyy");
      fmtCache[t] = s;
      return s;
    }
    return String(v || "").trim();
  };

  // 1) Lê só coluna A para descobrir os 12 meses mais recentes e o range coberto.
  const dataCol = sheet.getRange(2, 1, last - 1, 1).getValues();
  const monthByRow = new Array(dataCol.length);
  const allMonths = {};
  for (let i = 0; i < dataCol.length; i++) {
    const m = fmt(dataCol[i][0]);
    monthByRow[i] = m;
    if (m) allMonths[m] = true;
  }

  const monthsDesc = Object.keys(allMonths).sort(
    (a, b) => parseBrDate_(b) - parseBrDate_(a),
  );
  const last12Desc = monthsDesc.slice(0, 12);
  if (last12Desc.length === 0) {
    return {
      ok: true,
      months: [],
      history: { months: [], totals: [], julioPessoal: [], daniPessoal: [] },
    };
  }
  const last12Set = {};
  for (const m of last12Desc) last12Set[m] = true;

  // 2) Encontra range de linhas que cobre os últimos 12 meses.
  let minIdx = -1;
  let maxIdx = -1;
  for (let i = 0; i < monthByRow.length; i++) {
    if (last12Set[monthByRow[i]]) {
      if (minIdx === -1) minIdx = i;
      maxIdx = i;
    }
  }
  if (minIdx === -1) {
    return {
      ok: true,
      months: [],
      history: { months: [], totals: [], julioPessoal: [], daniPessoal: [] },
    };
  }

  // 3) Lê A..G só do slab necessário.
  const slabStart = minIdx + 2;
  const slabRows = maxIdx - minIdx + 1;
  const values = sheet.getRange(slabStart, 1, slabRows, 7).getValues();

  const byMonth = {};
  for (const m of last12Desc) {
    byMonth[m] = { total: 0, julioPessoal: 0, daniPessoal: 0 };
  }
  for (const r of values) {
    const data = fmt(r[0]);
    if (!data || !last12Set[data]) continue;
    const valor = Number(r[3]) || 0;
    const origem = String(r[4] || "");
    const categoria = String(r[5] || "");
    const rateio = String(r[6] || "");
    if (origem !== "Pessoal") byMonth[data].total += valor;
    if (categoria === "Pessoal") {
      if (rateio === "Julio") byMonth[data].julioPessoal += valor;
      else if (rateio === "Dani") byMonth[data].daniPessoal += valor;
      else if (rateio === "Metade") {
        byMonth[data].julioPessoal += valor / 2;
        byMonth[data].daniPessoal += valor / 2;
      }
    }
  }

  const last12Asc = last12Desc.slice().reverse();

  return {
    ok: true,
    months: last12Desc,
    history: {
      months: last12Asc,
      totals: last12Asc.map((m) => byMonth[m].total),
      julioPessoal: last12Asc.map((m) => byMonth[m].julioPessoal),
      daniPessoal: last12Asc.map((m) => byMonth[m].daniPessoal),
    },
  };
}

function getLastEntries(token, n) {
  const auth = checkToken_(token);
  if (auth) return auth;
  const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
  if (!sheet) return { ok: false, error: "sheet_not_found" };
  const last = sheet.getLastRow();
  if (last < 2) return { ok: true, entries: [] };
  const count = Math.min(n || 10, last - 1);
  const values = sheet.getRange(2, 1, count, 10).getValues();

  const tz = Session.getScriptTimeZone();
  const fmtDate = function (v) {
    if (v instanceof Date) return Utilities.formatDate(v, tz, "dd/MM/yyyy");
    return String(v || "").trim();
  };
  const fmtDateTime = function (v) {
    if (v instanceof Date) return Utilities.formatDate(v, tz, "dd/MM/yyyy HH:mm");
    return String(v || "").trim();
  };

  const entries = values.map((r, i) => ({
    row: i + 2,
    data: fmtDate(r[0]),
    dataRef: fmtDateTime(r[1]),
    descricao: String(r[2] || ""),
    valor: Number(r[3]) || 0,
    origem: String(r[4] || ""),
    categoria: String(r[5] || ""),
    rateio: String(r[6] || ""),
    cardLast4: String(r[7] || ""),
    parcela: String(r[8] || "").trim(),
    acerto: String(r[9] || ""),
  }));

  return { ok: true, entries: entries };
}

function updateEntry(token, row, fields) {
  const auth = checkToken_(token);
  if (auth) return auth;
  if (!row || row < 2) return { ok: false, error: "invalid_row" };
  const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
  if (!sheet) return { ok: false, error: "sheet_not_found" };
  if (row > sheet.getLastRow()) return { ok: false, error: "row_out_of_range" };
  fields = fields || {};
  // Colunas: C=descricao(3), D=valor(4), F=categoria(6), G=rateio(7), I=parcela(9)
  sheet.getRange(row, 3).setValue(String(fields.descricao || ""));
  sheet.getRange(row, 4).setValue(Number(fields.valor) || 0);
  sheet.getRange(row, 6).setValue(String(fields.categoria || ""));
  sheet.getRange(row, 7).setValue(String(fields.rateio || ""));
  sheet.getRange(row, 9).setValue(String(fields.parcela || ""));
  return { ok: true, row: row };
}

function deleteEntry(token, row) {
  const auth = checkToken_(token);
  if (auth) return auth;
  if (!row || row < 2) return { ok: false, error: "invalid_row" };
  const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
  if (!sheet) return { ok: false, error: "sheet_not_found" };
  if (row > sheet.getLastRow()) return { ok: false, error: "row_out_of_range" };
  sheet.deleteRow(row);
  return { ok: true };
}

function checkToken_(token) {
  const expected = PropertiesService.getScriptProperties().getProperty(
    "WEBHOOK_TOKEN",
  );
  if (!expected || token !== expected) {
    return { ok: false, error: "unauthorized" };
  }
  return null;
}

function mapRow_(r) {
  return {
    data: formatBrDate_(r[0]),
    dataRef: typeof r[1] === "string" ? r[1] : formatBrDate_(r[1]),
    descricao: String(r[2] || ""),
    valor: Number(r[3]) || 0,
    origem: String(r[4] || ""),
    categoria: String(r[5] || ""),
    rateio: String(r[6] || ""),
    cardLast4: String(r[7] || ""),
    parcela: String(r[8] || "").trim(),
    acerto: String(r[9] || ""),
  };
}

function readData_(token) {
  const auth = checkToken_(token);
  if (auth) return auth;
  const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
  if (!sheet) return { ok: false, error: "sheet_not_found" };
  const last = sheet.getLastRow();
  if (last < 2) return { ok: true, rows: [] };
  const values = sheet.getRange(2, 1, last - 1, 10).getValues();
  return { ok: true, rows: values.map(mapRow_) };
}

function readAllForApi_(token) {
  return readData_(token);
}

function include_(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}
