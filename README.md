# Njinga: Rainha do Ndongo e da Matamba

Jogo de plataformas 2D educativo, em português (PT-AO), sobre Njinga Mbandi, rainha do Ndongo e da Matamba. Guia Njinga por seis momentos históricos — Kabasa, Luanda, Kindonga e Matamba — combinando plataformas, diplomacia, furtividade e cartões de Crónica que desbloqueiam contexto histórico.

> **EN:** A browser-based 2D educational platformer, in Portuguese (Angolan orthography), telling the story of Queen Njinga of Ndongo and Matamba across six historical stages. Built with Godot 4.7.

## Jogar

Uma versão compilada para navegador (Web/WASM) está disponível em [`web-build/`](web-build/index.html). Para jogar localmente, serve a pasta a partir de um servidor HTTP (os navegadores bloqueiam `file://` para WASM):

```bash
cd web-build
python3 -m http.server 8000
# abre http://localhost:8000/index.html
```

## Estrutura do projecto

```
project.godot            Configuração do projecto Godot (sem autoloads; NjingaGame é autocontido)
scenes/game.tscn          Cena de entrada (NjingaGame)
scripts/njinga_game.gd    Router de menus, níveis, HUD e persistência
scripts/njinga_player.gd  Movimento e sinais de acções do jogador
data/levels/              Geometria, objectivos e cartões de cada nível (nivel1–6)
data/diplomacy/           Falas e perfis das cenas de diplomacia
assets/                   Arte, tipografia e áudio
docs/                     Documentação de implementação (produção, multijogador)
test/                     Testes do jogo real (GDScript) e das ferramentas de export (Node)
web-build/                Build Web/WASM exportada, pronta a publicar
```

O projecto partiu de um starter Godot de plataformas (género "cat platformer") disponibilizado pelo ambiente Manus. O código e os testes exclusivos desse starter que o MVP da Njinga não usa (menus, HUD, áudio, i18n EN/zh-CN e os testes que os cobriam) foram removidos do repositório — a cena principal (`scenes/game.tscn`) carrega apenas `scripts/njinga_game.gd`/`scripts/njinga_player.gd`, sem autoloads. Os **ficheiros de arte/áudio/fontes** do starter (`assets/template/cat/*`, `assets/template/audio/*`, as fontes CJK) permanecem no repositório por decisão documentada em [`CREDITS.md`](CREDITS.md), mas não são usados pelo jogo — o MVP desenha tudo via `_draw()` procedural. `data/i18n/pt-AO.json` também não está ligado a nenhum código (o texto de cada nível vive directamente nos ficheiros de `data/levels/`); mantém-se como referência textual, não como fonte de dados activa.

## Desenvolvimento

Requisitos: [Godot 4.7](https://godotengine.org/) (com suporte a exportação Web) e [pnpm](https://pnpm.io/) para os scripts auxiliares em Node.

```bash
# exportar a build Web para dist/
pnpm run export

# correr todos os testes (GDScript + Node)
pnpm run test:all

# testes individuais — ver scripts em package.json
pnpm test                 # smoke: a cena principal arranca e carrega o conteúdo
pnpm run test:content     # valida o esquema de data/levels/*.json e data/diplomacy/*.json
pnpm run test:gameplay    # iniciar nível, recolher item, chegar à meta, desbloquear o próximo
pnpm run test:diplomacy   # a meta de um nível com diplomacia abre a conversa, não termina a fase
pnpm run test:save        # ronda completa de save_progress()/load_save() entre duas instâncias
pnpm run test:checks      # testes Node das ferramentas de verificação de export
```

Alguns scripts de `package.json` (`dev`, `build`, `preview:build`, `doctor`, `inspect`, `assets:report`) invocam ferramentas internas do ambiente Manus (`scripts/manus/runtime-command.cjs`) e não correm fora dessa plataforma.

## Licença

Ainda não foi definida uma licença para este repositório. O conteúdo histórico segue as referências listadas em [`CREDITS.md`](CREDITS.md).
