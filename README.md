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
project.godot          Configuração do projecto Godot
scenes/game.tscn        Cena de entrada (NjingaGame)
scripts/njinga_game.gd  Router de menus, níveis, HUD e persistência
scripts/njinga_player.gd  Movimento e sinais de acções do jogador
data/levels/            Geometria, objectivos e cartões de cada nível (nivel1–6)
data/diplomacy/         Falas e perfis das cenas de diplomacia
data/i18n/pt-AO.json     Texto principal da interface em português
localization/           Traduções EN / zh-CN herdadas do template base
assets/                  Arte, tipografia e áudio
docs/                    Documentação de implementação e do template base
test/                    Testes de regressão em GDScript e Node
web-build/               Build Web/WASM exportada, pronta a publicar
```

O projecto partiu de um starter Godot de plataformas (género "cat platformer") disponibilizado pelo ambiente Manus. Os ficheiros desse starter que não são usados pelo MVP da Njinga (por exemplo `scripts/game.gd`, `scripts/entities.gd`, `scripts/yarn_ball.gd` e `docs/GAME_PRODUCTION_PLAYBOOK.md`) permanecem no repositório por referência, mas a cena principal (`scenes/game.tscn`) carrega apenas `scripts/njinga_game.gd`. Ver [`CREDITS.md`](CREDITS.md) para as fontes históricas e a proveniência da arte.

## Desenvolvimento

Requisitos: [Godot 4.7](https://godotengine.org/) (com suporte a exportação Web) e [pnpm](https://pnpm.io/) para os scripts auxiliares em Node.

```bash
# exportar a build Web para dist/
pnpm run export

# correr o smoke test principal (headless)
pnpm test

# outros testes específicos — ver scripts em package.json
pnpm run test:contract
pnpm run test:terrain
```

Alguns scripts de `package.json` (`dev`, `build`, `preview:build`, `doctor`, `inspect`, `assets:report`) invocam ferramentas internas do ambiente Manus (`scripts/manus/runtime-command.cjs`) e não correm fora dessa plataforma.

## Licença

Ainda não foi definida uma licença para este repositório. O conteúdo histórico segue as referências listadas em [`CREDITS.md`](CREDITS.md).
