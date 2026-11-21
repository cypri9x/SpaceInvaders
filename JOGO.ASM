; ICMC INVADERS - arcade de naves, campanha e sobrevivencia.
; Assembly do processador ICMC. A tela tem 40 colunas e 30 linhas.
; Uma posicao de tela e calculada por linha * 40 + coluna, de 0 a 1199.
; Por isso somar 40 desce uma linha, subtrair 40 sobe e somar 1 vai a direita.
;
; Organizacao do arquivo:
; - Textos, variaveis e tabelas das fases.
; - Menu, selecao e laco principal da partida.
; - Movimento, tiros, onda, colisoes e telas de resultado.
; - Pontuacao, bonus, modo infinito e chefe.
;
; Nos loops de inimigos, r4 e o indice e r5 aponta para alvos[r4].
; Nos loops de tiros, r6 e o indice e r7 aponta para tiros[r6].
; Os demais registradores servem para contas e comparacoes temporarias.
; Rotinas que precisam conservar um valor usam push/pop antes de retornar.
;
; O teclado entrega o codigo ASCII da tecla ou 255 quando nao ha entrada.
; Ele nao informa que a tecla foi solta. A/D iniciam o deslize e X freia.
; P pausa, espaco atira e U usa a onda quando a barra esta cheia.

; Pula os dados abaixo e comeca a executar na rotina main.
jmp main

; textos da tela principal
linha_topo:       string "+--------------------------------------+"
linha_lado:       string "|                                      |"
titulo:           string "ICMC INVADERS"
subtitulo:        string "ARCADE - USP"
assinatura:       string "INSTITUTO DE CIENCIAS MATEMATICAS"
divisor:          string "--------[  SELECIONE  ]--------"
ajuda:            string "W/S: MOVER   ENTER: ESCOLHER"

opcao_jogar:      string "         JOGAR          "
opcao_config:     string "     CONFIGURACOES      "
opcao_creditos:   string "        CREDITOS        "
opcao_sair:       string "          SAIR          "

sel_jogar:        string "      >> JOGAR <<       "
sel_config:       string "  >> CONFIGURACOES <<   "
sel_creditos:     string "     >> CREDITOS <<     "
sel_sair:         string "       >> SAIR <<       "

; textos das outras telas
msg_inicio:       string "ENTER PARA INICIAR"
voltar_enter:     string "PRESSIONE ENTER PARA VOLTAR"

titulo_config:    string "CONFIGURACOES"
config_controle1: string "A/D: DESLIZAR   X: FREAR"
config_controle2: string "ESPACO: TIRO   U: ULTIMATE"
config_mensagem:  string "P: PAUSA  1/2: RITMO  S: FASES"

titulo_creditos:  string "CREDITOS"
nome_1:           string "Gustavo Cypriano"
nome_2:           string "Adriana Rodrigues"
nome_3:           string "Mariana Alvares"
nome_4:           string "Davi de Alcantara"

titulo_sair:      string "ATE A PROXIMA!"
msg_sair:         string "ICMC USP"

; estado do menu
selecao:          var #1 ; opcao destacada, de 0 a 3
contador_anim:    var #1
nave_direita_x:   var #1
nave_esquerda_x:  var #1

; Seis formacoes (3..8 inimigos) e um chefe; ultimate em onda de choque.
nave_pos: var #1 ; posicao do centro da nave, na linha 26
; Estes tres vetores ficam juntos: a inicializacao limpa 24 posicoes.
alvos: var #8 ; centro de cada inimigo; o chefe usa apenas o indice 0
direcoes: var #8 ; 0 = esquerda, 1 = direita
explosao_protecao: var #8 ; protege inimigos que acabaram de reaparecer
; A inicializacao dos tiros tambem depende destes dois vetores juntos.
tiros: var #32 ; posicao do projetil; zero indica um espaco livre
tiro_direcoes: var #32 ; 0 = vertical, 1/2 = diagonais para cima, 6/7 = para baixo
nave_direcao: var #1 ; 0 = parada, 1 = esquerda, 2 = direita
nave_tempo: var #1 ; contador separado para o deslize
nave_intervalo: var #1 ; intervalo entre passos depois do primeiro toque
estrelas_tempo: var #1
estrelas_fase: var #1
; As estrelas ficam entre o placar e a nave, longe da moldura.
estrelas_pos: var #32
static estrelas_pos + #0, #182
static estrelas_pos + #1, #207
static estrelas_pos + #2, #229
static estrelas_pos + #3, #267
static estrelas_pos + #4, #303
static estrelas_pos + #5, #352
static estrelas_pos + #6, #375
static estrelas_pos + #7, #403
static estrelas_pos + #8, #432
static estrelas_pos + #9, #455
static estrelas_pos + #10, #487
static estrelas_pos + #11, #513
static estrelas_pos + #12, #548
static estrelas_pos + #13, #584
static estrelas_pos + #14, #597
static estrelas_pos + #15, #631
static estrelas_pos + #16, #665
static estrelas_pos + #17, #678
static estrelas_pos + #18, #696
static estrelas_pos + #19, #725
static estrelas_pos + #20, #751
static estrelas_pos + #21, #790
static estrelas_pos + #22, #809
static estrelas_pos + #23, #838
static estrelas_pos + #24, #853
static estrelas_pos + #25, #881
static estrelas_pos + #26, #905
static estrelas_pos + #27, #937
static estrelas_pos + #28, #956
static estrelas_pos + #29, #983
static estrelas_pos + #30, #1006
static estrelas_pos + #31, #1024
energia: var #1 ; carga da onda: de 0 a 6 segmentos
energia_tempo: var #1
vitoria_tempo: var #1
onda_linha: var #1 ; primeira linha do efeito; zero significa que nao esta ativo
onda_atingidos: var #8 ; impede contar o mesmo slot duas vezes na mesma onda
fase_atual: var #1 ; numero de 1 a 7; as tabelas usam fase_atual - 1
quantidade_inimigos: var #1 ; limita os loops para nao percorrer slots inativos
meta_acertos: var #1 ; no chefe, corresponde aos seus 20 pontos de vida
nivel_selecao: var #1
passo_inimigo: var #1
cor_inimigo: var #1
grupo_coluna: var #1
grupo_direcao: var #1
grupo_delta: var #1 ; 1 = direita, 2 = esquerda
grupo_virou: var #1 ; a formacao desce quando este valor e 1
acertos: var #1 ; progresso da fase; separado da pontuacao acumulada
vidas: var #1
relogio: var #1 ; conta passagens pelo laco, sem bloquear a leitura do teclado
intervalo: var #1 ; quantidade de passagens antes de atualizar um quadro
alvo_tempo: var #1
recarga: var #1 ; quadros restantes ate poder disparar outra vez
proxima_coluna: var #1
resultado: var #1 ; 0 = jogando, 1 = venceu, 2 = perdeu
jogo_nome: string "ICMC INVADERS"
jogo_objetivo: string "CUMPRA A META. VOCE TEM 3 VIDAS."
intro_naves: string "NAVES NA TELA:"
intro_meta: string "META:"
jogo_controles: string "A/D: DESLIZAR  X: FREAR  S: FASES"
jogo_armas: string "ESPACO: TIRO  U: ONDA  P: PAUSA"
jogo_ritmo: string "1: CALMO   2: NORMAL"
jogo_acertos: string "ACERTOS:"
jogo_meta: string "/"
jogo_vidas: string "VIDAS:"
jogo_vitoria: string "FASE CONCLUIDA!"
jogo_final: string "BOA! O ICMC ESTA A SALVO!"
jogo_derrota: string "AS NAVES PASSARAM! TENTE DE NOVO"
jogo_repetir: string "ENTER: CONTINUAR   R: REPETIR"
jogo_voltar: string "S: SELECAO DE FASES"
ultimate_label: string "U:"
ultimate_pronta: string "PRONTA"
ultimate_vazia: string "      "
explosao_direcoes: var #4
static explosao_direcoes + #0, #1
static explosao_direcoes + #1, #2
static explosao_direcoes + #2, #6
static explosao_direcoes + #3, #7


; Mesma navegacao do menu: W/S e Enter; A retorna.
niveis_titulo: string "SELECIONE A FASE"
niveis_ajuda: string "W/S: MOVER  ENTER: JOGAR  A: MENU"
nivel_1: string "LINHA (3 NAVES)"
nivel_2: string "ARCO (4 NAVES)"
nivel_3: string "ESCADA (5 NAVES)"
nivel_4: string "PATRULHA (6 NAVES)"
nivel_5: string "EM V (7 NAVES)"
nivel_6: string "ESQUADRA (8 NAVES)"
nivel_7: string "CHEFAO (20 ACERTOS)"
niveis_lista: var #7
static niveis_lista + #0, #nivel_1
static niveis_lista + #1, #nivel_2
static niveis_lista + #2, #nivel_3
static niveis_lista + #3, #nivel_4
static niveis_lista + #4, #nivel_5
static niveis_lista + #5, #nivel_6
static niveis_lista + #6, #nivel_7


