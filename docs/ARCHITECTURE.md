# Njinga: Rainha do Ndongo e da Matamba — Arquitectura

## Índice

- [Resumo](#resumo)
- [Árvore de cena e autoloads](#árvore-de-cena-e-autoloads)
- [Máquina de estados](#máquina-de-estados)
- [Modelo de dados](#modelo-de-dados)
- [Sistema de gravação](#sistema-de-gravação)
- [Renderização](#renderização)
- [Build e export Web](#build-e-export-web)
- [Testes](#testes)
- [Lacunas conhecidas](#lacunas-conhecidas)

## Resumo

Jogo de plataformas 2D single-player, sem backend, sem contas, sem rede. Um único script (`scripts/njinga_game.gd`, ~1000 linhas) faz de router de estado, mundo, HUD, diplomacia e persistência; um segundo script (`scripts/njinga_player.gd`) trata do movimento e emite sinais de acção para o primeiro. Não há mais nenhuma dependência de código em tempo de execução.

```
scenes/game.tscn
  └─ NjingaGame (Node2D, script=njinga_game.gd)
       └─ (runtime) njinga_player.gd  — CharacterBody2D criado em build_world()
```

## Árvore de cena e autoloads

`project.godot` não declara `[autoload]` nem `[input]` — isto é deliberado, não uma omissão (ver [ADR 0001](adr/0001-remove-inherited-template-code.md)). O starter de onde o projecto nasceu tinha sete autoloads (i18n, tema de fontes, política de viewport, áudio, gravação, tuning) e um InputMap completo; nenhum era referenciado por `njinga_game.gd`/`njinga_player.gd`, por isso foram removidos em bloco.

Consequência prática: qualquer sistema novo e verdadeiramente global (áudio, por exemplo) tem de ser reintroduzido deliberadamente — não há nenhum hook escondido para reaproveitar.

## Máquina de estados

`NjingaGame.state` é uma string com estes valores, todos geridos directamente por `njinga_game.gd`:

| Estado | Entrada | Saída |
|---|---|---|
| `menu` | `_ready()`, ou `show_menu()` a partir de qualquer ecrã | `start_level(i)` → `playing` |
| `playing` | `build_world()` (dentro de `start_level`) | meta atingida → `diplomacy` (se `level.diplomacy` e ainda não resolvida) ou `result` (via `finish_level()`) |
| `diplomacy` | `begin_diplomacy()` | depois da última ronda (`choose_diplomacy()`) → ecrã de resultado da diplomacia; "Continuar" chama `finish_level()` → `result` |
| `result` | `finish_level()` ou `show_result()` | "Próximo nível"/"Recomeçar" → `playing`; "Voltar ao menu" → `menu` |

`update_gameplay(delta)` só corre quando `state == "playing"`; é aí que vivem a colisão, os inimigos, os itens coleccionáveis, os checkpoints e a furtividade (`check_stealth()`), por este código em `_process()`.

## Modelo de dados

Tudo o que varia por nível ou por diálogo é JSON, carregado por `read_json()`/`load_content()` a partir de caminhos constantes (`LEVEL_PATHS`, `DIPLOMACY_PATHS`) no topo de `njinga_game.gd` — não há descoberta automática de ficheiros.

**`data/levels/nivelN.json`** (N = 1–6):

| Campo | Tipo | Nota |
|---|---|---|
| `id`, `title`, `era`, `place`, `theme`, `summary`, `objective`, `finale` | string | texto em português, usado directamente na UI |
| `spawn` | `[x, y]` | posição inicial do jogador |
| `world_width`, `goal_x` | número | limite da câmara e ponto de chegada |
| `platforms` | `[[x, y, w, h], ...]` | rectângulos de colisão estática |
| `collectibles` | `[{type, x, y, ...}]` | `type` ∈ `nzimbu`, `card`, `captive`, `ally`, `material`, `quiver` |
| `enemies` | `[{type, x, y, ...}]` | `type` ∈ `patrulha`, `sentinela`, `saqueador`, `guarda`, `mosqueteiro`, `campeao`, `canhao`, … |
| `hazards` | `[{type, x, y, w, h}]` | rectângulos de dano |
| `checkpoints` | `[[x, y], ...]` ou `[{x, y}]` | toque no `x` guarda progresso |
| `diplomacy` | string (opcional) | id que indexa `data/diplomacy/*.json` |

**`data/diplomacy/*.json`**: `title`, `interlocutor`, `opening`, e `rounds: [{request, hint, best}]`, onde `best` ∈ `Firme`, `Conciliadora`, `Astuta`. `choose_diplomacy()` sobe o `prestige` quando a escolha coincide com `best` (ou é a vizinha "diplomaticamente próxima"), desce quando não coincide — a diplomacia nunca bloqueia a progressão, só afecta o texto de resultado.

`test/content_integrity.gd` valida este esquema contra os ficheiros reais; é a única rede de segurança, porque `read_json()`/`load_content()` **engolem silenciosamente** um ficheiro malformado (`JSON.parse_string` devolve `null`, o chamador só verifica `if data is Dictionary` e segue sem avisar).

## Sistema de gravação

`save_data` é um `Dictionary` guardado em dois sítios, por este código em `save_progress()`:
1. `user://njinga_save.json` via `FileAccess` (sempre).
2. `localStorage["njinga_save"]` via `JavaScriptBridge.eval`, só quando `OS.has_feature("web")`.

`load_save()` lê o localStorage primeiro (no browser), cai para `user://` se estiver vazio. Não há campo de versão no esquema gravado — uma mudança futura de formato (por exemplo adicionar um campo obrigatório) precisa de um caminho de migração explícito, porque hoje um save antigo é simplesmente mesclado por chave (`for key in loaded: save_data[key] = loaded[key]`), sem qualquer verificação de compatibilidade.

## Renderização

Não há sprites nem texturas no caminho de jogo. `njinga_game.gd`/`njinga_player.gd` desenham tudo via `_draw()` com formas primitivas (`draw_rect`, `draw_line`, `draw_arc`, `draw_colored_polygon`). As únicas duas imagens realmente usadas em todo o projecto são `assets/share/favicon.png` (ícone da aplicação) e `assets/template/ui/loading-background.png` (boot splash do motor, configurado em `project.godot`). Todo o resto debaixo de `assets/template/` (sprites de gato, áudio, fontes CJK) é herdado do starter e não é referenciado por nenhum script activo.

## Build e export Web

`export_presets.cfg` define um único preset Web/WASM. `export_filter="all_resources"` inclui tudo por omissão; `exclude_filter` remove explicitamente o output de build (`dist/*`, `site/*`, `test/*`, …) **e** os ficheiros de arte/áudio/fontes do starter que a secção anterior descreve como não usados — isto reduz o download do jogador em ~6 MiB sem apagar nada do repositório. `html/custom_html_shell` aponta para `res://web/loading.html`.

```bash
pnpm run export          # godot --headless --path . --export-release Web dist/index.html
pnpm run verify-export   # valida a estrutura do .pck resultante
```

## Testes

Cobertura real contra `njinga_game.gd`/`njinga_player.gd` — ver [`CLAUDE.md`](../CLAUDE.md#comandos) para os comandos. Resumo:

| Ficheiro | O que verifica |
|---|---|
| `test/smoke.gd` | a cena arranca, carrega 6 níveis e 3 diálogos de diplomacia |
| `test/content_integrity.gd` | esquema de todo o JSON de níveis/diplomacia |
| `test/gameplay_flow.gd` | iniciar nível → recolher item → chegar à meta → terminar fase → desbloquear a próxima |
| `test/diplomacy_flow.gd` | a meta de um nível com diplomacia abre a conversa em vez de terminar a fase; respostas "best" sobem o prestígio |
| `test/save_load.gd` | ronda de save/load entre duas instâncias independentes |
| `test/godot-check.test.mjs`, `test/exported-pack-profile.test.mjs` | testes Node das ferramentas de verificação (`scripts/godot-check.mjs`, `scripts/check-exported-pack.mjs`), sem tocar no motor |

## Lacunas conhecidas

- **Sem licença definida** — ver [`README.md`](../README.md#licença).
- **Sem CI** — não há workflow do GitHub Actions a correr `pnpm run test:all` em cada push/PR; a suite só corre quando alguém a invoca manualmente.
- **`data/i18n/pt-AO.json` órfão** — não é lido por nenhum código; o texto real vive directamente em `data/levels/*.json`. Fica como referência textual, não como fonte de dados activa.
- **Falhas de parsing silenciosas** — ver a nota em [Modelo de dados](#modelo-de-dados).
