# Njinga: Rainha do Ndongo e da Matamba — plano de implementação

## Direcção

MVP de plataforma 2D educativa para navegador, em português PT-AO com ortografia pré-AO90. A campanha condensa os seis níveis da proposta numa sequência curta, jogável e desbloqueável. A arte é **pixel-art 16-bit procedural**, desenhada com formas Godot a 480×270, para manter a lógica independente de futuros sprites.

### Movimento visual
- **Referência:** pixel art de 16 bits com composição de diorama lateral.
- **Princípios:** leitura imediata, contrastes quentes/frios, formas simples mas específicas por fase, informação histórica sempre legível.
- **Paleta:** terra ocre/vermelha para a memória e a resistência; verdes do Kwanza para vida e refúgio; azul atlântico para Luanda e alianças.
- **Layout:** percurso horizontal com camadas de montanhas, árvores e arquitectura, HUD compacto em placas de tecido.
- **Motivos:** padrões geométricos de tecido em faixas, búzios nzimbu, tambores ngoma como checkpoints.
- **Interacção:** cada acção ensina algo: recolher cartões abre a Crónica; diplomacia altera Prestígio; furtividade recompensa leitura do cone; combate é estilizado e secundário.
- **Animação:** bob de caminhada, salto com altura variável, pulsação suave de coleccionáveis, cones de visão estáveis e feedback textual; sem sangue.
- **Tipografia:** fontes de interface do template Godot, com hierarquia forte e texto curto para leitura a partir dos 8 anos.
- **Essência:** uma aventura histórica acessível que transforma a inteligência política de Njinga em mecânicas jogáveis.
- **Voz:** clara, respeitosa, directa. Exemplos: “A história também se atravessa com atenção.” / “Escolhe as palavras — o Prestígio abre caminhos.”

## Estrutura

- `scripts/njinga_game.gd`: router de menus, níveis, HUD, persistência e desenho procedural do mundo.
- `scripts/njinga_player.gd`: movimento, coyote time, jump buffer, salto variável e sinais de acções.
- `data/levels/nivel1.json` … `nivel6.json`: geometria, objectivos, entidades e cartões históricos.
- `data/diplomacy/*.json`: falas e perfis de respostas usados pelo minijogo de diplomacia.
- `data/i18n/pt-AO.json`: cópia textual principal fora da lógica; os JSON de níveis também guardam o texto histórico específico.
- `scenes/game.tscn`: cena de entrada mínima, sem dependência do antigo demo Yarn.
- `CREDITS.md`: registo de fontes históricas e nota de que arte/efeitos do MVP são código original.

## Escopo fechado do MVP

Inclui seis fases curtas; plataforma clássica; nzimbu; três cartões por nível; ngoma/checkpoint; vidas e manto; diplomacia nos níveis 2, 5 e 6; cones de visão e perseguição no nível 3; machado no nível 3; arco, flechas e aljavas no nível 4; libertação de cativos; menu, selecção/desbloqueio, Crónica, Para pais e professores, créditos, controlos de teclado e botões tácteis; localStorage/Web Storage quando disponível e fallback `user://`.

Não inclui contas, servidor, compras, multijogador, vozes gravadas, cronómetro por omissão, ou acontecimentos excluídos pela proposta.