; Cores, formas iniciais e intervalo em quadros de cada frota.
fase_dica_1: string "ATIRE NOS DRONES EM LINHA."
fase_dica_2: string "A FROTA DESCE QUANDO MUDA DE LADO."
fase_dica_3: string "USE OS ESPACOS PARA DESVIAR."
fase_dica_4: string "FREIE COM X PARA MIRAR NA FROTA."
fase_dica_5: string "A FORMACAO EM V AVANCA JUNTA."
fase_dica_6: string "MIRE NOS ESPACOS ENTRE OS LASERS."
fase_dica_7: string "DESVIE DOS TIROS. U ATINGE O CHEFE."
fase_dicas: var #7
static fase_dicas + #0, #fase_dica_1
static fase_dicas + #1, #fase_dica_2
static fase_dicas + #2, #fase_dica_3
static fase_dicas + #3, #fase_dica_4
static fase_dicas + #4, #fase_dica_5
static fase_dicas + #5, #fase_dica_6
static fase_dicas + #6, #fase_dica_7
fase_cores: var #7
static fase_cores + #0, #512
static fase_cores + #1, #3584
static fase_cores + #2, #3328
static fase_cores + #3, #2304
static fase_cores + #4, #2816
static fase_cores + #5, #2560
static fase_cores + #6, #2304
fase_passos: var #7
static fase_passos + #0, #7
static fase_passos + #1, #6
static fase_passos + #2, #6
static fase_passos + #3, #6
static fase_passos + #4, #5
static fase_passos + #5, #4
static fase_passos + #6, #2
; Cada fase ocupa oito entradas, mesmo quando usa menos de oito inimigos.
; Para achar a posicao inicial: (fase_atual - 1) * 8 + indice do inimigo.
fase_formacoes: var #56
static fase_formacoes + #0, #250
static fase_formacoes + #1, #260
static fase_formacoes + #2, #270
static fase_formacoes + #3, #0
static fase_formacoes + #4, #0
static fase_formacoes + #5, #0
static fase_formacoes + #6, #0
static fase_formacoes + #7, #0
static fase_formacoes + #8, #290
static fase_formacoes + #9, #216
static fase_formacoes + #10, #224
static fase_formacoes + #11, #310
static fase_formacoes + #12, #0
static fase_formacoes + #13, #0
static fase_formacoes + #14, #0
static fase_formacoes + #15, #0
static fase_formacoes + #16, #210
static fase_formacoes + #17, #255
static fase_formacoes + #18, #300
static fase_formacoes + #19, #345
static fase_formacoes + #20, #390
static fase_formacoes + #21, #0
static fase_formacoes + #22, #0
static fase_formacoes + #23, #0
static fase_formacoes + #24, #210
static fase_formacoes + #25, #220
static fase_formacoes + #26, #230
static fase_formacoes + #27, #330
static fase_formacoes + #28, #340
static fase_formacoes + #29, #350
static fase_formacoes + #30, #0
static fase_formacoes + #31, #0
static fase_formacoes + #32, #210
static fase_formacoes + #33, #255
static fase_formacoes + #34, #300
static fase_formacoes + #35, #265
static fase_formacoes + #36, #230
static fase_formacoes + #37, #335
static fase_formacoes + #38, #345
static fase_formacoes + #39, #0
static fase_formacoes + #40, #210
static fase_formacoes + #41, #216
static fase_formacoes + #42, #224
static fase_formacoes + #43, #230
static fase_formacoes + #44, #330
static fase_formacoes + #45, #336
static fase_formacoes + #46, #344
static fase_formacoes + #47, #350
static fase_formacoes + #48, #300


; Estado arcade. O recorde dura enquanto o simulador estiver aberto.
pontos: var #1 ; soma das fases desta tentativa, limitada a 60000
recorde: var #1 ; nao e gravado em arquivo; se perde ao reiniciar a CPU
combo: var #1 ; multiplicador de 0 a 5
combo_tempo: var #1 ; prazo, em quadros, para manter o combo
modo_infinito: var #1 ; 0 = campanha, 1 = ondas sem fim
onda_numero: var #1 ; contador do modo infinito, limitado a 99
vidas_reserva: var #1 ; leva as vidas restantes para a proxima onda do infinito
bonus_pos: var #1 ; zero quando nao existe bonus caindo
bonus_tipo: var #1 ; 1 = tiro duplo, 2 = escudo, 3 = carga da onda
bonus_ciclo: var #1
bonus_contador: var #1
duplo_tempo: var #1 ; quadros restantes do tiro duplo
escudo: var #1 ; 0 = sem escudo, 1 = absorve o proximo dano
tiro_inimigo: var #1 ; um laser hostil de cada vez; zero quando nao existe
tiro_inimigo_tempo: var #1
atirador: var #1 ; indice do inimigo que vai disparar
aviso_disparo: var #1 ; posicao da luz antes do disparo
rajada_pos: var #1
rajada_restante: var #1
infinito_ajuda: string "I: MODO INFINITO"
hud_pontos: string "PTS:"
hud_combo: string "X"
hud_duplo: string "D:"
hud_escudo: string "E:"
hud_pausa: string "PAUSADO - P PARA CONTINUAR"
hud_onda: string "ONDA:"
hud_fase: string "FASE:"
linha_hud_vazia: string "                                  "
hud_recorde: string "RECORDE:"
hud_bonus: string "D: DUPLO  E: ESCUDO  U: ENERGIA"
ritmo_curto: string "1/2: RITMO"
; Sequencias de codigos do charmap. Zero encerra a rotina imprime_str.
drone_sprite: var #4
static drone_sprite + #0, #4
static drone_sprite + #1, #5
static drone_sprite + #2, #6
static drone_sprite + #3, #0
chefe_sprite: var #8
static chefe_sprite + #0, #7
static chefe_sprite + #1, #8
static chefe_sprite + #2, #9
static chefe_sprite + #3, #10
static chefe_sprite + #4, #11
static chefe_sprite + #5, #12
static chefe_sprite + #6, #13
static chefe_sprite + #7, #0
chefe_vazio: string "       "


; So esta entrada zera o recorde. Voltar ao menu nao reinicia a CPU.
main:
    loadn r0, #0
    store recorde, r0
    store pontos, r0
    store modo_infinito, r0
    loadn r0, #1
    store fase_atual, r0
    loadn r0, #0
    store selecao, r0
    store contador_anim, r0
    loadn r0, #2
    store nave_direita_x, r0
    loadn r0, #36
    store nave_esquerda_x, r0

; Cada tela limpa a anterior antes de desenhar seus textos.
; Nos menus, as coordenadas sao posicoes fixas da grade de 40 colunas.
menu_inicio:
    call limpa_tela
    call desenha_moldura

    loadn r0, #134
    loadn r1, #titulo
    loadn r2, #2816
    call imprime_str

    loadn r0, #205
    loadn r1, #assinatura
    loadn r2, #2048
    call imprime_str

    loadn r0, #285
    loadn r1, #divisor
    loadn r2, #1536
    call imprime_str

    loadn r0, #173
    loadn r1, #subtitulo
    loadn r2, #1792
    call imprime_str

    loadn r0, #448
    loadn r1, #opcao_jogar
    loadn r2, #0
    call imprime_str

    loadn r0, #528
    loadn r1, #opcao_config
    loadn r2, #0
    call imprime_str

    loadn r0, #608
    loadn r1, #opcao_creditos
    loadn r2, #0
    call imprime_str

    loadn r0, #688
    loadn r1, #opcao_sair
    loadn r2, #0
    call imprime_str

    loadn r0, #965
    loadn r1, #ajuda
    loadn r2, #2048
    call imprime_str

menu_loop:
    call desenha_selecao

; Enquanto nao chega uma tecla, as duas naves decorativas continuam andando.
menu_espera:
    inchar r0
    loadn r1, #255
    cmp r0, r1
    jne menu_tecla
    call anima_naves
    jmp menu_espera

menu_tecla:
    loadn r1, #'w'
    cmp r0, r1
    jeq menu_sobe
    loadn r1, #'W'
    cmp r0, r1
    jeq menu_sobe

    loadn r1, #'s'
    cmp r0, r1
    jeq menu_desce
    loadn r1, #'S'
    cmp r0, r1
    jeq menu_desce

    loadn r1, #13
    cmp r0, r1
    jeq menu_confirma
    jmp menu_loop

; Testa o zero antes de decrementar para nao depender de estouro do registrador.
menu_sobe:
    load r0, selecao
    loadn r1, #0
    cmp r0, r1
    jne menu_sobe_passo
    loadn r0, #3
    jmp menu_salva
menu_sobe_passo:
    dec r0
    jmp menu_salva

menu_desce:
    load r0, selecao
    inc r0
    loadn r1, #4
    cmp r0, r1
    jne menu_salva
    loadn r0, #0

menu_salva:
    store selecao, r0
    jmp menu_loop

; Usa a opcao selecionada para escolher a proxima tela, sem empilhar chamadas.
menu_confirma:
    load r0, selecao
    loadn r1, #0
    cmp r0, r1
    jeq tela_niveis
    loadn r1, #1
    cmp r0, r1
    jeq tela_config
    loadn r1, #2
    cmp r0, r1
    jeq tela_creditos
    jmp tela_sair

; Sete fases e acesso direto ao modo infinito.
tela_niveis:
    ; Entrar na selecao encerra a tentativa anterior, mas conserva o recorde.
    call partida_nova
    load r0, fase_atual
    dec r0
    store nivel_selecao, r0
niveis_desenha:
    call limpa_tela
    call desenha_moldura
    loadn r0, #132
    loadn r1, #niveis_titulo
    loadn r2, #2816
    call imprime_str
    loadn r0, #1004
    loadn r1, #niveis_ajuda
    loadn r2, #2048
    call imprime_str
    loadn r3, #0
    loadn r0, #328
; A lista guarda enderecos de strings. loadi busca o nome da fase escolhida.
niveis_opcoes:
    loadn r1, #niveis_lista
    add r1, r1, r3
    loadi r1, r1
    loadn r2, #1792
    load r4, nivel_selecao
    cmp r3, r4
    jne niveis_imprime
    loadn r2, #2816
niveis_imprime:
    call imprime_str
    loadn r4, #80
    add r0, r0, r4
    inc r3
    loadn r4, #7
    cmp r3, r4
    jne niveis_opcoes
    loadn r0, #924
    loadn r1, #infinito_ajuda
    loadn r2, #512
    call imprime_str
niveis_espera:
    call espera_tecla
    loadn r1, #'i'
    cmp r0, r1
    jeq inicia_infinito
    loadn r1, #'I'
    cmp r0, r1
    jeq inicia_infinito
    loadn r1, #'w'
    cmp r0, r1
    jeq niveis_sobe
    loadn r1, #'W'
    cmp r0, r1
    jeq niveis_sobe
    loadn r1, #'s'
    cmp r0, r1
    jeq niveis_desce
    loadn r1, #'S'
    cmp r0, r1
    jeq niveis_desce
    loadn r1, #'a'
    cmp r0, r1
    jeq menu_inicio
    loadn r1, #'A'
    cmp r0, r1
    jeq menu_inicio
    loadn r1, #13
    cmp r0, r1
    jne niveis_espera
    load r0, nivel_selecao
    inc r0
    store fase_atual, r0
    jmp tela_jogar
niveis_sobe:
    load r0, nivel_selecao
    loadn r1, #0
    cmp r0, r1
    jeq niveis_ultimo
    dec r0
    jmp niveis_salva
niveis_ultimo:
    loadn r0, #6
    jmp niveis_salva
niveis_desce:
    load r0, nivel_selecao
    inc r0
    loadn r1, #7
    cmp r0, r1
    jne niveis_salva
    loadn r0, #0
