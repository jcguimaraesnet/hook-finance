---
status: stable
last_updated: 2026-05-07
---

# Acerto — acerto final do mês entre Júlio e Dani

Página com 2 [AcertoCard](../cards/acerto-card.md) lado a lado (Júlio + Dani) mostrando o cartão compartilhado, cartão pessoal e Pix marcadas como `acerto`. O Δ no header de cada card indica a diferença (mesma regra do PersonCard de Consulta).

## Contexto

No fim do mês, o casal "fecha" as contas: quem deve a quem, quanto. Esta página agrega só o que entra no acerto. Pix não-`acerto` ficam fora por padrão; o card do Júlio permite expandir e mostrar tudo (apenas como referência — não muda o cálculo).

## Regras

### Layout

- 2 [AcertoCard](../cards/acerto-card.md) (Júlio + Dani) em grid 2-col em tablet+, empilhados em mobile.
- Não tem sub-tabs nem filtros adicionais (o filtro de mês é o StickyHeader compartilhado).

### Source

- `useMonthData(currentMonth)` — mesma query de Consulta. Sem chamadas extras.

### Toggle do Pix do Júlio

- Estado `acertoPixJulio: boolean` no store global (Zustand, persistido). Default `false`.
- Click no header `"Pix (contas)"` do card de Júlio → `toggleAcertoPix`.
- Quando `true`: card de Júlio mostra **todas** as Pix dele do mês. Total do card cresce.
- Card de Dani **não** tem toggle equivalente.

### Δ (diff)

Mesma regra de [diff-calculation.md](../rules/diff-calculation.md). Toggle Δ é per-card (sessionStorage por pessoa). Compartilha o mesmo flag com PersonCard de Consulta.

## Edge cases

- **Mês sem nada:** ambos cards mostram totais 0 e Δ = +R$ 0,00. Ainda renderiza.
- **Mês sem Pix de nenhum:** seções Pix ocultas em ambos.
- **Mês sem Pix de Dani mas com Pix de Júlio (raro):** card de Dani sem seção Pix; card de Júlio mostra a Pix dele (acerto-only por default).
- **`currentMonth` mudou enquanto eu olhava o Acerto:** queryClient compartilha cache; o card re-renderiza automaticamente.

## Implementações

- **PWA:** [web/src/pages/AcertoPage.tsx](../../../web/src/pages/AcertoPage.tsx) (página + AcertoCard inline).
- **Após Onda 2:** sem mudanças visuais; lógica do diff/split passa a vir de `web/src/core/rules/`.
- **Flutter:** `app/lib/features/acerto/` (Onda 5).

## Specs relacionadas

- [../cards/acerto-card.md](../cards/acerto-card.md)
- [../rules/split-for-person.md](../rules/split-for-person.md)
- [../rules/diff-calculation.md](../rules/diff-calculation.md)
- [../state/persistence.md](../state/persistence.md) — `acertoPixJulio`, toggle Δ
- [../responsive/breakpoints.md](../responsive/breakpoints.md)
