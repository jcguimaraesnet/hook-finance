// One-shot fix: a migration anterior gravou "X/Y" em col I sem forçar formato TEXT,
// e o Google Sheets auto-converteu valores como "1/3" em Date (1 de março).
// Esta função:
//   1) Lê col I do ciclo 06/05/2026
//   2) Para cada célula que é Date, extrai d/M e regrava como TEXTO
//   3) Para cada célula que já é texto "X/Y", apenas reaplica formato TEXT (idempotente)
//
// USO:
//   1) Aguarde push (clasp/GH Action) e rode `fixParcelaCells20260506` no editor Apps Script.
//   2) Confira o log — deve listar ~33 conversões Date→Texto.
//   3) DELETE este arquivo + push.

function fixParcelaCells20260506() {
  const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
  if (!sheet) { Logger.log("ERRO: planilha não encontrada."); return; }
  const last = sheet.getLastRow();
  if (last < 2) { Logger.log("Planilha vazia."); return; }

  const tz = Session.getScriptTimeZone();
  const targetCycle = "06/05/2026";

  function fmtDate(v) {
    if (v instanceof Date) return Utilities.formatDate(v, tz, "dd/MM/yyyy");
    return String(v || "").trim();
  }

  // 1) Localiza range de linhas do ciclo.
  const dataCol = sheet.getRange(2, 1, last - 1, 1).getValues();
  const matchIndexes = [];
  for (let i = 0; i < dataCol.length; i++) {
    if (fmtDate(dataCol[i][0]) === targetCycle) matchIndexes.push(i + 2);
  }
  if (matchIndexes.length === 0) {
    Logger.log("Nenhuma linha encontrada para fatura " + targetCycle);
    return;
  }
  const minRow = matchIndexes[0];
  const maxRow = matchIndexes[matchIndexes.length - 1];
  const numRows = maxRow - minRow + 1;

  // 2) Lê col I do range
  const range = sheet.getRange(minRow, 9, numRows, 1);
  const values = range.getValues();

  let dateConverted = 0;
  let textKept = 0;
  let empty = 0;
  const newValues = new Array(numRows);

  for (let i = 0; i < numRows; i++) {
    const v = values[i][0];
    if (v instanceof Date) {
      const day = Utilities.formatDate(v, tz, "d");
      const month = Utilities.formatDate(v, tz, "M");
      const fixed = day + "/" + month;
      Logger.log(
        "row " + (minRow + i) + ": Date " +
        Utilities.formatDate(v, tz, "yyyy-MM-dd") + " → texto '" + fixed + "'"
      );
      newValues[i] = [fixed];
      dateConverted++;
    } else {
      const s = String(v || "").trim();
      if (!s) {
        newValues[i] = [""];
        empty++;
      } else {
        newValues[i] = [s];
        textKept++;
      }
    }
  }

  // 3) Força formato TEXT em todas as células do range, depois grava os valores corrigidos.
  range.setNumberFormat("@");
  range.setValues(newValues);

  Logger.log("=== RESULTADO ===");
  Logger.log("Linhas no ciclo: " + numRows);
  Logger.log("Date convertido pra texto: " + dateConverted);
  Logger.log("Texto preservado: " + textKept);
  Logger.log("Vazio: " + empty);
  Logger.log("DONE.");
}