niveis_salva:
    store nivel_selecao, r0
    jmp niveis_desenha

; Intro da fase. O teclado continua ativo entre os quadros.
; A/D: deslizar; X: frear; espaco: tiros; U: onda; P: pausa.
tela_jogar:
    call fase_configura
    call limpa_tela
    call desenha_moldura
    loadn r0, #127
    load r1, fase_atual
    dec r1
    loadn r2, #niveis_lista
    add r1, r1, r2
    loadi r1, r1
    loadn r2, #2816
    call imprime_str
    loadn r0, #404
    loadn r1, #jogo_objetivo
    loadn r2, #1792
    call imprime_str
    loadn r0, #444
    loadn r1, #intro_naves
    call imprime_str
    load r0, quantidade_inimigos
    loadn r1, #'0'
    add r0, r0, r1
    loadn r1, #458
    outchar r0, r1
    loadn r0, #464
    loadn r1, #intro_meta
    call imprime_str
    load r0, meta_acertos
    loadn r1, #470
    call imprime_numero
    loadn r0, #483
    load r1, fase_atual
    dec r1
    loadn r2, #fase_dicas
    add r1, r1, r2
    loadi r1, r1
    loadn r2, #2816
    call imprime_str
    loadn r0, #563
    loadn r1, #jogo_controles
    loadn r2, #1792
    call imprime_str
    loadn r0, #645
    loadn r1, #jogo_armas
    call imprime_str
    loadn r0, #690
    loadn r1, #jogo_ritmo
    call imprime_str
    loadn r0, #767
    loadn r1, #msg_inicio
    loadn r2, #2816
    call imprime_str
jogo_espera_inicio:
    call espera_tecla
    loadn r1, #13
    cmp r0, r1
    jeq jogo_reinicia
    loadn r1, #'s'
    cmp r0, r1
    jeq tela_niveis
    loadn r1, #'S'
    cmp r0, r1
    jeq tela_niveis
    jmp jogo_espera_inicio
; Prepara a partida tanto ao escolher uma fase quanto ao avancar ou repetir.
; Pontos e recorde nao sao zerados aqui, pois podem continuar entre fases.
jogo_comeca:
    call fase_configura
    call extras_inicia
    call limpa_tela
    call desenha_moldura
    loadn r0, #12
    load r1, fase_atual
    dec r1
    loadn r2, #niveis_lista
    add r1, r1, r2
    loadi r1, r1
    loadn r2, #2816
    call imprime_str
    loadn r0, #1084
    loadn r1, #jogo_controles
    loadn r2, #1792
    call imprime_str
    loadn r0, #1124
    loadn r1, #jogo_armas
    call imprime_str
    loadn r0, #140
    loadn r1, #ultimate_label
    call imprime_str
    loadn r0, #108
    loadn r1, #ritmo_curto
    call imprime_str
    loadn r0, #44
    loadn r1, #jogo_acertos
    call imprime_str
    loadn r0, #54
    loadn r1, #jogo_meta
    call imprime_str
    loadn r0, #64
    loadn r1, #jogo_vidas
    call imprime_str
    loadn r0, #0
    store acertos, r0
    store relogio, r0
    store alvo_tempo, r0
    store recarga, r0
    store resultado, r0
    store vitoria_tempo, r0
    store onda_linha, r0
    store nave_direcao, r0
    store nave_tempo, r0
    store estrelas_tempo, r0
    store estrelas_fase, r0
    loadn r1, #alvos
    loadn r2, #24 ; oito alvos, oito direcoes e oito protecoes
jogo_limpa_inimigos:
    storei r1, r0
    inc r1
    dec r2
    loadn r3, #0
    cmp r2, r3
    jne jogo_limpa_inimigos
    loadn r1, #tiros
    loadn r2, #64 ; 32 posicoes e 32 direcoes
jogo_limpa_tiros:
    storei r1, r0
    inc r1
    dec r2
    loadn r3, #0
    cmp r2, r3
    jne jogo_limpa_tiros
    loadn r0, #6
    store energia, r0
    loadn r0, #0
    store energia_tempo, r0
    call ultimate_placar
    load r0, fase_atual
    dec r0
    loadn r1, #fase_passos
    add r1, r1, r0
    loadi r1, r1
    store passo_inimigo, r1
    loadn r1, #fase_cores
    add r1, r1, r0
    loadi r1, r1
    store cor_inimigo, r1
    loadn r0, #20
    store grupo_coluna, r0
    loadn r0, #1
    store grupo_direcao, r0
    store grupo_delta, r0
    loadn r0, #0
    store grupo_virou, r0
    call configura_ritmo
    load r0, vidas_reserva
    store vidas, r0
    loadn r0, #1060
    store nave_pos, r0
    loadn r0, #8
    store proxima_coluna, r0
    call desenha_estrelas
    loadn r4, #0
jogo_cria_inimigos:
    call novo_alvo
    inc r4
    load r0, quantidade_inimigos
    cmp r4, r0
    jne jogo_cria_inimigos
    call desenha_nave
    call jogo_placar
    call extras_placar
; Le o teclado em toda passagem. O mundo so avanca quando o relogio atinge
; o intervalo, para a nave continuar respondendo durante a espera do quadro.
jogo_loop:
    inchar r0
    loadn r1, #255
    cmp r0, r1
    jeq jogo_tempo
    loadn r1, #'p'
    cmp r0, r1
    jeq jogo_pausa
    loadn r1, #'P'
    cmp r0, r1
    jeq jogo_pausa
    loadn r1, #'s'
    cmp r0, r1
    jeq tela_niveis
    loadn r1, #'S'
    cmp r0, r1
    jeq tela_niveis
    loadn r1, #'a'
    cmp r0, r1
    jeq nave_esquerda
    loadn r1, #'A'
    cmp r0, r1
    jeq nave_esquerda
    loadn r1, #'d'
    cmp r0, r1
    jeq nave_direita
    loadn r1, #'D'
    cmp r0, r1
    jeq nave_direita
    loadn r1, #' '
    cmp r0, r1
    jeq nave_atira
    loadn r1, #'x'
    cmp r0, r1
    jeq nave_freia
    loadn r1, #'X'
    cmp r0, r1
    jeq nave_freia
    loadn r1, #'u'
    cmp r0, r1
    jeq nave_ultimate
    loadn r1, #'U'
    cmp r0, r1
    jeq nave_ultimate
    loadn r1, #'1'
    cmp r0, r1
    jeq ritmo_calmo
    loadn r1, #'2'
    cmp r0, r1
    jeq ritmo_normal
    jmp jogo_tempo
ritmo_calmo:
    loadn r0, #9000
    jmp ritmo_salva
ritmo_normal:
    loadn r0, #5800
ritmo_salva:
    call grava_ritmo
    loadn r0, #0
    store nave_tempo, r0
    store relogio, r0
    jmp jogo_tempo
nave_esquerda:
    loadn r0, #1
    jmp nave_muda_direcao
nave_direita:
    loadn r0, #2
nave_muda_direcao:
    load r1, nave_direcao
    cmp r0, r1
    jeq jogo_tempo
    store nave_direcao, r0
    ; Ao iniciar ou inverter o deslize, a nave anda na hora.
    call desliza_passo
    jmp jogo_tempo
nave_freia:
    loadn r0, #0
    store nave_direcao, r0
    store nave_tempo, r0
    jmp jogo_tempo
nave_atira:
    call dispara_rajada
    jmp jogo_tempo

jogo_tempo:
    call nave_desliza
    load r0, relogio
    inc r0
    store relogio, r0
    load r1, intervalo
    cmp r0, r1
    jle jogo_loop
    loadn r0, #0
    store relogio, r0
    load r0, recarga
    loadn r1, #0
    cmp r0, r1
    jeq jogo_quadro
    dec r0
    store recarga, r0
; Ordem de um quadro: bonus e prazos, protecao, energia, tiros, inimigos e onda.
; O redesenho final recupera partes de objetos apagadas por outros sprites.
jogo_quadro:
    call extras_quadro
    call atualiza_protecao
    call ultimate_recarrega
    call atualiza_tiros
    call atualiza_alvos
    call onda_atualiza
    call inimigo_dispara
    call pulsa_estrelas
    call arena_redesenha
    load r0, resultado
    loadn r1, #1
    cmp r0, r1
    jeq jogo_verifica_vitoria
    loadn r1, #2
    cmp r0, r1
    jeq jogo_perdeu
    jmp jogo_loop


; A meta pode ser atingida no meio da onda. Espera o efeito acabar antes
; de trocar de tela ou iniciar automaticamente a proxima onda do infinito.
jogo_verifica_vitoria:
    load r0, onda_linha
    loadn r1, #0
    cmp r0, r1
    jne jogo_loop
    ; Deixa o efeito terminar antes da tela de fase concluida.
    load r0, vitoria_tempo
    loadn r1, #0
    cmp r0, r1
    jeq jogo_ganhou
    dec r0
    store vitoria_tempo, r0
    jmp jogo_loop

; A nave tem seu proprio ritmo para responder mais rapido que os inimigos.
nave_desliza:
    ; A faixa 1042..1077 deixa espaco para as duas pontas do sprite de 3 casas.
    load r0, nave_direcao
    loadn r1, #0
    cmp r0, r1
    jeq desliza_fim
    load r0, nave_tempo
    inc r0
    store nave_tempo, r0
    load r1, nave_intervalo
    cmp r0, r1
    jle desliza_fim
desliza_passo:
    loadn r0, #0
    store nave_tempo, r0
    load r0, nave_pos
    load r1, nave_direcao
    loadn r2, #1
    cmp r1, r2
    jeq desliza_esquerda
    loadn r1, #1077
    cmp r0, r1
    jeq desliza_para
    call apaga_sprite
    inc r0
    jmp desliza_salva
desliza_esquerda:
    loadn r1, #1042
    cmp r0, r1
    jeq desliza_para
    call apaga_sprite
    dec r0
desliza_salva:
    store nave_pos, r0
    call desenha_nave
    rts
desliza_para:
    loadn r0, #0
    store nave_direcao, r0
desliza_fim:
    rts

