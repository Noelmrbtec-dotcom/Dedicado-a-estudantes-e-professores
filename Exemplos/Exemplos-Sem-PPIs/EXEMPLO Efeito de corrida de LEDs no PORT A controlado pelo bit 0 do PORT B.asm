; =================================================================================
; EXEMPLO 11: Corrida de LEDs no PORT A controlada pelo bit 0 do PORT B
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique C. Braga
; Plataforma: Z80-EMU (PIC18F6722)
;
; OBJETIVO:
;   Demonstrar leitura de porta de entrada (PORT B), teste de bit (BIT),
;   desvio condicional (JR cc,e) e dois efeitos visuais distintos no PORT A:
;
;     - Bit 0 do PORT B = 0  ->  corrida para a esquerda (RLCA)
;     - Bit 0 do PORT B = 1  ->  corrida para a direita  (RRCA)
;
; MAPA DE PORTAS:
;   PORT A (01h) = SAIDA   -> 8 LEDs (efeito de corrida)
;   PORT B (02h) = ENTRADA -> bit 0 seleciona o sentido
;
; DELAY:
;   Usa a sub-rotina delay_curto com BC = 0001h.
;   Delay curto o suficiente para Proteus, mas ideal para observar
;   o efeito no depurador. Para acelerar/desacelerar, ajuste o valor
;   de BC em delay_curto.
;
; OBSERVACAO IMPORTANTE:
;   A variavel "estado" e inicializada POR CODIGO (LD (estado),A), e nao
;   por "ORG 80F0h / DB 01h". Isso garante que o valor inicial seja
;   gravado na RAM independentemente do procedimento de carga do .hex.
;
; TECNICAS DEMONSTRADAS:
;   - IN A,(n)         leitura de porta de entrada
;   - BIT b,r          teste de bit individual
;   - JR Z,e / JR NZ,e desvio condicional relativo
;   - RLCA / RRCA      rotacao circular do acumulador (efeito de corrida)
;   - DJNZ e           loop com decremento de B
;   - OUT (n),A        escrita em porta de saida
;   - CALL nn / RET    sub-rotina de delay
;   - PUSH AF / POP AF preservacao do acumulador
; =================================================================================

; ---------------------------------------------------------------------------------
; Definicoes de portas e constantes
; ---------------------------------------------------------------------------------
porta        = 01h        ; PORT A - saida (8 LEDs)
portb        = 02h        ; PORT B - entrada (bit 0 = seletor de sentido)
estado       = 80F0h      ; endereco da variavel de estado na RAM

led_inicial  = 01h        ; LED inicial aceso (bit 0)

; ---------------------------------------------------------------------------------
; Vetor de reset
; ---------------------------------------------------------------------------------
    org 0000h
    jp inicio

; ---------------------------------------------------------------------------------
; Programa principal
; ---------------------------------------------------------------------------------
    org 0100h
inicio:
    ld sp, 8100h           ; SP = 8100h (RAM baixa)

    ; --- Inicializa o estado na RAM POR CODIGO (nao depende de DB em ORG alto) ---
    ld a, led_inicial      ; A = 01h
    ld (estado), a         ; (80F0h) = 01h
    out (porta), a         ; Acende LED 0 no PORT A

; ---------------------------------------------------------------------------------
; Loop principal - verifica o bit 0 do PORT B e escolhe o sentido
; ---------------------------------------------------------------------------------
loop_principal:
    in a, (portb)          ; Le o estado do PORT B
    bit 0, a               ; Testa o bit 0 (Z=1 se bit 0 = 0)
    jr z, corrida_esquerda ; Se bit 0 = 0 -> corrida para a esquerda
    jr corrida_direita     ; Se bit 0 = 1 -> corrida para a direita

; ---------------------------------------------------------------------------------
; Efeito 1: corrida para a esquerda (bit 0 do PORT B = 0)
; ---------------------------------------------------------------------------------
corrida_esquerda:
    ld b, 8                ; 8 LEDs no PORT A

loop_esq:
    call delay_curto       ; Delay curto (BC = 0001h)
    in a, (portb)          ; Re-le o PORT B (permite trocar sentido em tempo real)
    bit 0, a               ; Bit 0 mudou?
    jr nz, loop_principal  ; Se mudou para 1 -> volta ao loop principal

    ld a, (estado)         ; Recupera o estado atual dos LEDs
    rlca                   ; Rotaciona para a esquerda
    ld (estado), a         ; Salva o novo estado
    out (porta), a         ; Atualiza os LEDs

    djnz loop_esq          ; Repete 8 vezes (um ciclo completo)
    jr loop_principal      ; Volta ao loop principal

; ---------------------------------------------------------------------------------
; Efeito 2: corrida para a direita (bit 0 do PORT B = 1)
; ---------------------------------------------------------------------------------
corrida_direita:
    ld b, 8                ; 8 LEDs no PORT A

loop_dir:
    call delay_curto       ; Delay curto (BC = 0001h)
    in a, (portb)          ; Re-le o PORT B (permite trocar sentido em tempo real)
    bit 0, a               ; Bit 0 mudou?
    jr z, loop_principal   ; Se mudou para 0 -> volta ao loop principal

    ld a, (estado)         ; Recupera o estado atual dos LEDs
    rrca                   ; Rotaciona para a direita
    ld (estado), a         ; Salva o novo estado
    out (porta), a         ; Atualiza os LEDs

    djnz loop_dir          ; Repete 8 vezes (um ciclo completo)
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
    push af                 ; Salva A e F (para nao corromper o padrao)
    push bc                 ; Salva BC (para nao corromper o chamador)
    ld bc, 0001h            ; Valor do contador (ajustar conforme a
                            ; velocidade do clock)
delay_loop:
    dec bc                  ; Decrementa BC
    ld a, b                 ; Carrega B em A
    or c                    ; OR com C - se ambos forem 0, o resultado e 0
    jr nz, delay_loop       ; Se nao for zero, repete
    pop bc                  ; Restaura BC
    pop af                  ; Restaura A e F
    ret                     ; Retorna

fim_programa:
;==================================================================================
    end
;**************************Fim******************************************************