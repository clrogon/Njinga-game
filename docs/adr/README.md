# Architectural Decision Records (ADR)

Este directório guarda os registos de decisões arquitecturais com impacto significativo no projecto Njinga-game.

## O que é um ADR?

Um ADR documenta uma decisão com impacto relevante na arquitectura, segurança ou fluxo de trabalho do projecto: o contexto, as opções consideradas, a decisão tomada e as suas consequências.

## Índice

| ID | Título | Data | Estado |
|----|--------|------|--------|
| [0001](0001-remove-inherited-template-code.md) | Remover o código herdado do starter | 2026-10-09 | Aceite |

## Modelo

Para adicionar um novo ADR, copia este modelo:

```markdown
# ADR NNNN — Título

**Data**: AAAA-MM-DD
**Estado**: Proposto | Aceite | Obsoleto | Substituído por [NNNN]
**Decisores**: Nomes

---

## Contexto
Qual é o problema que motiva esta decisão?

## Opções consideradas
| Opção | Vantagens | Desvantagens |
|-------|-----------|--------------|

## Decisão
O que foi decidido/feito?

## Consequências
O que fica mais fácil ou mais difícil por causa desta mudança?

## Verificação
Como sabemos que esta decisão está a funcionar?
```