; U solta uma onda larga que atravessa a arena de baixo para cima.
; Cada inimigo ativo pode ser atingido uma vez por onda, sem auto-recarga.
nave_ultimate:
    ; Nao aceita uma nova onda se outra ja esta ativa ou a partida acabou.
    load r0, onda_linha
    loadn r1, #0
    cmp r0, r1
    jne jogo_tempo
    load r0, resultado
    cmp r0, r1
    jne jogo_tempo
    load r0, energia
    loadn r1, #6
    cmp r0, r1
    jne jogo_tempo
    loadn r0, #0
    store energia, r0
    store energia_tempo, r0
    loadn r1, #onda_atingidos
    loadn r2, #8
; Libera as marcas da onda anterior. Reaparecer nao libera a marca da atual.
onda_limpa_marcas:
    storei r1, r0
    inc r1
    dec r2
    loadn r3, #0
    cmp r2, r3
    jne onda_limpa_marcas
    loadn r7, #tiros
    loadn r6, #0
ultimate_limpa:
    loadi r0, r7
    loadn r1, #0
    cmp r0, r1
    jeq ultimate_limpa_slot
    call apaga_tiro
ultimate_limpa_slot:
    loadn r0, #0
    storei r7, r0
    inc r7
    inc r6
    loadn r1, #32
    cmp r6, r1
    jne ultimate_limpa
    loadn r0, #24
    store onda_linha, r0
    call onda_dano
    call onda_redesenha
    loadn r1, #1
    call onda_pinta
    call ultimate_placar
    jmp jogo_tempo

onda_atualiza:
    load r0, onda_linha
    loadn r1, #0
    cmp r0, r1
    jeq onda_fim
    ; Inclui inimigos que entraram na faixa desde o ultimo quadro.
    call onda_dano
    loadn r1, #0
    call onda_pinta
    load r0, onda_linha
    loadn r1, #2
    sub r0, r0, r1
    loadn r1, #4
    cmp r0, r1
    jle onda_termina
    store onda_linha, r0
    call onda_dano
    rts
onda_termina:
    loadn r0, #0
    store onda_linha, r0
onda_fim:
    rts

; r1: zero apaga, um desenha duas linhas de energia.
onda_pinta:
    push r0
    push r1
    push r2
    push r3
    loadn r3, #0
    cmp r1, r3
    jeq onda_cores_apagar
    loadn r1, #3352 ; onda rosa
    loadn r3, #3609 ; pulso aqua
    jmp onda_cores_prontas
onda_cores_apagar:
    loadn r1, #' '
    loadn r3, #' '
onda_cores_prontas:
    load r0, onda_linha
    loadn r2, #40
    mul r0, r0, r2
    loadn r2, #2
    add r0, r0, r2
    call onda_faixa
    loadn r2, #40
    add r0, r0, r2
    mov r1, r3
    call onda_faixa
    pop r3
    pop r2
    pop r1
    pop r0
    rts
onda_faixa:
    push r0
    push r2
    push r3
    loadn r2, #36
onda_faixa_loop:
    outchar r1, r0
    inc r0
    dec r2
    loadn r3, #0
    cmp r2, r3
    jne onda_faixa_loop
    pop r3
    pop r2
    pop r0
    rts

; Verifica se o centro do inimigo esta entre as duas linhas do efeito.
; A marca e feita antes da reposicao para nao pontuar de novo naquele slot.
onda_dano:
    load r0, resultado
    loadn r1, #0
    cmp r0, r1
    jne onda_dano_fim
    loadn r4, #0
    loadn r5, #alvos
    loadn r6, #onda_atingidos
onda_dano_loop:
    loadi r0, r6
    loadn r1, #0
    cmp r0, r1
    jne onda_dano_proximo
    load r2, onda_linha
    loadn r1, #40
    mul r2, r2, r1
    loadn r1, #80
    add r3, r2, r1
    loadi r0, r5
    cmp r0, r2
    jle onda_dano_proximo
    cmp r0, r3
    jgr onda_dano_proximo
    call apaga_alvo
    loadn r0, #1
    storei r6, r0
    load r0, acertos
    load r1, meta_acertos
    cmp r0, r1
    jeq onda_dano_repor
    inc r0
    store acertos, r0
    push r0
    push r1
    call registra_acerto
    pop r1
    pop r0
    cmp r0, r1
    jne onda_dano_repor
    loadn r0, #1
    store resultado, r0
    loadn r0, #0
    store vitoria_tempo, r0
onda_dano_repor:
    load r0, fase_atual
    loadn r1, #7
    cmp r0, r1
    jeq onda_dano_proximo
    call novo_alvo
onda_dano_proximo:
    inc r4
    inc r5
    inc r6
    load r1, quantidade_inimigos
    cmp r4, r1
    jne onda_dano_loop
    call jogo_placar
onda_dano_fim:
    rts

; Repinta objetos que estavam atras do efeito, sem deixar rastros.
onda_redesenha:
    loadn r4, #0
    loadn r5, #alvos
onda_redesenha_alvos:
    loadi r0, r5
    call desenha_alvo
    inc r5
    inc r4
    load r1, quantidade_inimigos
    cmp r4, r1
    jne onda_redesenha_alvos
    loadn r7, #tiros
    loadn r6, #0
onda_redesenha_tiros:
    loadi r0, r7
    loadn r1, #0
    cmp r0, r1
    jeq onda_redesenha_proximo
    call desenha_tiro
onda_redesenha_proximo:
    inc r7
    inc r6
    loadn r1, #32
    cmp r6, r1
    jne onda_redesenha_tiros
    call desenha_nave
    rts

; Seis segmentos: carrega com o tempo e ganha dois por acerto normal.
ultimate_recarrega:
    load r0, energia
    loadn r1, #6
    cmp r0, r1
    jeq energia_fim
    load r0, energia_tempo
    inc r0
    store energia_tempo, r0
    loadn r1, #30
    cmp r0, r1
    jne energia_fim
    loadn r0, #0
    store energia_tempo, r0
    load r0, energia
    inc r0
    store energia, r0
    call ultimate_placar
energia_fim:
    rts
ultimate_placar:
    push r0
    push r1
    push r2
    push r3
    push r4
    loadn r0, #143
    loadn r1, #'['
    outchar r1, r0
    inc r0
    loadn r3, #0
    load r4, energia
ultimate_barra:
    cmp r3, r4
    jeq ultimate_segmento_vazio
    jle ultimate_segmento_cheio
ultimate_segmento_vazio:
    loadn r1, #2093 ; - em cinza
    jmp ultimate_segmento_imprime
ultimate_segmento_cheio:
    loadn r1, #2851 ; # em amarelo
    loadn r2, #6
    cmp r4, r2
    jne ultimate_segmento_imprime
    loadn r1, #547 ; # em verde
ultimate_segmento_imprime:
    outchar r1, r0
    inc r0
    inc r3
    loadn r2, #6
    cmp r3, r2
    jne ultimate_barra
    loadn r1, #']'
    outchar r1, r0
    loadn r0, #152
    loadn r1, #ultimate_vazia
    loadn r2, #2048
    loadn r3, #6
    cmp r4, r3
    jne ultimate_status
    loadn r1, #ultimate_pronta
    loadn r2, #512
ultimate_status:
    call imprime_str
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; A nave e os inimigos comuns ocupam tres caracteres, com a posicao no centro.
; O chefe ocupa sete e tem uma rotina de limpeza propria.
apaga_sprite:
    push r0
    push r1
    dec r0
    loadn r1, #' '
    outchar r1, r0
    inc r0
    outchar r1, r0
    inc r0
    outchar r1, r0
    pop r1
    pop r0
    rts
desenha_nave:
    push r0
    push r1
    push r2
    load r0, nave_pos
    dec r0
    loadn r1, #3585 ; asa aqua, tile 1
    outchar r1, r0
    loadn r1, #2818 ; cabine amarela, tile 2
    load r2, escudo
    loadn r0, #0
    cmp r2, r0
    jeq nave_cabine
    loadn r1, #2562 ; cabine verde quando ha escudo
nave_cabine:
    load r0, nave_pos
    outchar r1, r0
    inc r0
    loadn r1, #3587 ; asa aqua, tile 3
    outchar r1, r0
    pop r2
    pop r1
    pop r0
    rts
desenha_alvo:
    push r1
    load r1, fase_atual
    push r2
    loadn r2, #7
    cmp r1, r2
    pop r2
    pop r1
    jeq desenha_chefe
    push r0
    push r1
    push r2
    dec r0
    loadn r1, #drone_sprite
    load r2, cor_inimigo
    call imprime_str
    pop r2
    pop r1
    pop r0
    rts
; r0 = posicao e r7 = endereco do slot do tiro; a direcao define o caractere.
desenha_tiro:
    push r1
    push r2
    loadn r1, #tiros
    sub r1, r7, r1
    loadn r2, #tiro_direcoes
    add r1, r1, r2
    loadi r2, r1
    loadn r1, #0
    cmp r2, r1
    jeq desenha_tiro_normal
    loadn r1, #3347 ; faisca do charmap
    jmp desenha_tiro_imprime
desenha_tiro_normal:
    loadn r1, #2830 ; laser do charmap
desenha_tiro_imprime:
    outchar r1, r0
    pop r2
    pop r1
    rts
apaga_tiro:
    push r1
    loadn r1, #' '
    outchar r1, r0
    pop r1
    rts
; Dois digitos permitem metas e pontuacoes acima de 9.
jogo_placar:
    load r0, acertos
    loadn r1, #52
    call imprime_numero
    load r0, meta_acertos
    loadn r1, #55
    call imprime_numero
    load r0, vidas
    loadn r1, #'0'
    add r0, r0, r1
    loadn r1, #71
    outchar r0, r1
    rts
; Entrada: r0 = valor de 0 a 99, r1 = primeira posicao de tela.
; A divisao por 10 fornece a dezena e o resto fornece a unidade.
imprime_numero:
    push r0
    push r1
    push r2
    push r3
    loadn r2, #10
    div r3, r0, r2
    loadn r2, #'0'
    add r3, r3, r2
    outchar r3, r1
    inc r1
    loadn r2, #10
    mod r3, r0, r2
    loadn r2, #'0'
    add r3, r3, r2
    outchar r3, r1
    pop r3
    pop r2
    pop r1
    pop r0
    rts
; Nas fases comuns a meta e tres vezes a quantidade de inimigos.
; Esquadra usa 40 acertos e o chefe usa um inimigo com 20 pontos de dano.
fase_configura:
    load r0, fase_atual
    loadn r1, #7
    cmp r0, r1
    jne fase_configura_normal
    loadn r0, #1
    store quantidade_inimigos, r0
    loadn r0, #20
    store meta_acertos, r0
    rts
