# Contribuir para Njinga-game

> **EN**: Contributing guide for Njinga-game, a single-player educational Godot platformer. Portuguese is the project's working language, matching its in-game text; this guide follows that convention.

## Configuração de desenvolvimento

**Pré-requisitos**:
- [Godot 4.7](https://godotengine.org/) com suporte a exportação Web
- [pnpm](https://pnpm.io/) (para os scripts auxiliares em Node — ver [`CLAUDE.md`](CLAUDE.md#comandos))

**Primeiros passos**:

```bash
git clone https://github.com/clrogon/Njinga-game.git
cd Njinga-game
pnpm run test:all   # confirma que o ambiente está pronto
```

Abre `project.godot` no editor Godot 4.7 para trabalhar na cena/scripts, ou edita directamente e usa `pnpm run test:all` para validar.

## Fluxo de trabalho

1. Cria um ramo a partir de `main`.
2. Faz a alteração. Mantém-na focada — um ramo, um assunto.
3. Corre `pnpm run test:all` antes de qualquer commit; se tocaste em `data/levels/*.json` ou `data/diplomacy/*.json`, confirma que `pnpm run test:content` continua verde.
4. Abre um Pull Request contra `main`. Descreve o quê e o porquê, não apenas o quê — um PR sem contexto obriga quem revisa a reconstruir o raciocínio.
5. Se a alteração for uma decisão arquitectural com impacto real (não um ajuste local), considera um ADR em `docs/adr/` (ver o modelo em [`docs/adr/README.md`](docs/adr/README.md)).

## Convenções de código

**GDScript**: indentação de 4 espaços (não tabs) — consistente com `scripts/njinga_game.gd`/`scripts/njinga_player.gd`. `snake_case` para funções e variáveis, `PascalCase` para classes/nós. Tipagem estática onde ajuda a legibilidade (`var x: int`, `-> void`), sem forçar onde o tipo é óbvio pelo contexto.

**Dados** (`data/levels/*.json`, `data/diplomacy/*.json`): segue o esquema documentado em [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md#modelo-de-dados). `njinga_game.gd` engole silenciosamente um JSON malformado — corre `pnpm run test:content` sempre que editares um destes ficheiros, não confies apenas em abrir o jogo.

**Testes**: ficheiros `test/*.gd` são scripts `SceneTree` autónomos (ver qualquer um dos existentes como modelo), não GUT nem outro framework — o projecto não depende de nenhum. Cada teste imprime um marcador `[NOME_PASS]`/`[NOME_FAIL]` e sai com código 0/1; `scripts/godot-check.mjs` depende desse contrato para os scripts `pnpm run test:*`.

## Mensagens de commit

Sem formato imposto, mas a primeira linha deve dizer o que mudou em termos concretos (não "fix bug" ou "updates"). Se a mudança para de só ser um ajuste e passa a ser uma decisão (remover um sistema, trocar uma abordagem), o corpo do commit deve explicar o porquê — ver o histórico do repositório para exemplos.

## Reportar problemas

Abre uma issue no GitHub. Para um bug: o que esperavas, o que aconteceu, passos para reproduzir, e se possível qual nível/ficheiro está envolvido. Para uma vulnerabilidade de segurança, ver [`SECURITY.md`](SECURITY.md) — não abras uma issue pública.

## Licença

Este repositório ainda não tem uma licença definida (ver [`README.md`](README.md#licença)). Contribuições são aceites com esse entendimento; a licença final será decidida pelo proprietário do repositório.
