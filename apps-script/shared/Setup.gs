// Rode esta função UMA VEZ no editor do Apps Script para definir o token.
// Depois, troque o valor abaixo por um placeholder e não comite o token real.
function setupToken() {
  PropertiesService.getScriptProperties().setProperty(
    "WEBHOOK_TOKEN",
    "TROCAR_POR_TOKEN_FORTE",
  );
}