fase_configura_normal:
    load r0, fase_atual
    loadn r1, #2
    add r0, r0, r1
    store quantidade_inimigos, r0
    loadn r1, #3
    mul r0, r0, r1
    load r1, fase_atual
    loadn r2, #6
    cmp r1, r2
    jne fase_meta_pronta
    loadn r0, #40
fase_meta_pronta:
    store meta_acertos, r0
    rts

; r4 = indice ativo 0..7. Reposiciona somente a nave atingida/perdida.
novo_alvo:
    load r0, fase_atual
    dec r0
    loadn r1, #8
    mul r0, r0, r1
    add r0, r0, r4
    loadn r1, #fase_formacoes
    add r0, r0, r1
    loadi r0, r0
    load r1, fase_atual
    loadn r2, #7
    cmp r1, r2
    jeq novo_alvo_grava
    load r1, grupo_coluna
    add r0, r0, r1
    loadn r1, #20
    sub r0, r0, r1
novo_alvo_grava:
    loadn r2, #alvos
    add r2, r2, r4
    storei r2, r0
    call desenha_alvo
    ; As faiscas nao acertam de novo a mesma nave assim que ela reaparece.
    loadn r1, #explosao_protecao
    add r1, r1, r4
    loadn r0, #8
    storei r1, r0
    loadn r0, #1
    load r1, fase_atual
    loadn r2, #1
    cmp r1, r2
    jeq novo_alvo_direcao
    loadn r0, #2
    mod r0, r4, r0
novo_alvo_direcao:
    loadn r1, #direcoes
    add r1, r1, r4
    storei r1, r0
    rts
; Primeiro apaga as posicoes antigas de todos os tiros; depois move e desenha.
; Fazer isso tiro por tiro poderia apagar um projetil desenhado por outro slot.
atualiza_tiros:
    loadn r7, #tiros
    loadn r6, #0
    ; Apaga todos antes de mover: uma fileira nao apaga a outra da rajada.
tiros_apaga_anteriores:
    loadi r0, r7
    loadn r1, #0
    cmp r0, r1
    jeq tiros_apaga_proximo
    call apaga_tiro
tiros_apaga_proximo:
    inc r7
    inc r6
    loadn r1, #32
    cmp r6, r1
    jne tiros_apaga_anteriores
    loadn r7, #tiros
    loadn r6, #0
tiros_loop:
    loadi r0, r7
    loadn r1, #0
    cmp r0, r1
    jeq tiros_proximo
    loadn r1, #tiro_direcoes
    add r1, r1, r6
    loadi r2, r1
    loadn r1, #6
    cmp r2, r1
    jeq tiro_explosao_baixo_esquerda
    loadn r1, #7
    cmp r2, r1
    jeq tiro_explosao_baixo_direita
    loadn r1, #40
    sub r0, r0, r1
    loadn r1, #1
    cmp r2, r1
    jeq tiro_diagonal_esquerda
    loadn r1, #2
    cmp r2, r1
    jne tiro_verifica_borda
    inc r0
    jmp tiro_verifica_borda
tiro_diagonal_esquerda:
    dec r0
    jmp tiro_verifica_borda
tiro_explosao_baixo_esquerda:
    loadn r1, #39
    add r0, r0, r1
    jmp tiro_verifica_borda
tiro_explosao_baixo_direita:
    loadn r1, #41
    add r0, r0, r1
; Remove o tiro antes que ele invada o placar, a linha da nave ou a moldura.
tiro_verifica_borda:
    loadn r1, #160
    cmp r0, r1
    jle tiros_remove
    loadn r1, #1040
    cmp r0, r1
    jeq tiros_remove
    jgr tiros_remove
    loadn r1, #40
    mod r2, r0, r1
    loadn r1, #0
    cmp r2, r1
    jeq tiros_remove
    loadn r1, #39
    cmp r2, r1
    jeq tiros_remove
    storei r7, r0
    call verifica_acerto
    loadi r0, r7
    loadn r1, #0
    cmp r0, r1
    jeq tiros_proximo
    call desenha_tiro
    jmp tiros_proximo
tiros_remove:
    loadn r0, #0
    storei r7, r0
tiros_proximo:
    inc r7
    inc r6
    loadn r1, #32
    cmp r6, r1
    jne tiros_loop
    rts

; Diminui a protecao temporaria dos inimigos sem alterar os indices dos tiros.
atualiza_protecao:
    loadn r1, #explosao_protecao
    loadn r2, #0
protecao_loop:
    loadi r0, r1
    loadn r3, #0
    cmp r0, r3
    jeq protecao_proxima
    dec r0
    storei r1, r0
protecao_proxima:
    inc r1
    inc r2
    load r3, quantidade_inimigos
    cmp r2, r3
    jne protecao_loop
    rts

; r7 aponta para o tiro. Preserva os indices dos loops chamadores.
verifica_acerto:
    push r4
    push r5
    load r0, resultado
    loadn r1, #0
    cmp r0, r1
    jne acerto_fim
    loadn r4, #0
    loadn r5, #alvos
acerto_procura:
    loadi r0, r7
    loadn r1, #0
    cmp r0, r1
    jeq acerto_fim
    loadn r1, #tiros
    sub r2, r7, r1
    loadn r1, #tiro_direcoes
    add r2, r2, r1
    loadi r2, r2
    loadn r1, #0
    cmp r2, r1
    jeq acerto_compara
    loadn r1, #explosao_protecao
    add r1, r1, r4
    loadi r2, r1
    loadn r1, #0
    cmp r2, r1
    jne acerto_proximo
acerto_compara:
    ; Aceita o centro ou uma das pontas do inimigo, nao apenas o centro.
    ; O teste separado do chefe considera sua largura maior.
    call colisao_chefe
    loadn r1, #1
    cmp r2, r1
    jeq acerto_atingiu
    loadi r1, r5
    cmp r0, r1
    jeq acerto_atingiu
    dec r1
    cmp r0, r1
    jeq acerto_atingiu
    inc r1
    inc r1
    cmp r0, r1
    jeq acerto_atingiu
acerto_proximo:
    inc r5
    inc r4
    load r1, quantidade_inimigos
    cmp r4, r1
    jne acerto_procura
    jmp acerto_fim
; Consome o tiro antes de somar o acerto. Assim outro teste no mesmo quadro
; nao conta esse projetil de novo. O chefe recebe dano sem reaparecer.
acerto_atingiu:
    call apaga_tiro
    loadn r0, #0
    storei r7, r0
    loadi r0, r5
    call apaga_alvo
    load r0, acertos
    inc r0
    store acertos, r0
    call registra_acerto
    ; Apenas tiros normais dao energia, evitando ultimates infinitos.
    loadn r0, #tiros
    sub r0, r7, r0
    loadn r1, #tiro_direcoes
    add r0, r0, r1
    loadi r0, r0
    loadn r1, #0
    cmp r0, r1
    jne acerto_energia_pronta
    load r0, energia
    loadn r1, #6
    cmp r0, r1
    jeq acerto_energia_pronta
    loadn r1, #2
    add r0, r0, r1
    loadn r1, #6
    cmp r0, r1
    jgr acerto_energia_limite
    jmp acerto_energia_salva
acerto_energia_limite:
    loadn r0, #6
acerto_energia_salva:
    store energia, r0
acerto_energia_pronta:
    call ultimate_placar
    call jogo_placar
    load r0, acertos
    load r1, meta_acertos
    cmp r0, r1
    jne acerto_repor
    loadn r0, #1
    store resultado, r0
    jmp acerto_fim
acerto_repor:
    load r0, fase_atual
    loadn r1, #7
    cmp r0, r1
    jeq acerto_fim
    call novo_alvo
acerto_fim:
    pop r5
    pop r4
    rts

; Os drones andam juntos. A frota so desce quando chega na lateral.
atualiza_alvos:
    load r0, fase_atual
    loadn r1, #7
    cmp r0, r1
    jeq chefe_atualiza
    load r0, resultado
    loadn r1, #0
    cmp r0, r1
    jne alvos_fim
    load r0, alvo_tempo
    inc r0
    store alvo_tempo, r0
    load r1, passo_inimigo
    cmp r0, r1
    jne alvos_fim
    loadn r0, #0
    store alvo_tempo, r0
    call grupo_atualiza
    loadn r4, #0
    loadn r5, #alvos
alvos_loop:
    loadi r0, r5
    call apaga_sprite
    ; Nas bordas, gasta o passo apenas descendo e vira para o proximo.
    load r1, grupo_virou
    loadn r2, #0
    cmp r1, r2
    jne alvo_desce
    load r1, grupo_delta
    loadn r2, #1
    cmp r1, r2
    jeq alvo_direita
    dec r0
    jmp alvo_grava
alvo_direita:
    inc r0
    jmp alvo_grava
alvo_desce:
    loadn r1, #40
    add r0, r0, r1
alvo_grava:
    loadn r1, #1040
    cmp r0, r1
    jgr frota_chegou
    storei r5, r0
alvo_proximo:
    inc r5
    inc r4
    load r1, quantidade_inimigos
    cmp r4, r1
    jne alvos_loop
    ; Detecta tambem a nave que se moveu sobre um tiro.
    loadn r7, #tiros
    loadn r6, #0
alvos_colisoes:
    call verifica_acerto
    inc r7
    inc r6
    loadn r1, #32
    cmp r6, r1
    jne alvos_colisoes
    loadn r5, #alvos
    loadn r4, #0
alvos_desenha:
    loadi r0, r5
    call desenha_alvo
    inc r5
    inc r4
    load r1, quantidade_inimigos
    cmp r4, r1
    jne alvos_desenha
alvos_fim:
    rts
frota_chegou:
    ; Uma chegada custa uma vida ou escudo, mesmo com varios drones na base.
    call recebe_dano
    load r0, vidas
    loadn r1, #0
    cmp r0, r1
    jne frota_reinicia
    loadn r0, #2
    store resultado, r0
    rts
frota_reinicia:
    loadn r0, #20
    store grupo_coluna, r0
    loadn r0, #1
    store grupo_direcao, r0
    store grupo_delta, r0
    loadn r4, #0
    loadn r5, #alvos
frota_reinicia_loop:
    loadi r0, r5
    call apaga_sprite
    call novo_alvo
    inc r4
    inc r5
    load r0, quantidade_inimigos
    cmp r4, r0
    jne frota_reinicia_loop
    rts

