# Roblox Hub

Script em Luau para Roblox com interface gráfica, feito para executores. Reúne **Fly**, **ESP**, **Fling** e **Anti-Fling** em um menu único, arrastável e minimizável.

<!-- Coloque um print em assets/screenshot.png e descomente a linha abaixo -->
<!-- ![Menu](assets/screenshot.png) -->

## Funções

| Função | O que faz |
|---|---|
| **Fly** | Voa na direção da câmera (W/A/S/D, Espaço sobe, Ctrl esquerdo desce). Velocidade ajustável de 10 a 300. |
| **ESP** | Contorno vermelho visível através das paredes, com nome e distância (em studs) de cada jogador. |
| **Fling** | Escolha um jogador na lista e arremesse. Sem seleção, usa o jogador mais próximo. Depois do fling você volta para a posição original. |
| **Anti-Fling** | Desativa a colisão dos outros jogadores com você e zera sua velocidade caso ela dispare de repente. |

## Atalhos

| Tecla | Ação |
|---|---|
| `F` | Fly liga/desliga |
| `G` | Fling no alvo selecionado (ou no mais próximo) |
| `T` | ESP liga/desliga |
| `Y` | Anti-Fling liga/desliga |
| `↑` / `↓` | Aumenta / diminui velocidade do fly (só nos scripts standalone) |
| `RightShift` | Esconde/mostra o menu |

## Como usar

1. Abra o Roblox e entre no jogo desejado.
2. Abra seu executor e faça o *Attach*.
3. Cole o conteúdo de [`hub.lua`](hub.lua) e clique em **Run**.

Ou carregue direto do GitHub (troque `SEU_USUARIO` e `SEU_REPO`):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/hub.lua"))()
```

## Estrutura

```
roblox-hub/
├── hub.lua                    # script principal com interface
├── scripts/
│   ├── fly.lua                # só o fly, sem interface
│   └── fly_fling_esp.lua      # fly + fling + ESP por teclas, sem interface
├── assets/                    # prints e imagens
├── LICENSE
└── README.md
```

## Compatibilidade

- Testado com a estrutura do **Potassium**. Deve funcionar em executores que suportem `gethui()` ou acesso ao `CoreGui` (o script usa `gethui()` e cai para `CoreGui` se não existir).
- O Fling depende da física do jogo. Em jogos com colisão entre jogadores desativada, ele pode não ter efeito.
- Jogos com anti-cheat forte podem detectar fly, fling e velocidade anormal.

## Aviso

Este projeto é apenas para fins educacionais e de estudo de Luau. Usar executores em jogos de terceiros viola os Termos de Uso do Roblox e pode resultar em banimento da conta. Use por sua conta e risco, de preferência em jogos seus ou servidores privados, e não use o Fling para atrapalhar a partida de outras pessoas. Este projeto não tem qualquer afiliação com a Roblox Corporation.

## Licença

Distribuído sob a licença MIT. Veja [`LICENSE`](LICENSE).
