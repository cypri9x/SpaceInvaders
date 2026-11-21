# ICMC Invaders

Jogo de nave em Assembly para o processador ICMC, inspirado em Space Invaders e Galaga. O jogador move a nave pela parte inferior da tela, atira nos inimigos e usa uma onda de choque para ajudar a cumprir a meta de cada fase. O menu traz uma referência ao ICMC/USP.

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
| A / D, durante a partida | Iniciar um deslize curto para a esquerda ou para a direita. |
| X | Frear o deslize imediatamente. |
| Espaço | Atirar. |
| U | Usar a onda de choque quando a barra estiver cheia. |
| P | Pausar ou continuar. |
| 1 / 2 | Escolher ritmo calmo ou normal. |
| S, durante a partida | Voltar à seleção de fases. |
| Enter, no resultado | Avançar após vencer ou tentar novamente após perder. |
| R, no resultado | Reiniciar a tentativa na fase atual; no infinito, voltar à primeira onda. |

Cada toque em A/D move uma casa na hora e completa até duas casas após breves intervalos. No simulador original, segurar estende o deslize conforme a repetição do teclado. Uma adaptação local do simulador também pode informar diretamente quando A/D são segurados ou soltos. O jogo reconhece os códigos 128 e 129 para manter o movimento e 130 para completar o deslize e parar. A campanha abre no ritmo normal, e a tecla 1 dá mais tempo para mirar e desviar.

## Fases e modo infinito

| Fase | Padrão | Meta |
| --- | --- | --- |
| Linha | Três inimigos em patrulha horizontal. | 9 acertos |
| Arco | Quatro drones com as pontas abaixo do centro. | 12 acertos |
| Escada | Cinco drones em diagonal. | 15 acertos |
| Patrulha | Seis drones em duas fileiras de três. | 18 acertos |
| Em V | Sete drones em uma formação em V com reforços atrás. | 21 acertos |
| Esquadra | Oito drones em duas fileiras de quatro. | 40 acertos |
| Chefão duplo | Duas naves patrulham alturas diferentes e se revezam para disparar. | 18 pontos de dano por nave |

Nas seis primeiras fases, os drones cruzam a arena juntos. Às vezes, a frota faz uma pausa curta e inverte a direção no meio da tela. A descida de uma linha só acontece nas laterais. Se a frota alcançar a base, ela volta ao topo e causa um único dano.

Os drones abatidos ficam fora da formação. Ao derrubar o último, entra uma nova frota pelo topo. Os acertos acumulam até atingir a meta da fase.

Cada fase da campanha começa com três vidas. Os inimigos se revezam para disparar e esperam menos nas fases mais intensas. Uma luz amarela mostra quem vai atirar e marca a coluna do jogador perto da base. O laser segue até essa coluna. Saia da marca para desviar. A pontuação continua ao avançar de fase.

O fundo muda a cada fase. Cinturão de asteroides, planeta com anéis, nebulosa, estação orbital, cometas, lua partida e portais do chefão usam blocos desenhados no charmap.

No modo infinito, as seis formações comuns se repetem, sem o chefe. A próxima onda começa automaticamente, conservando vidas e pontos. A velocidade aumenta até a onda 16; o indicador de onda para em 99. Escolher 1 ou 2 altera manualmente o ritmo da onda atual.

## Pontuação, bônus e onda de choque

Acertos com intervalo de até 45 quadros aumentam o combo até **X5**. Cada acerto rende de 10 a 50 pontos. Receber dano ou deixar o prazo acabar zera o combo. O recorde fica na memória durante a execução e é perdido ao reiniciar a CPU ou fechar o simulador. A pontuação é limitada a 60.000 para manter as contas dentro dos 16 bits.

A cada quatro acertos pode cair um bônus. Só existe um caindo por vez, e os tipos alternam:

- **D:** tiro duplo durante 180 quadros.
- **E:** escudo que absorve um dano de laser ou de inimigo que passou.
- **U:** recupera dois segmentos da onda de choque.

Para coletar, encoste com qualquer parte da nave. A cabine fica verde com o escudo ativo. O tiro duplo dispara pelas duas pontas da nave. Os bônus e efeitos temporários são reiniciados ao mudar de fase.

A onda começa vazia e consome seis segmentos. Dois acertos de tiro normal recuperam um segmento. O bônus de energia recupera dois. Ao continuar para a fase seguinte, a carga acumulada é mantida. A onda causa um ponto de dano a cada nave do chefão.

## Organização do código

As posições da tela são calculadas por `linha * 40 + coluna`. O início de `JOGO.ASM` guarda os textos, as variáveis e as tabelas das fases. Depois vêm os menus e o laço principal da partida. As rotinas seguintes cuidam do movimento, dos tiros, das colisões, da onda de choque, da pontuação, dos bônus e do chefe.

Os inimigos usam vetores de até oito posições. Os tiros do jogador têm 32 espaços. Os dois chefes usam os primeiros espaços de inimigo e têm vida e direção independentes. A leitura do teclado ocorre entre as atualizações dos quadros, e a pausa não avança os temporizadores.

Cada desenho do charmap usa blocos de 8 × 8 pixels. Os códigos de 1 a 28 guardam os sprites da partida. Os cenários usam 29 a 31, 96 a 123 e 125. O texto do jogo usa letras maiúsculas e números. A nave e os drones juntam três blocos na horizontal. O chefe junta sete. O Assembly envia o código do bloco e a cor pela instrução `OUTCHAR`. O fundo é desenhado antes dos objetos da arena.

## Verificação e referência do simulador

O jogo foi montado com o montador original e passou em 32 testes locais que executam as instruções do arquivo compilado. Eles verificam a navegação em Configurações e Créditos, os controles, as colisões, a troca de frotas, a vida independente dos chefes e a recarga da ultimate. O ritmo em tempo real depende do simulador gráfico.

O processador e as ferramentas da disciplina são do projeto [Processador-ICMC, de Eduardo Valle Simões](https://github.com/simoesusp/Processador-ICMC). O arquivo C acompanha a adaptação para Windows que já estava no material local. Os comentários e a identificação existentes nesse fonte foram preservados.