; As formacoes ocupam as colunas 10 a 30 no inicio. A referencia 20
; pode variar de 12 a 27, mantendo os centros entre as colunas 2 e 37.
grupo_atualiza:
    loadn r0, #0
    store grupo_virou, r0
    load r0, grupo_coluna
    load r1, grupo_direcao
    loadn r2, #0
    cmp r1, r2
    jeq grupo_esquerda
    loadn r1, #27
    cmp r0, r1
    jne grupo_direita_passo
    loadn r1, #0
    store grupo_direcao, r1
    jmp grupo_marca_descida
grupo_direita_passo:
    inc r0
    loadn r1, #1
    jmp grupo_salva
grupo_esquerda:
    loadn r1, #12
    cmp r0, r1
    jne grupo_esquerda_passo
    loadn r1, #1
    store grupo_direcao, r1
grupo_marca_descida:
    loadn r1, #1
    store grupo_virou, r1
    rts
grupo_esquerda_passo:
    dec r0
    loadn r1, #2
grupo_salva:
    store grupo_coluna, r0
    store grupo_delta, r1
    rts

jogo_ganhou:
    load r0, modo_infinito
    loadn r1, #1
    cmp r0, r1
    jeq jogo_continua
    load r0, fase_atual
    loadn r1, #7
    cmp r0, r1
    jne jogo_fase_ganhou
    loadn r1, #jogo_final
    loadn r2, #2816
    jmp jogo_resultado
jogo_fase_ganhou:
    loadn r1, #jogo_vitoria
    loadn r2, #2816
    jmp jogo_resultado
jogo_perdeu:
    loadn r1, #jogo_derrota
    loadn r2, #2304
jogo_resultado:
    call limpa_tela
    call desenha_moldura
    loadn r0, #485
    call imprime_str
    loadn r0, #645
    loadn r1, #jogo_repetir
    loadn r2, #1792
    call imprime_str
    loadn r0, #770
    loadn r1, #jogo_voltar
    call imprime_str
    call resultado_pontos
jogo_fim_tecla:
    call espera_tecla
    loadn r1, #13
    cmp r0, r1
    jeq jogo_continua
    loadn r1, #'r'
    cmp r0, r1
    jeq jogo_reinicia
    loadn r1, #'R'
    cmp r0, r1
    jeq jogo_reinicia
    loadn r1, #'s'
    cmp r0, r1
    jeq tela_niveis
    loadn r1, #'S'
    cmp r0, r1
    jeq tela_niveis
    jmp jogo_fim_tecla
; Enter avanca somente quando resultado = 1; na derrota, comeca nova tentativa.
jogo_continua:
    load r0, resultado
    loadn r1, #1
    cmp r0, r1
    jne jogo_reinicia
    load r0, modo_infinito
    loadn r1, #1
    cmp r0, r1
    jeq infinito_avanca
    load r0, fase_atual
    loadn r1, #7
    cmp r0, r1
    jeq tela_niveis
    inc r0
    store fase_atual, r0
    jmp jogo_comeca

; tela que mostra os controles
tela_config:
    call limpa_tela
    call desenha_moldura
    loadn r0, #133
    loadn r1, #titulo_config
    loadn r2, #3584
    call imprime_str
    loadn r0, #491
    loadn r1, #config_controle1
    loadn r2, #0
    call imprime_str
    loadn r0, #530
    loadn r1, #config_controle2
    call imprime_str
    loadn r0, #607
    loadn r1, #config_mensagem
    loadn r2, #2560
    call imprime_str
    loadn r0, #644
    loadn r1, #hud_bonus
    loadn r2, #512
    call imprime_str
    loadn r0, #687
    loadn r1, #voltar_enter
    loadn r2, #2048
    call imprime_str
    call espera_enter
    jmp menu_inicio

; tela com os nomes da equipe
tela_creditos:
    call limpa_tela
    call desenha_moldura
    loadn r0, #136
    loadn r1, #titulo_creditos
    loadn r2, #3328
    call imprime_str

    loadn r0, #452
    loadn r1, #nome_1
    loadn r2, #0
    call imprime_str
    loadn r0, #492
    loadn r1, #nome_2
    call imprime_str
    loadn r0, #533
    loadn r1, #nome_3
    call imprime_str
    loadn r0, #572
    loadn r1, #nome_4
    call imprime_str

    loadn r0, #687
    loadn r1, #voltar_enter
    loadn r2, #2048
    call imprime_str
    call espera_enter
    jmp menu_inicio

; tela final do programa
tela_sair:
    call limpa_tela
    loadn r0, #493
    loadn r1, #titulo_sair
    loadn r2, #2816
    call imprime_str
    loadn r0, #576
    loadn r1, #msg_sair
    loadn r2, #1792
    call imprime_str
    halt

; redesenha todas as opcoes e destaca a escolhida
desenha_selecao:
    push r0
    push r1
    push r2
    push r3
    push r4

    loadn r2, #0
    loadn r0, #448
    loadn r1, #opcao_jogar
    call imprime_str
    loadn r0, #528
    loadn r1, #opcao_config
    call imprime_str
    loadn r0, #608
    loadn r1, #opcao_creditos
    call imprime_str
    loadn r0, #688
    loadn r1, #opcao_sair
    call imprime_str

    load r3, selecao
    loadn r2, #2816
    loadn r0, #448
    loadn r1, #sel_jogar
    loadn r4, #0
    cmp r3, r4
    jeq desenha_escolhida

    loadn r0, #528
    loadn r1, #sel_config
    loadn r4, #1
    cmp r3, r4
    jeq desenha_escolhida

    loadn r0, #608
    loadn r1, #sel_creditos
    loadn r4, #2
    cmp r3, r4
    jeq desenha_escolhida

    loadn r0, #688
    loadn r1, #sel_sair

desenha_escolhida:
    call imprime_str
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; desenha uma moldura simples de quarenta colunas
desenha_moldura:
    push r0
    push r1
    push r2
    push r3
    loadn r1, #linha_topo
    loadn r2, #1536
    loadn r0, #0
    call imprime_str
    loadn r0, #1160
    call imprime_str

    loadn r1, #linha_lado
    loadn r0, #40

moldura_loop:
    loadn r2, #1536
    call imprime_str
    loadn r3, #40
    add r0, r0, r3
    loadn r3, #1160
    cmp r0, r3
    jne moldura_loop
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; move duas naves devagar e faz elas voltarem pelo outro lado
anima_naves:
    push r0
    push r1
    push r2
    push r3

    load r0, contador_anim
    inc r0
    store contador_anim, r0
    loadn r1, #5500
    cmp r0, r1
    jne anima_fim
    loadn r0, #0
    store contador_anim, r0

    ; apaga a nave que anda para a direita
    load r0, nave_direita_x
    loadn r1, #320
    add r1, r1, r0
    loadn r2, #' '
    outchar r2, r1
    inc r1
    outchar r2, r1

    ; calcula a nova posicao da primeira nave
    inc r0
    loadn r1, #37
    cmp r0, r1
    jne nave_direita_salva
    loadn r0, #2

nave_direita_salva:
    store nave_direita_x, r0
    loadn r1, #320
    add r1, r1, r0
    loadn r2, #20
    loadn r3, #3584
    add r2, r2, r3
    outchar r2, r1
    inc r1
    loadn r2, #21
    add r2, r2, r3
    outchar r2, r1

    ; apaga a nave que anda para a esquerda
    load r0, nave_esquerda_x
    loadn r1, #800
    add r1, r1, r0
    loadn r2, #' '
    outchar r2, r1
    inc r1
    outchar r2, r1

    ; calcula a nova posicao da segunda nave
    dec r0
    loadn r1, #1
    cmp r0, r1
    jne nave_esquerda_salva
    loadn r0, #36

nave_esquerda_salva:
    store nave_esquerda_x, r0
    loadn r1, #800
    add r1, r1, r0
    loadn r2, #22
    loadn r3, #3328
    add r2, r2, r3
    outchar r2, r1
    inc r1
    loadn r2, #23
    add r2, r2, r3
    outchar r2, r1

anima_fim:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; espera uma tecla valida chegar do teclado
espera_tecla:
    push r1
    loadn r1, #255

espera_tecla_loop:
    inchar r0
    cmp r0, r1
    jeq espera_tecla_loop
    pop r1
    rts

; espera especificamente pela tecla enter
espera_enter:
    push r0
    push r1
    loadn r1, #13

espera_enter_loop:
    call espera_tecla
    cmp r0, r1
    jne espera_enter_loop
    pop r1
    pop r0
    rts

; preenche as mil e duzentas posicoes com espacos
limpa_tela:
    push r0
    push r1
    push r2
    loadn r0, #0
    loadn r1, #' '
    loadn r2, #1200

limpa_tela_loop:
    outchar r1, r0
    inc r0
    cmp r0, r2
    jne limpa_tela_loop
    pop r2
    pop r1
    pop r0
    rts

; imprime uma string terminada em zero
; r0 guarda a posicao, r1 o endereco e r2 a cor
imprime_str:
    push r0
    push r1
    push r2
    push r3
    push r4
    loadn r3, #'\0'

imprime_str_loop:
    loadi r4, r1
    cmp r4, r3
    jeq imprime_str_fim
    add r4, r2, r4
    outchar r4, r0
    inc r0
    inc r1
    jmp imprime_str_loop

imprime_str_fim:
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts


; Zera a tentativa e prepara tres vidas. O recorde fica fora desta rotina.
partida_nova:
    loadn r0, #0
    store pontos, r0
    store modo_infinito, r0
    store bonus_ciclo, r0
    store bonus_contador, r0
    loadn r0, #1
    store onda_numero, r0
    loadn r0, #3
    store vidas_reserva, r0
    rts

; A tecla I da selecao inicia o infinito sempre pela primeira formacao.
inicia_infinito:
    call partida_nova
    loadn r0, #1
    store modo_infinito, r0
    store fase_atual, r0
    jmp tela_jogar

; Conserva apenas o modo escolhido: campanha repete a fase, infinito volta a 1.
jogo_reinicia:
    load r6, modo_infinito
    call partida_nova
    store modo_infinito, r6
    loadn r0, #0
    cmp r6, r0
    jeq jogo_comeca
    loadn r0, #1
    store fase_atual, r0
    jmp jogo_comeca

