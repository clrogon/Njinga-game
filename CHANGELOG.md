# Changelog

Todas as alterações notáveis a este projecto são registadas aqui. Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-PT/1.0.0/); o projecto ainda não tem versões/tags, por isso tudo vive em `[Unreleased]` até à primeira release.

## [Unreleased]

### Added
- Repositório inicial criado com o projecto Godot 4.7 completo (fonte + build Web/WASM compilada), a partir do starter "cat platformer" do ambiente Manus adaptado para a Njinga.
- Suite de testes real contra `njinga_game.gd`/`njinga_player.gd`: `test/smoke.gd`, `test/content_integrity.gd`, `test/gameplay_flow.gd`, `test/diplomacy_flow.gd`, `test/save_load.gd`.
- `docs/ARCHITECTURE.md`, `docs/adr/` (com [ADR 0001](docs/adr/0001-remove-inherited-template-code.md)), `CLAUDE.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`.

### Changed
- `export_presets.cfg`: excluídos da build Web os ficheiros de arte/áudio/fontes do starter não usados pelo jogo (~6,25 MiB menos por jogador); mantidos no repositório.
- `README.md` reescrito para descrever o jogo real (a versão original, herdada do starter, descrevia o fluxo de desenvolvimento genérico do Manus, não a Njinga).

### Removed
- ~50 scripts, 2 autoloads, 1 cena e os dados exclusivos do starter "cat platformer" herdado, confirmados sem nenhuma referência viva em `njinga_game.gd`/`njinga_player.gd` (ver [ADR 0001](docs/adr/0001-remove-inherited-template-code.md)).
- 27 ficheiros de teste escritos contra esse código removido (nenhum exercitava o jogo real — confirmado a correr cada um contra um Godot 4.7 real antes de apagar).
- `docs/GAME_PRODUCTION_PLAYBOOK.md`, que documentava em detalhe o sistema removido.

### Known gaps
- Sem licença definida (ver [`README.md`](README.md#licença)).
- Sem CI (nenhum workflow corre `pnpm run test:all` automaticamente).
- `data/i18n/pt-AO.json` órfão — não lido por nenhum código.
