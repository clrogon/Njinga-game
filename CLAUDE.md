# CLAUDE.md

Orientação para o Claude Code (claude.ai/code) a trabalhar neste repositório.

## Projecto

Njinga: Rainha do Ndongo e da Matamba é um jogo de plataformas 2D educativo em português (PT-AO), feito em Godot 4.7. Single-player, sem backend, sem contas, sem pagamentos — a superfície é a cena `scenes/game.tscn` e o script `scripts/njinga_game.gd` (ver [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) para detalhe).

O projecto nasceu de um starter Godot genérico ("cat platformer") disponibilizado pelo ambiente Manus. O código e os testes exclusivos desse starter foram removidos (ver [`docs/adr/0001-remove-inherited-template-code.md`](docs/adr/0001-remove-inherited-template-code.md)); os ficheiros de arte/áudio/fontes não usados permanecem no repositório por decisão documentada em [`CREDITS.md`](CREDITS.md), mas estão excluídos da build Web (`export_presets.cfg`).

## Comandos

Requer [Godot 4.7](https://godotengine.org/) (binário `godot` no PATH) e [pnpm](https://pnpm.io/).

```bash
pnpm run test:all          # toda a suite (5 testes GDScript + 2 testes Node) — corre antes de qualquer push
pnpm test                  # smoke: a cena principal arranca e carrega o conteúdo
pnpm run test:content      # valida o esquema de data/levels/*.json e data/diplomacy/*.json
pnpm run test:gameplay     # iniciar nível, recolher item, chegar à meta, desbloquear o próximo
pnpm run test:diplomacy    # a meta de um nível com diplomacia abre a conversa, não termina a fase
pnpm run test:save         # ronda completa de save_progress()/load_save() entre duas instâncias
pnpm run test:checks       # testes Node das ferramentas de verificação de export
pnpm run export            # exporta a build Web para dist/ (precisa de export templates instalados)
pnpm run verify-export     # node scripts/check-exported-pack.mjs — valida a estrutura do .pck exportado
```

**Armadilha conhecida**: `--user-data-dir` **não** é respeitado por `godot --headless -s <script>.gd` (modo MainLoop) neste binário — todas as execuções caem na pasta global `~/.local/share/godot/app_userdata/Njinga- Rainha do Ndongo e da Matamba/`, partilhando `njinga_save.json` entre execuções. Os testes que tocam em save/load (`test/gameplay_flow.gd`, `test/diplomacy_flow.gd`, `test/save_load.gd`) já limpam esse ficheiro no arranque (`_clear_save()`) — segue o mesmo padrão em qualquer teste novo que chame `save_progress()`/`load_save()`.

Alguns scripts de `package.json` (`dev`, `build`, `preview:build`, `doctor`, `inspect`, `assets:report`) invocam `scripts/manus/runtime-command.cjs` e só correm dentro do ambiente Manus.

## Arquitectura (resumo)

- `scenes/game.tscn` → `scripts/njinga_game.gd` (`NjingaGame`, único nó da cena) → pré-carrega apenas `scripts/njinga_player.gd`. Nenhum outro script, cena ou autoload é usado pelo jogo em execução.
- `project.godot` não define autoloads nem InputMap — `njinga_player.gd` lê teclas directamente (`Input.is_key_pressed`), sem acções mapeadas.
- Todo o visual é desenhado por código em `_draw()` — não há sprites/texturas usados pelo gameplay. As únicas imagens realmente consumidas são `assets/share/favicon.png` (ícone) e `assets/template/ui/loading-background.png` (boot splash).
- Conteúdo (níveis, diplomacia) vive em `data/levels/*.json` e `data/diplomacy/*.json`, carregado e interpretado directamente por `njinga_game.gd`; não há camada de tradução — o texto é directamente em português.

Ver [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) para a máquina de estados, o modelo de dados completo e o sistema de gravação.

## Notas sobre deriva de documentação

A versão anterior de `docs/GAME_PRODUCTION_PLAYBOOK.md` documentava o starter antigo ("Calico Yarn Quest"), não o jogo Njinga — foi removida junto com o código que descrevia. Se `docs/ARCHITECTURE.md` alguma vez divergir do código real (por exemplo depois de adicionar um nível ou um sistema novo), corrige o documento na mesma alteração; não deixes ficar como referência de um sistema que já não existe.