; Carrega as vidas restantes e alterna entre as seis formacoes comuns.
; O chefe fica na campanha. A contagem para em 99 para caber no placar.
infinito_avanca:
    load r0, vidas
    store vidas_reserva, r0
    load r0, onda_numero
    loadn r1, #99
    cmp r0, r1
    jeq infinito_fase
    inc r0
    store onda_numero, r0
infinito_fase:
    load r0, fase_atual
    inc r0
    loadn r1, #7
    cmp r0, r1
    jne infinito_salva
    loadn r0, #1
infinito_salva:
    store fase_atual, r0
    jmp jogo_comeca

; Bonus, escudo, combo e tiro do chefe pertencem a fase que esta comecando.
extras_inicia:
    loadn r0, #0
    store bonus_pos, r0
    store duplo_tempo, r0
    store escudo, r0
    store tiro_inimigo, r0
    store tiro_inimigo_tempo, r0
    store atirador, r0
    store aviso_disparo, r0
    store combo, r0
    store combo_tempo, r0
    rts

; A campanha comeca no ritmo normal. No infinito, cada onda tira 150
; passagens do intervalo, ate o minimo de 3400 passagens na onda 16.
configura_ritmo:
    loadn r0, #5800
    load r1, modo_infinito
    loadn r2, #0
    cmp r1, r2
    jeq configura_ritmo_salva
    load r1, onda_numero
    loadn r2, #16
    cmp r1, r2
    jle configura_ritmo_onda
    loadn r1, #16
configura_ritmo_onda:
    loadn r2, #150
    mul r1, r1, r2
    sub r0, r0, r1
configura_ritmo_salva:
grava_ritmo:
    store intervalo, r0
    ; O primeiro toque anda na hora. Os demais passos dao tempo para mirar.
    loadn r1, #2
    div r1, r0, r1
    load r2, fase_atual
    loadn r3, #4
    cmp r2, r3
    jne grava_deslize
    ; Na fase Patrulha, segurar a mira na mesma coluna ajuda.
    mov r1, r0
grava_deslize:
    add r0, r0, r1
    store nave_intervalo, r0
    rts

; Durante a pausa so ha leitura de teclado. Nenhum contador do jogo avanca.
jogo_pausa:
    loadn r0, #1124
    loadn r1, #linha_hud_vazia
    loadn r2, #0
    call imprime_str
    loadn r1, #hud_pausa
    loadn r2, #2816
    call imprime_str
pausa_espera:
    call espera_tecla
    loadn r1, #'p'
    cmp r0, r1
    jeq pausa_volta
    loadn r1, #'P'
    cmp r0, r1
    jne pausa_espera
pausa_volta:
    loadn r0, #1124
    loadn r1, #jogo_armas
    loadn r2, #1792
    call imprime_str
    jmp jogo_loop

; Dois tiros verticais nas pontas da nave; nunca sai das bordas.
dispara_rajada:
    ; So usa slots vazios do vetor de 32 tiros. Se estiver cheio, nao sobrescreve.
    ; Com tiro duplo, as posicoes sao uma coluna a esquerda e outra a direita.
    load r0, recarga
    loadn r1, #0
    cmp r0, r1
    jne rajada_fim
    load r0, nave_pos
    loadn r1, #40
    sub r0, r0, r1
    store rajada_pos, r0
    loadn r1, #1
    store rajada_restante, r1
    load r2, duplo_tempo
    loadn r1, #0
    cmp r2, r1
    jeq rajada_procura_inicio
    dec r0
    store rajada_pos, r0
    loadn r1, #2
    store rajada_restante, r1
rajada_procura_inicio:
    loadn r7, #tiros
    loadn r6, #0
rajada_procura:
    loadi r0, r7
    loadn r1, #0
    cmp r0, r1
    jeq rajada_cria
rajada_proximo:
    inc r7
    inc r6
    loadn r1, #32
    cmp r6, r1
    jne rajada_procura
    jmp rajada_recarga
rajada_cria:
    loadn r0, #tiro_direcoes
    add r0, r0, r6
    loadn r1, #0
    storei r0, r1
    load r0, rajada_pos
    storei r7, r0
    call verifica_acerto
    loadi r0, r7
    loadn r1, #0
    cmp r0, r1
    jeq rajada_avanca
    call desenha_tiro
rajada_avanca:
    load r0, rajada_restante
    dec r0
    store rajada_restante, r0
    loadn r1, #0
    cmp r0, r1
    jeq rajada_recarga
    load r0, rajada_pos
    loadn r1, #2
    add r0, r0, r1
    store rajada_pos, r0
    jmp rajada_proximo
rajada_recarga:
    loadn r0, #2
    store recarga, r0
rajada_fim:
    rts

; Entrada: r5 aponta para o inimigo atingido, usado como origem do bonus.
; Conserva r0-r2 e os indices dos loops chamadores.
registra_acerto:
    push r0
    push r1
    push r2
    load r0, combo
    loadn r1, #5
    cmp r0, r1
    jeq combo_soma
    inc r0
    store combo, r0
; Dez pontos vezes o combo. O limite de 60000 deixa margem nas contas de 16 bits.
combo_soma:
    loadn r1, #10
    mul r0, r0, r1
    load r1, pontos
    add r0, r0, r1
    loadn r1, #60000
    cmp r0, r1
    jle pontos_salva
    mov r0, r1
pontos_salva:
    store pontos, r0
    load r1, recorde
    cmp r0, r1
    jle pontos_recorde_pronto
    store recorde, r0
; Renova o prazo do combo a cada acerto. A cada quatro acertos tenta criar
; um bonus, mas nunca substitui outro que ainda esteja caindo.
pontos_recorde_pronto:
    loadn r0, #45
    store combo_tempo, r0
    load r0, bonus_contador
    inc r0
    store bonus_contador, r0
    loadn r1, #4
    cmp r0, r1
    jne bonus_spawn_fim
    loadn r0, #0
    store bonus_contador, r0
    load r0, bonus_pos
    loadn r1, #0
    cmp r0, r1
    jne bonus_spawn_fim
    loadi r0, r5
    store bonus_pos, r0
    load r0, bonus_ciclo
    inc r0
    loadn r1, #3
    cmp r0, r1
    jle bonus_tipo_salva
    loadn r0, #1
bonus_tipo_salva:
    store bonus_ciclo, r0
    store bonus_tipo, r0
bonus_spawn_fim:
    call extras_placar
    pop r2
    pop r1
    pop r0
    rts

; Qualquer dano quebra o combo. O escudo vale para a base inteira: absorve
; tanto um inimigo que passou quanto um laser inimigo que acertou a nave.
recebe_dano:
    loadn r0, #0
    store combo, r0
    store combo_tempo, r0
    load r0, escudo
    loadn r1, #0
    cmp r0, r1
    jeq dano_vida
    loadn r0, #0
    store escudo, r0
    jmp dano_placar
dano_vida:
    load r0, vidas
    loadn r1, #0
    cmp r0, r1
    jeq dano_placar
    dec r0
    store vidas, r0
dano_placar:
    call jogo_placar
    call extras_placar
    rts

; Temporizadores medidos em quadros, sem depender da repeticao do teclado.
extras_quadro:
    load r0, resultado
    loadn r1, #0
    cmp r0, r1
    jne extras_quadro_fim
    load r0, combo_tempo
    cmp r0, r1
    jeq extras_duplo
    dec r0
    store combo_tempo, r0
    cmp r0, r1
    jne extras_duplo
    store combo, r0
    call extras_placar
extras_duplo:
    load r0, duplo_tempo
    loadn r1, #0
    cmp r0, r1
    jeq extras_bonus
    dec r0
    store duplo_tempo, r0
    cmp r0, r1
    jne extras_bonus
    call extras_placar
extras_bonus:
    call bonus_atualiza
extras_quadro_fim:
    rts

; O bonus cai uma linha por quadro. Ao chegar a linha da nave, compara as
; tres casas do jogador. Se passar longe, some sem aplicar o efeito.
bonus_atualiza:
    load r0, bonus_pos
    loadn r1, #0
    cmp r0, r1
    jeq bonus_fim
    call apaga_tiro
    loadn r1, #40
    add r0, r0, r1
    store bonus_pos, r0
    loadn r1, #1040
    cmp r0, r1
    jle bonus_desenha
    loadn r1, #1080
    cmp r0, r1
    jgr bonus_remove
    load r1, nave_pos
    dec r1
    cmp r0, r1
    jeq bonus_coleta
    inc r1
    cmp r0, r1
    jeq bonus_coleta
    inc r1
    cmp r0, r1
    jeq bonus_coleta
    jmp bonus_remove
; A coleta escolhe o efeito pelo tipo, e nao pelo caractere desenhado na tela.
bonus_coleta:
    load r0, bonus_tipo
    loadn r1, #1
    cmp r0, r1
    jeq bonus_duplo
    loadn r1, #2
    cmp r0, r1
    jeq bonus_escudo
    loadn r0, #6
    store energia, r0
    call ultimate_placar
    jmp bonus_remove
bonus_duplo:
    loadn r0, #180
    store duplo_tempo, r0
    call extras_placar
    jmp bonus_remove
bonus_escudo:
    loadn r0, #1
    store escudo, r0
    call extras_placar
bonus_remove:
    loadn r0, #0
    store bonus_pos, r0
    call desenha_nave
    rts
bonus_desenha:
    load r1, bonus_tipo
    loadn r2, #1
    cmp r1, r2
    jeq bonus_letra_duplo
    loadn r2, #2
    cmp r1, r2
    jeq bonus_letra_escudo
    loadn r1, #530 ; bonus de energia
    jmp bonus_imprime
bonus_letra_duplo:
    loadn r1, #2832 ; bonus de tiro duplo
    jmp bonus_imprime
bonus_letra_escudo:
    loadn r1, #3601 ; bonus de escudo
bonus_imprime:
    outchar r1, r0
bonus_fim:
    rts

; Atualiza pontos, combo, efeitos e fase/onda nas quatro primeiras linhas.
; Os push/pop permitem chamar esta rotina de dentro das colisoes.
extras_placar:
    push r0
    push r1
    push r2
    push r3
    loadn r0, #84
    loadn r1, #hud_pontos
    loadn r2, #2816
    call imprime_str
    load r0, pontos
    loadn r1, #89
    call imprime_cinco
    ; HUD fica nas quatro primeiras linhas, nunca na arena.
    loadn r0, #74
    loadn r1, #hud_combo
    call imprime_str
    load r0, combo
    loadn r1, #'0'
    add r0, r0, r1
    loadn r1, #75
    outchar r0, r1
    loadn r1, #hud_duplo
    loadn r0, #98
    call imprime_str
    load r0, duplo_tempo
    loadn r1, #0
    cmp r0, r1
    jeq hud_duplo_zero
    loadn r0, #1
