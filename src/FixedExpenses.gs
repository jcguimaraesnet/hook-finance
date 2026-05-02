// Despesas fixas inseridas automaticamente na primeira compra de cada fatura nova.
// `refDay` = dia do mês (1-31). Mês e ano são preenchidos com o mês/ano da
// data de fechamento da fatura no momento da inserção.
const FIXED_EXPENSES = [
  { refDay: 6, description: "Diarista", value: 1500, origem: "Pix", categoria: "Contas", rateio: "Dani" },
  { refDay: 6, description: "Plano de Saúde (Dani)", value: 761.81, origem: "Pix", categoria: "Contas", rateio: "Dani" },
  { refDay: 6, description: "Plano de Saúde (Julio)", value: 761.81, origem: "Pix", categoria: "Contas", rateio: "Julio" },
  { refDay: 7, description: "Mensalidade creche 1/2", value: 1741.40, origem: "Pix", categoria: "Contas", rateio: "Dani" },
  { refDay: 7, description: "Mensalidade creche 2/2", value: 1741.40, origem: "Pix", categoria: "Contas", rateio: "Julio" },
  { refDay: 5, description: "Ajuda de custo (Creche)", value: -620, origem: "Pix", categoria: "Contas", rateio: "Dani" },
  { refDay: 6, description: "Claro Internet - https://minhaclaroresidencial.claro.com.br", value: 0.01, origem: "Pix", categoria: "Contas", rateio: "Dani" },
  { refDay: 5, description: "Gás", value: 120.42, origem: "Pix", categoria: "Contas", rateio: "Dani" },
  { refDay: 10, description: "Condomínio 1/2", value: 1550, origem: "Pix", categoria: "Contas", rateio: "Julio" },
  { refDay: 10, description: "Condomínio 1/2", value: 0, origem: "Pix", categoria: "Contas", rateio: "Dani" },
  { refDay: 7, description: "Energia (débito automático)", value: 500, origem: "Pix", categoria: "Contas", rateio: "Dani" },
  { refDay: 15, description: "Guia de Previdência Social", value: 1300, origem: "Pix", categoria: "Contas", rateio: "Julio" },
  { refDay: 15, description: "Guia de Previdência Social (coloquei pra Dani pra equilibrar)", value: 1300, origem: "Pix", categoria: "Contas", rateio: "Dani" },
  { refDay: 5, description: "Dízimo", value: 500, origem: "Pix", categoria: "Contas", rateio: "Julio" },
  { refDay: 5, description: "Dízimo", value: 500, origem: "Pix", categoria: "Contas", rateio: "Dani" },
];
