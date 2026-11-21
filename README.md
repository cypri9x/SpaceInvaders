# ICMC Invaders

Jogo de nave em Assembly para o processador ICMC, inspirado em Space Invaders e Galaga. O jogador desliza pela parte inferior da tela, atira nos inimigos e usa uma onda de choque para ajudar a cumprir a meta de cada fase. O menu traz uma referência ao ICMC/USP.

## Integrantes

- Gustavo Cypriano
- Adriana Rodrigues
- Mariana Alvares
- Davi de Alcantara

## Vídeo de apresentação

**Pendente de gravação e publicação.** O link do YouTube ou do Google Drive será colocado nesta seção depois da gravação. O vídeo não será enviado para o repositório.

Além do vídeo, todos os integrantes precisam apresentar o trabalho pessoalmente em sala, conforme a orientação do professor.

## Arquivos

| Arquivo | Conteúdo |
| --- | --- |
| [JOGO.ASM](JOGO.ASM) | Código completo do jogo, com comentários sobre as variáveis e as rotinas. |
| [CHARMAP.MIF](CHARMAP.MIF) | Mapa com os desenhos da nave, dos inimigos, dos tiros, dos bônus, da onda de choque e das estrelas. |
| [simple_simulator_template.c](simple_simulator_template.c) | Arquivo C inteiro do Simple Simulator recebido com o material, sem alterações. |

O executável do simulador, o editor, as bibliotecas e os arquivos gerados pela montagem não fazem parte desta entrega.

## Como executar

Use o montador e o simulador gráfico do processador ICMC disponibilizados para a disciplina.

1. Coloque `JOGO.ASM` e `CHARMAP.MIF` na pasta em que vai executar as ferramentas.
2. Monte o jogo:

   ```text
   Montador.exe JOGO.ASM JOGO.mif
   ```

3. Abra o programa gerado no simulador gráfico:

   ```text
   simulador.exe JOGO.mif CHARMAP.MIF
   ```

4. Use **Home** para alternar entre execução automática e manual, se necessário.

O arquivo C incluído é a versão didática em console do Simple Simulator. Nela, `OUTCHAR` imprime caracteres no terminal; o jogo usa o simulador gráfico para exibir posições e cores na grade de 40 × 30. O fonte C foi mantido como recebido para acompanhar a entrega, e não deve ser confundido com o executável gráfico usado para jogar.

## Controles

| Tecla | Ação |
| --- | --- |
| W / S e Enter | Escolher e confirmar uma opção nos menus. |
| A, na seleção de fases | Voltar ao menu principal. |
| I, na seleção de fases | Iniciar o modo infinito. |
| A / D, durante a partida | Deslizar para a esquerda ou para a direita. |
| X | Frear a nave. As bordas também interrompem o movimento. |
| Espaço | Atirar. |
| U | Usar a onda de choque quando a barra estiver cheia. |
| P | Pausar ou continuar. |
| 1 / 2 | Escolher ritmo calmo ou normal. |
| S, durante a partida | Voltar à seleção de fases. |
| Enter, no resultado | Avançar após vencer ou tentar novamente após perder. |
| R, no resultado | Reiniciar a tentativa na fase atual; no infinito, voltar à primeira onda. |

O teclado do simulador informa a tecla pressionada, mas não avisa quando ela foi solta. Por isso A/D iniciam o movimento contínuo, e X para a nave.

A nave dá um passo no primeiro toque e ao inverter a direção. A campanha abre no ritmo normal, e a tecla 1 dá mais tempo para mirar e desviar.

## Fases e modo infinito

| Fase | Padrão | Meta |
| --- | --- | --- |
| Linha | Três inimigos em patrulha horizontal. | 9 acertos |
| Chuva | Quatro inimigos em queda vertical. | 12 acertos |
| Zigue-zague | Cinco inimigos com passos horizontais duplos. | 15 acertos |
| Caçadoras | Seis inimigos que seguem a coluna da nave. | 18 acertos |
| Em V | Sete inimigos que se movem juntos e descem ao virar. | 21 acertos |
| Mergulho | Oito inimigos que avançam na direção do jogador. | 40 acertos |
| Chefão | Nave maior que patrulha o topo e dispara para baixo. | 20 pontos de dano |

Cada fase da campanha começa com três vidas. Os inimigos se revezam para disparar. Uma luz amarela indica quem vai atirar, e o laser vermelho desce na coluna de onde saiu. Você perde uma vida se o laser atingir a nave ou se um inimigo atravessar a arena. A pontuação continua ao avançar de fase.

No modo infinito, as seis formações comuns se repetem, sem o chefe. A próxima onda começa automaticamente, conservando vidas e pontos. A velocidade aumenta até a onda 16; o indicador de onda para em 99. Escolher 1 ou 2 altera manualmente o ritmo da onda atual.

## Pontuação, bônus e onda de choque

Acertos com intervalo de até 45 quadros aumentam o combo até **X5**. Cada acerto rende de 10 a 50 pontos. Receber dano ou deixar o prazo acabar zera o combo. O recorde fica na memória durante a execução e é perdido ao reiniciar a CPU ou fechar o simulador. A pontuação é limitada a 60.000 para manter as contas dentro dos 16 bits.

A cada quatro acertos pode cair um bônus. Só existe um caindo por vez, e os tipos alternam:

- **D:** tiro duplo durante 180 quadros.
- **E:** escudo que absorve um dano de laser ou de inimigo que passou.
- **U:** recarga completa da onda de choque.

Para coletar, encoste com qualquer parte da nave. O placar mostra `D:1` e `E:1` quando os efeitos estão ativos. Os bônus e efeitos temporários são reiniciados ao mudar de fase.

A onda começa carregada e consome os seis segmentos da barra. A energia volta com o tempo e com acertos de tiros normais. Cada inimigo, identificado pelo seu espaço no vetor, pode receber um acerto por onda. Contra o chefe, cada onda causa um ponto de dano. Ela não recarrega a própria barra.

## Organização do código

As posições da tela são calculadas por `linha * 40 + coluna`. O início de `JOGO.ASM` guarda os textos, as variáveis e as tabelas das fases. Depois vêm os menus e o laço principal da partida. As rotinas seguintes cuidam do movimento, dos tiros, das colisões, da onda de choque, da pontuação, dos bônus e do chefe.

Os inimigos usam vetores de até oito posições; os tiros do jogador têm 32 espaços. O chefe usa o primeiro espaço de inimigo e possui uma rotina própria de movimento. A leitura do teclado ocorre entre as atualizações dos quadros, e a pausa não avança os temporizadores.

Cada desenho do charmap usa blocos de 8 × 8 pixels. Os códigos de 1 a 28 guardam os desenhos do jogo, e as letras e os números continuam disponíveis para o placar e os menus. A nave e os drones juntam três blocos na horizontal. O chefe junta sete. O Assembly envia o código do bloco e a cor pela instrução `OUTCHAR`. As estrelas alternam o brilho em grupos e são desenhadas antes dos objetos da arena.

## Verificação e referência do simulador

Na preparação da entrega, o jogo foi montado com o montador original e passou em 23 testes locais que executam as instruções do arquivo compilado. Eles verificam, entre outros casos, colisões, limites da tela, bônus, pausa, avanço das fases e o aviso e trajeto do laser inimigo. O ritmo em tempo real depende do simulador gráfico.

O processador e as ferramentas da disciplina são do projeto [Processador-ICMC, de Eduardo Valle Simões](https://github.com/simoesusp/Processador-ICMC). O arquivo C acompanha a adaptação para Windows que já estava no material local. Os comentários e a identificação existentes nesse fonte foram preservados.
