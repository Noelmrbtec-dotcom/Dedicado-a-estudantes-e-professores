; =================================================================================
; EXEMPLO 12: NMI inverte o sentido da corrida de LEDs (troca de contexto com EXX)
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique C. Braga
;
; OBJETIVO:
;   Demonstrar TROCA DE CONTEXTO com NMI + EXX de forma DIDATICA:
;   ha UM UNICO efeito de corrida de LEDs no PORT A, cujo SENTIDO
;   e invertido a cada pressao do botao NMI.
;
;     - Sentido = 0  ->  corrida para a ESQUERDA (RLCA)
;     - Sentido = 1  ->  corrida para a DIREITA  (RRCA)
;
;   Ao pressionar o botao NMI, o handler em 0066h:
;     1. Salva AF do processo principal (PUSH AF)
;     2. Troca para o banco alternativo (EXX) — usa B'/C'/D'/E'/H'/L'
;     3. Inverte a flag "sentido" na RAM
;     4. Restaura o banco principal (EXX)
;     5. Restaura AF (POP AF)
;     6. RETN — volta ao processo principal
;
;   O processo principal NAO PERCEBE a interrupcao: continua do ponto
;   onde parou, mas agora com o sentido invertido.
;
; MAPA DE PORTAS:
;   PORT A (01h) = SAIDA  -> 8 LEDs (corrida)
;   NMI (RA4)    = ENTRADA -> botao que inverte o sentido
;
; POR QUE USAR EXX NO HANDLER?
;   O handler da NMI precisa usar registradores (B, C, D, E, H, L)
;   para executar sua logica. Se usasse os mesmos registradores do
;   processo principal, corromperia o estado dele. O EXX troca para
;   o banco ALTERNATIVO, que esta livre — o processo principal continua
;   intacto no banco PRINCIPAL.
;
;   AF NAO e trocado por EXX. Por isso o handler faz PUSH AF / POP AF
;   para preservar o acumulador do processo principal.
;
; TECNICAS DEMONSTRADAS:
;   - NMI + RETN       interrupcao nao-mascaravel com retorno
;   - EXX              troca BC/DE/HL entre bancos (contexto)
;   - PUSH AF/POP AF   preservacao do acumulador (EXX nao cobre AF)
;   - XOR n            inversao de bit (flag de sentido)
;   - RLCA / RRCA      rotacao circular (efeito de corrida)
;   - BIT b,r + JR     decisao condicional pelo sentido
;   - LD (nn),A / LD A,(nn) persistencia em RAM
;   - CALL nn / RET    sub-rotina de delay
; =================================================================================

; ---------------------------------------------------------------------------------
; Definicoes de portas, variaveis e constantes
; ---------------------------------------------------------------------------------
porta        = 01h        ; PORT A - saida (8 LEDs)

led_inicial  = 01h        ; LED inicial aceso (bit 0)
estado_led   = 80F0h      ; padrao atual dos LEDs (persistente)
sentido      = 80F1h      ; 0 = esquerda, 1 = direita

; ---------------------------------------------------------------------------------
; Vetor de reset
; ---------------------------------------------------------------------------------
    org 0000h
    jp inicio

; ---------------------------------------------------------------------------------
; Handler da NMI (endereco fixo 0066h) — inverte o sentido da corrida
; ---------------------------------------------------------------------------------
    org 0066h
nmi_handler:
    push af                ; 1. Salva AF do processo principal
    exx                    ; 2. Troca para banco ALTERNATIVO (B'/C'/D'/E'/H'/L')

    ; --- Inverte a flag "sentido" na RAM ---
    ld a, (sentido)        ; A = sentido atual (0 ou 1)
    xor 01h                ; inverte o bit 0 (0 -> 1, 1 -> 0)
    ld (sentido), a        ; salva o novo sentido

    exx                    ; 3. Volta ao banco PRINCIPAL
    pop af                 ; 4. Restaura AF do processo principal
    retn                   ; 5. Retorna ao processo principal

; ---------------------------------------------------------------------------------
; Programa principal — corrida de LEDs com sentido controlado pela NMI
; ---------------------------------------------------------------------------------
    org 0100h
inicio:
    ld sp, 8100h           ; SP = 8100h (RAM baixa)

    ; --- Inicializa variaveis na RAM POR CODIGO (nao depende de DB em ORG alto) ---
    ld a, led_inicial
    ld (estado_led), a     ; (80F0h) = 01h
    xor a                  ; A = 0
    ld (sentido), a        ; (80F1h) = 00h (sentido inicial = esquerda)
    ld a, led_inicial
    out (porta), a         ; Acende LED 0 no PORT A

; ---------------------------------------------------------------------------------
; Loop principal — verifica o sentido e escolhe o efeito
; ---------------------------------------------------------------------------------
loop_principal:
    ld a, (sentido)        ; Le o sentido atual
    bit 0, a               ; Testa o bit 0
    jr z, corrida_esq      ; Se 0 -> corrida para a esquerda
    jr corrida_dir         ; Se 1 -> corrida para a direita

; ---------------------------------------------------------------------------------
; Efeito: corrida para a esquerda (sentido = 0)
; ---------------------------------------------------------------------------------
corrida_esq:
    call delay_curto
    ld a, (estado_led)     ; Recupera o padrao atual dos LEDs
    rlca                   ; Rotaciona para a esquerda
    ld (estado_led), a     ; Salva o novo padrao
    out (porta), a         ; Atualiza os LEDs
    jr loop_principal      ; Volta ao loop principal

; ---------------------------------------------------------------------------------
; Efeito: corrida para a direita (sentido = 1)
; ---------------------------------------------------------------------------------
corrida_dir:
    call delay_curto
    ld a, (estado_led)     ; Recupera o padrao atual dos LEDs
    rrca                   ; Rotaciona para a direita
    ld (estado_led), a     ; Salva o novo padrao
    out (porta), a         ; Atualiza os LEDs
    jr loop_principal      ; Volta ao loop principal

; ==================================================================================
; SUB-ROTINA: delay_curto
; ==================================================================================
; Gera um atraso curto, usando o par BC como contador.
; Para delays mais longos, aumente o valor de BC.
;
; IMPORTANTE:
;   Esta sub-rotina salva e restaura AF e BC, para nao corromper
;   o acumulador A (que contem o padrao dos LEDs).
; ==================================================================================
delay_curto:
    push af                 ; Salva A e F
    push bc                 ; Salva BC
    ld bc, 0001h            ; Valor do contador (ajustar conforme clock)
delay_loop:
    dec bc                  ; Decrementa BC
    ld a, b                 ; Carrega B em A
    or c                    ; OR com C — se ambos forem 0, resultado e 0
    jr nz, delay_loop       ; Se nao for zero, repete
    pop bc                  ; Restaura BC
    pop af                  ; Restaura A e F
    ret                     ; Retorna

fim_programa:
;==================================================================================
    end
;**************************Fim******************************************************