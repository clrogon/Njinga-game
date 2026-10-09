# ADR 0001 — Remover o código herdado do starter

**Data**: 2026-10-09
**Estado**: Aceite
**Decisores**: Cláudio Roberto Gonçalves (via sessão Claude Code)

---

## Contexto

O projecto nasceu de um starter Godot genérico de plataformas ("cat platformer") disponibilizado pelo ambiente Manus. O MVP da Njinga foi construído por cima dele através de dois ficheiros novos (`scripts/njinga_game.gd`, `scripts/njinga_player.gd`) e a troca da cena principal (`scenes/game.tscn`) para os carregar — mas o resto do starter (~50 scripts de menus/HUD/áudio/gravação/tuning, 2 autoloads, 1 cena, e os 27 testes escritos contra eles) permaneceu no repositório, ainda ligado em `project.godot` e ainda incluído em cada export, sem que nada no caminho de execução real o referenciasse.

A suite de testes herdou o mesmo problema: todos os 27 ficheiros de teste do starter ou pré-carregavam directamente um script do starter, ou arrancavam `scenes/game.tscn` esperando o layout de nós/API do `game.gd` antigo — que já não existe no script actual. Isto foi confirmado a correr cada teste contra um binário Godot 4.7 real, não apenas por leitura estática: `test/smoke.gd` já falhava (uma verificação de fallback de fonte não relacionada com o jogo real), e `test/responsive_layout.gd` falhava a procurar um nó (`HudLayer/ResponsiveHud/TopBar`) que não existe na cena actual.

## Opções consideradas

| Opção | Vantagens | Desvantagens |
|-------|-----------|--------------|
| Manter tudo como está | Zero risco imediato, zero esforço | Autoloads mortos continuam a correr em todo o arranque; cada export continua a incluir ~50 scripts e dados nunca lidos; a suite de testes continua a dar falsa confiança (testa o jogo errado) |
| Mover para uma pasta `legacy/` isolada | Preserva o histórico sem o misturar com o código activo | Ainda precisa de ser excluído manualmente do export; não resolve a suite de testes |
| Apagar o código morto (scripts, autoloads, cena, dados exclusivos, testes), manter os ficheiros de arte/áudio/fontes por decisão já documentada em `CREDITS.md`, e escrever testes novos contra o jogo real | Remove o risco e o ruído definitivamente; a suite de testes passa a provar algo real | Perde-se a base de código do starter como referência directa (fica preservada no histórico do git) |

## Decisão

Apagar o grafo de dependências morto confirmado por `grep` antes de qualquer remoção — nenhum ficheiro apagado era referenciado, directa ou indirectamente, por `njinga_game.gd`/`njinga_player.gd`:
- ~50 scripts (`scripts/*.gd` do starter, incluindo `scripts/manus/` exclusivos dele)
- 2 autoloads (`autoload/i18n.gd`, `autoload/manus_font_theme.gd`) e as secções `[autoload]`/`[input]` de `project.godot` que só os ligavam
- 1 cena (`scenes/title_screen.tscn`)
- os dados exclusivos desses sistemas (`config/tuning.json`, `localization/en.json`/`zh-CN.json`, `data/stages/*.json`)
- `docs/GAME_PRODUCTION_PLAYBOOK.md`, que documentava o sistema apagado em detalhe
- os 27 ficheiros de teste do starter, substituídos por 5 testes novos contra `njinga_game.gd` real (`test/smoke.gd`, `test/content_integrity.gd`, `test/gameplay_flow.gd`, `test/diplomacy_flow.gd`, `test/save_load.gd`)

Os ficheiros de arte/áudio/fontes do starter (`assets/template/cat/*`, `assets/template/audio/*`, as fontes CJK) foram **mantidos no repositório**, consistente com a política já documentada em `CREDITS.md` de preservar recursos não usados do starter como referência — mas excluídos da build Web em `export_presets.cfg` (ver follow-up abaixo), já que não precisam de ser descarregados por quem joga.

## Consequências

- `pnpm run test:all` passa a provar que o jogo real funciona, não que um sistema não usado ainda compila.
- `project.godot` fica sem autoloads nem InputMap — qualquer sistema global futuro (áudio, por exemplo) tem de ser reintroduzido deliberadamente.
- A base de código ficou ~11 600 linhas mais pequena (145 ficheiros alterados), o que reduz a área de confusão para quem contribuir a seguir.
- **Trade-off**: perdeu-se a base i18n EN/zh-CN do starter por inteiro; se algum dia se quiser localização real, tem de ser construída de novo (`data/i18n/pt-AO.json` já existe como referência textual, mas nunca esteve ligado a código).
- Follow-up directo desta decisão: `export_presets.cfg` foi depois ajustado para excluir os ficheiros de arte/áudio/fontes mantidos da build Web (~6,25 MiB menos por jogador), já que "mantido no repositório por referência" nunca implicou "deve ser descarregado por quem joga".

## Verificação

- `pnpm run test:all` verde (5 testes GDScript + 2 testes Node) contra um binário Godot 4.7 headless real, antes e depois da remoção.
- `grep` confirmou zero referências de `njinga_game.gd`/`njinga_player.gd` a qualquer ficheiro apagado, antes da remoção.
- Re-execução de `godot --headless --path . --import` sem avisos de recurso em falta depois da remoção.
