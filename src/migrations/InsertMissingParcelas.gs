// One-shot: insere as 5 parcelas faltantes na fatura 06/06/2026.
//
// Estratégia:
//   1) Identifica as 5 entries faltantes (mesma lógica do checkMissingParcelas, mas
//      restringe explicitamente às 5 src_row conhecidas pra evitar surpresas)
//   2) Para cada nova linha, localiza a posição de inserção no slab 06/06 baseada
//      em dataRef (insere ANTES da primeira linha existente com dataRef estritamente
//      menor; se não houver, insere logo após a última linha do ciclo)
//   3) Insere de baixo pra cima (ordem decrescente de targetRow) pra evitar shift
//   4) Força formato TEXT na col I antes de gravar a parcela
//
// USO: rode `insertMissingParcelas` no editor Apps Script. Após verificar, delete o arquivo.

const MISSING_SOURCE_ROWS = [85, 150, 156, 203, 280];
const NEW_CYCLE = "06/06/2026";

function insertMissingParcelas() {
  const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
  if (!sheet) { Logger.log("ERRO: planilha não encontrada."); return; }
  const last = sheet.getLastRow();
  if (last < 2) { Logger.log("Planilha vazia."); return; }

  const tz = Session.getScriptTimeZone();

  function fmtDate(v) {
    if (v instanceof Date) return Utilities.formatDate(v, tz, "dd/MM/yyyy");
    return String(v || "").trim();
  }
  function dataRefMs_(v) {
    // Retorna timestamp comparável. Se Date, .getTime(); se string "DD/MM/YYYY HH:MM",
    // parseia manualmente; se nada, retorna NaN.
    if (v instanceof Date) return v.getTime();
    const s = String(v || "").trim();
    if (!s) return NaN;
    const m = s.match(/^(\d{1,2})\/(\d{1,2})\/(\d{2,4})(?:\s+(\d{1,2}):(\d{1,2}))?/);
    if (!m) return NaN;
    let y = parseInt(m[3], 10);
    if (y < 100) y += 2000;
    const mo = parseInt(m[2], 10) - 1;
    const d = parseInt(m[1], 10);
    const hh = m[4] ? parseInt(m[4], 10) : 0;
    const mi = m[5] ? parseInt(m[5], 10) : 0;
    return new Date(y, mo, d, hh, mi).getTime();
  }
  function parsePAtualTotal_(parcelaCell) {
    if (parcelaCell instanceof Date) {
      const day = parseInt(Utilities.formatDate(parcelaCell, tz, "d"), 10);
      const month = parseInt(Utilities.formatDate(parcelaCell, tz, "M"), 10);
      return { atual: day, total: month };
    }
    const s = String(parcelaCell || "").trim();
    if (!s || s.indexOf("/") === -1) return null;
    const parts = s.split("/");
    const atual = parseInt(parts[0], 10);
    const total = parseInt(parts[1], 10);
    if (!atual || !total) return null;
    return { atual: atual, total: total };
  }

  // 1) Lê toda a planilha (10 cols).
  const all = sheet.getRange(2, 1, last - 1, 10).getValues();

  // 2) Coleta as src rows (1-indexed na planilha).
  const sources = [];
  for (const srcRow of MISSING_SOURCE_ROWS) {
    const idx = srcRow - 2;
    if (idx < 0 || idx >= all.length) {
      Logger.log("ERRO: src row " + srcRow + " fora do range. Abortando.");
      return;
    }
    const r = all[idx];
    const p = parsePAtualTotal_(r[8]);
    if (!p) {
      Logger.log("ERRO: src row " + srcRow + " sem parcela válida (col I = '" + r[8] + "'). Abortando.");
      return;
    }
    if (p.atual >= p.total) {
      Logger.log("ERRO: src row " + srcRow + " já é última parcela (" + p.atual + "/" + p.total + "). Abortando.");
      return;
    }
    sources.push({
      srcRow: srcRow,
      raw: r,
      parcelaAtual: p.atual,
      parcelaTotal: p.total,
      novaParcela: (p.atual + 1) + "/" + p.total,
      dataRefMs: dataRefMs_(r[1]),
    });
  }

  Logger.log("Sources coletados: " + sources.length);
  for (const s of sources) {
    Logger.log("  src " + s.srcRow + ": " + s.raw[2] + " R$ " + s.raw[3] +
      " | " + s.parcelaAtual + "/" + s.parcelaTotal + " → " + s.novaParcela +
      " | dataRef='" + (s.raw[1] instanceof Date ? Utilities.formatDate(s.raw[1], tz, "dd/MM/yyyy HH:mm") : s.raw[1]) + "'");
  }

  // 3) Indexa rows do ciclo alvo (06/06/2026).
  const targetRows = []; // { absRow, dataRefMs }
  for (let i = 0; i < all.length; i++) {
    if (fmtDate(all[i][0]) === NEW_CYCLE) {
      targetRows.push({ absRow: i + 2, dataRefMs: dataRefMs_(all[i][1]) });
    }
  }
  Logger.log("Linhas existentes em " + NEW_CYCLE + ": " + targetRows.length);

  // 4) Decide targetRow pra cada source — primeira linha do 06/06 cuja dataRef é
  //    estritamente MENOR que a nova; se não houver, vai logo após a última linha.
  let lastCycleRow = targetRows.length ? targetRows[targetRows.length - 1].absRow : 0;
  // Se não há nenhuma linha em 06/06, define ponto de inserção como o início da planilha
  // após o cabeçalho (row 2). Mas é improvável já que o user disse que tem 69 linhas.
  if (targetRows.length === 0) {
    Logger.log("AVISO: nenhuma linha em " + NEW_CYCLE + " — todas serão inseridas na linha 2.");
  }

  for (const s of sources) {
    let target = -1;
    for (const tr of targetRows) {
      if (!isNaN(tr.dataRefMs) && tr.dataRefMs < s.dataRefMs) {
        target = tr.absRow;
        break;
      }
    }
    if (target === -1) {
      // dataRef da source é mais antiga (ou igual) a todas as existentes — vai pro fim do ciclo.
      target = lastCycleRow > 0 ? lastCycleRow + 1 : 2;
    }
    s.targetRow = target;
  }

  // 5) Ordena de baixo pra cima (target desc) pra evitar shift entre inserts.
  sources.sort((a, b) => b.targetRow - a.targetRow);

  Logger.log("=== Plano de inserção (bottom-up) ===");
  for (const s of sources) {
    Logger.log("  inserir antes da row " + s.targetRow + " ← " + s.raw[2] + " R$ " + s.raw[3] + " (" + s.novaParcela + ")");
  }

  // 6) Constrói new row e insere.
  const cycleA = new Date(2026, 5, 6); // mês 5 = junho (0-indexed)
  for (const s of sources) {
    const r = s.raw;
    const newRow = [
      cycleA,           // A: ciclo da fatura
      r[1],             // B: dataRef (copiado)
      r[2],             // C: descricao (verbatim)
      r[3],             // D: valor
      r[4],             // E: origem (Cartão)
      r[5],             // F: categoria
      r[6],             // G: rateio
      r[7],             // H: cardLast4
      s.novaParcela,    // I: parcela "X+1/Y"
      r[9],             // J: acerto
    ];
    sheet.insertRowBefore(s.targetRow);
    // Aplica formato TEXT em col I ANTES de gravar pra evitar auto-Date.
    sheet.getRange(s.targetRow, 9).setNumberFormat("@");
    sheet.getRange(s.targetRow, 1, 1, 10).setValues([newRow]);
    Logger.log("Inserido na row " + s.targetRow + " | parcela='" + s.novaParcela + "'");
  }

  Logger.log("DONE. " + sources.length + " linhas inseridas.");
}