hud_duplo_zero:
    loadn r1, #'0'
    add r0, r0, r1
    loadn r1, #100
    outchar r0, r1
    loadn r0, #103
    loadn r1, #hud_escudo
    call imprime_str
    load r0, escudo
    loadn r1, #'0'
    add r0, r0, r1
    loadn r1, #105
    outchar r0, r1
    loadn r0, #124
    loadn r1, #hud_onda
    load r3, modo_infinito
    loadn r2, #0
    cmp r3, r2
    jne hud_modo_onda
    loadn r1, #hud_fase
hud_modo_onda:
    loadn r2, #2816
    call imprime_str
    load r0, onda_numero
    loadn r2, #0
    cmp r3, r2
    jne hud_modo_numero
    load r0, fase_atual
hud_modo_numero:
    loadn r1, #129
    call imprime_numero
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; Entrada: r0 = valor, r1 = posicao inicial. Escreve cinco digitos com zeros.
; Comeca em 10000 e divide o divisor por 10 depois de escrever cada casa.
imprime_cinco:
    push r0
    push r1
    push r2
    push r3
    loadn r2, #10000
cinco_loop:
    div r3, r0, r2
    push r0
    loadn r0, #'0'
    add r3, r3, r0
    outchar r3, r1
    pop r0
    mod r0, r0, r2
    inc r1
    loadn r3, #10
    div r2, r2, r3
    loadn r3, #0
    cmp r2, r3
    jne cinco_loop
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; Pontos da tentativa e melhor pontuacao aparecem juntos na tela de resultado.
resultado_pontos:
    loadn r0, #564
    loadn r1, #hud_pontos
    loadn r2, #2816
    call imprime_str
    load r0, pontos
    loadn r1, #569
    call imprime_cinco
    loadn r0, #576
    loadn r1, #hud_recorde
    call imprime_str
    load r0, recorde
    loadn r1, #585
    call imprime_cinco
    loadn r0, #844
    loadn r1, #hud_bonus
    loadn r2, #512
    call imprime_str
    rts

; Chefe usa o primeiro slot; os vinte acertos sao seus pontos de vida.
colisao_chefe:
    ; Entrada: r0 = posicao do tiro, r5 = slot do alvo. Saida: r2 = 1 se acertou.
    ; O centro menos 3 e mais 3 corresponde aos sete caracteres do chefe.
    loadn r2, #0
    load r1, fase_atual
    loadn r3, #7
    cmp r1, r3
    jne colisao_chefe_fim
    loadi r1, r5
    loadn r3, #3
    sub r1, r1, r3
    cmp r0, r1
    jle colisao_chefe_esquerda
    loadn r3, #6
    add r1, r1, r3
    cmp r0, r1
    jgr colisao_chefe_fim
    loadn r2, #1
    rts
colisao_chefe_esquerda:
    jne colisao_chefe_fim
    loadn r2, #1
colisao_chefe_fim:
    rts

apaga_alvo:
    push r1
    push r2
    load r1, fase_atual
    loadn r2, #7
    cmp r1, r2
    pop r2
    pop r1
    jeq apaga_chefe
    jmp apaga_sprite

apaga_chefe:
    push r0
    push r1
    push r2
    loadn r2, #3
    sub r0, r0, r2
    loadn r1, #chefe_vazio
    loadn r2, #0
    call imprime_str
    pop r2
    pop r1
    pop r0
    rts

desenha_chefe:
    push r0
    push r1
    push r2
    loadn r2, #3
    sub r0, r0, r2
    loadn r1, #chefe_sprite
    loadn r2, #2304
    call imprime_str
    pop r2
    pop r1
    pop r0
    rts

; O chefe anda a cada dois quadros, sem descer. Limites nas colunas 4 e 35
; deixam espaco para as tres pontas de cada lado. Depois de mover, testa
; tambem se algum tiro que ja estava na tela ficou sobre ele.
chefe_atualiza:
    load r0, resultado
    loadn r1, #0
    cmp r0, r1
    jne chefe_fim
    load r0, alvo_tempo
    inc r0
    store alvo_tempo, r0
    loadn r1, #2
    cmp r0, r1
    jne chefe_fim
    loadn r0, #0
    store alvo_tempo, r0
    load r0, alvos
    call apaga_chefe
    load r1, direcoes
    loadn r2, #0
    cmp r1, r2
    jeq chefe_esquerda
    inc r0
    loadn r1, #315
    cmp r0, r1
    jne chefe_salva
    loadn r1, #0
    store direcoes, r1
    jmp chefe_salva
chefe_esquerda:
    dec r0
    loadn r1, #284
    cmp r0, r1
    jne chefe_salva
    loadn r1, #1
    store direcoes, r1
chefe_salva:
    store alvos, r0
    loadn r7, #tiros
    loadn r6, #0
chefe_colisoes:
    call verifica_acerto
    inc r7
    inc r6
    loadn r1, #32
    cmp r6, r1
    jne chefe_colisoes
    load r0, alvos
    call desenha_chefe
chefe_fim:
    rts

; Permite um laser inimigo por vez. Os drones revezam os disparos,
; e o chefe tem uma cadencia propria. O laser segue reto na coluna de origem.
inimigo_dispara:
    load r0, resultado
    loadn r1, #0
    cmp r0, r1
    jne inimigo_tiro_fim
    load r0, aviso_disparo
    cmp r0, r1
    jeq inimigo_testa_tiro
    call apaga_tiro
    store aviso_disparo, r1
inimigo_testa_tiro:
    load r0, tiro_inimigo
    cmp r0, r1
    jne inimigo_tiro_move
    load r0, tiro_inimigo_tempo
    inc r0
    store tiro_inimigo_tempo, r0
    loadn r1, #18
    loadn r2, #25
    load r3, fase_atual
    loadn r4, #7
    cmp r3, r4
    jne inimigo_testa_aviso
    loadn r1, #10
    loadn r2, #16
inimigo_testa_aviso:
    cmp r0, r1
    jle inimigo_tiro_fim
    mov r3, r0
    load r0, atirador
    loadn r1, #alvos
    add r0, r0, r1
    loadi r0, r0
    loadn r1, #40
    add r0, r0, r1
    ; Deixa pelo menos tres linhas para reagir ao laser.
    loadn r1, #920
    cmp r0, r1
    jgr inimigo_proximo_atirador
    cmp r3, r2
    jgr inimigo_lanca_tiro
    store aviso_disparo, r0
    rts
inimigo_lanca_tiro:
    store tiro_inimigo, r0
inimigo_proximo_atirador:
    loadn r0, #0
    store tiro_inimigo_tempo, r0
    load r0, atirador
    inc r0
    load r1, quantidade_inimigos
    mod r0, r0, r1
    store atirador, r0
    rts
inimigo_tiro_move:
    call apaga_tiro
    loadn r1, #40
    add r0, r0, r1
    store tiro_inimigo, r0
    loadn r1, #1040
    cmp r0, r1
    jle inimigo_tiro_fim
    load r1, nave_pos
    dec r1
    cmp r0, r1
    jeq inimigo_tiro_dano
    inc r1
    cmp r0, r1
    jeq inimigo_tiro_dano
    inc r1
    cmp r0, r1
    jne inimigo_tiro_remove
inimigo_tiro_dano:
    call recebe_dano
    load r0, vidas
    loadn r1, #0
    cmp r0, r1
    jne inimigo_tiro_remove
    loadn r0, #2
    store resultado, r0
inimigo_tiro_remove:
    loadn r0, #0
    store tiro_inimigo, r0
    call desenha_nave
    rts
inimigo_tiro_desenha:
    loadn r1, #2319 ; laser vermelho, tile 15
    outchar r1, r0
inimigo_tiro_fim:
    rts

; Repinta todas as camadas apos mover: uma explosao ou bonus nao apaga
; partes de outra nave. A onda aparece na frente dos demais objetos.
arena_redesenha:
    call desenha_estrelas
    load r0, aviso_disparo
    loadn r1, #0
    cmp r0, r1
    jeq arena_desenha_objetos
    loadn r1, #2844 ; luz de carga amarela, tile 28
    outchar r1, r0
arena_desenha_objetos:
    call onda_redesenha
    load r0, bonus_pos
    loadn r1, #0
    cmp r0, r1
    jeq arena_tiro_inimigo
    call bonus_desenha
arena_tiro_inimigo:
    load r0, tiro_inimigo
    loadn r1, #0
    cmp r0, r1
    jeq arena_onda
    call inimigo_tiro_desenha
arena_onda:
    load r0, onda_linha
    loadn r1, #0
    cmp r0, r1
    jeq arena_fim
    loadn r1, #1
    call onda_pinta
arena_fim:
    rts

; Muda o brilho em grupos, para o fundo nunca piscar inteiro.
pulsa_estrelas:
    load r0, estrelas_tempo
    inc r0
    store estrelas_tempo, r0
    loadn r1, #6
    cmp r0, r1
    jne pulsa_estrelas_fim
    loadn r0, #0
    store estrelas_tempo, r0
    load r0, estrelas_fase
    inc r0
    loadn r1, #4
    mod r0, r0, r1
    store estrelas_fase, r0
pulsa_estrelas_fim:
    rts

; Fundo primeiro, depois naves e tiros. As estrelas nao entram nas colisoes.
desenha_estrelas:
    loadn r0, #estrelas_pos
    loadn r1, #32
    load r2, estrelas_fase
    loadn r5, #4
estrelas_loop:
    loadi r3, r0
    loadn r4, #2074 ; ponto cinza (tile 26)
    mod r6, r2, r5
    loadn r7, #0
    cmp r6, r7
    jeq estrela_acesa
    loadn r7, #2
    cmp r6, r7
    jne estrela_pinta
    loadn r4, #1050 ; ponto azul escuro
    jmp estrela_pinta
estrela_acesa:
    loadn r4, #1819 ; brilho prateado (tile 27)
estrela_pinta:
    outchar r4, r3
    inc r0
    inc r2
    dec r1
    loadn r7, #0
    cmp r1, r7
    jne estrelas_loop
    rts
