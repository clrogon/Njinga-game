# Política de Segurança

> **EN**: Security policy for Njinga-game. This is a static, client-only browser game with no backend, no accounts, and no payment processing — see "Superfície de ataque" below for what that does and doesn't cover.

## Superfície de ataque

Njinga-game não tem backend, não tem contas de utilizador, não processa pagamentos e não recolhe dados pessoais. A build Web distribuída é um conjunto de ficheiros estáticos (`.html`, `.wasm`, `.pck`) servidos por quem decidir hospedá-los — não há servidor próprio nem API.

O único dado persistido é o progresso do jogo (`njinga_save.json`), guardado localmente via `user://` (Godot) ou `localStorage` (navegador) — nunca enviado para fora da máquina de quem joga. Não há informação sensível neste ficheiro: nível desbloqueado, cartões recolhidos, nzimbu, preferências de teclas.

Dado isto, o risco de segurança real limita-se a:
- Vulnerabilidades no motor Godot/exportação Web em si (fora do controlo deste repositório — ver [avisos de segurança do Godot](https://godotengine.org/security/))
- Como o site estático é servido (cabeçalhos, HTTPS, etc. — responsabilidade de quem hospeda)
- Dependências de build (`package.json`/`pnpm-lock.yaml`) desactualizadas

## Reportar uma vulnerabilidade

Se encontrares algo que se enquadre no acima (ou qualquer coisa que te pareça um problema de segurança genuíno, não apenas um bug de gameplay):

1. **Não** abras uma issue pública.
2. Usa a funcionalidade de [GitHub Security Advisories](https://github.com/clrogon/Njinga-game/security/advisories/new) deste repositório, ou contacta directamente o proprietário do repositório via GitHub.

Este é um projecto de pequena escala sem equipa de segurança dedicada — não há SLA formal de resposta, mas qualquer relato genuíno será investigado.

## Dependências

`pnpm run test:all` não inclui uma auditoria de dependências. Se quiseres verificar as dependências Node, `pnpm audit` cobre o que está em `package-lock.json`/`pnpm-lock.yaml`; não há equivalente para o próprio motor Godot além de manter a versão actualizada.
