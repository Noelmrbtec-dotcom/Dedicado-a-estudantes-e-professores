; =================================================================================
; Entendendo funcionamento de processadores (Z80) Zilog
; Autor: Marcos Roberto Braga
; Data: 17/09/2025
; Aluno: Pedro Henrique Cerqueira Braga
; Deslocamentos com SLA e SRA
;
; OBJETIVO:
;   Demonstrar o uso das instruções SLA (Shift Left Arithmetic) e SRA
;   (Shift Right Arithmetic) do Z80, com o resultado sendo exibido nas
;   Portas A e C do PPI1 (LEDs).
;
;   Este exemplo ensina, na prática:
;     - Instrução SLA (deslocamento aritmético à esquerda)
;     - Instrução SRA (deslocamento aritmético à direita)
;     - Como o deslocamento afeta os bits e as flags
;     - Uso de contadores com DJNZ
;     - Escrita em múltiplas portas de I/O
;
; HARDWARE MAPEADO:
;   PPI1: porta   = 00h (Porta A — SAÍDA, LEDs)
;         portb   = 01h (Porta B — ENTRADA, chaves)
;         portc   = 02h (Porta C — SAÍDA, LEDs)
;         ppi_confg1 = 03h (Registrador de controle)
; =================================================================================

; =================================================================================
; MAPEAMENTO DE I/O — PPI 1 (8255)
; =================================================================================
porta      = 00h    ; Porta A do PPI1 (SAÍDA — LEDs)
portb      = 01h    ; Porta B do PPI1 (ENTRADA — chaves)
portc      = 02h    ; Porta C do PPI1 (SAÍDA — LEDs)
ppi_confg1 = 03h    ; Registrador de controle do PPI1

; =================================================================================
; --- Vetor de RESET ---
; =================================================================================
    org 0000h
    jp inicio

; =================================================================================
; --- Vetor de Interrupção ---
; =================================================================================
    org 0038h
    reti              ; Retorno de interrupção mascarável (INT)

    org 0066h
    retn              ; Retorno de interrupção não-mascárável (NMI)

; =================================================================================
; --- Programa Principal ---
; =================================================================================
    org 0030h

inicio:
    ld sp, FFFFh              ; Inicializa o Stack Pointer no topo da RAM

    ; ******************************************************************
    ; 1. CONFIGURAÇÃO DA PPI1 — Modo 0
    ;    Porta A = SAÍDA (LEDs)
    ;    Porta B = ENTRADA (chaves)
    ;    Porta C = SAÍDA (LEDs)
    ; ******************************************************************
    ; Byte de controle:
    ;   1000 0010b = 82h
    ;       │││
    ;       ││└── Porta C (baixa): saída
    ;       │└─── Porta B: ENTRADA
    ;       └──── Porta A: saída
    ; ------------------------------------------------------------------
    ld a, 82h                 ; 82h = Modo 0, A=out, B=in, C=out
    out (ppi_confg1), a       ; Configura o PPI1

    ; ******************************************************************
    ; 2. EXEMPLO 1: SLA — Deslocamento à esquerda
    ; ******************************************************************
    ; A instrução SLA desloca o acumulador (ou registrador) um bit
    ; para a esquerda. O bit 7 vai para o Carry (flag C), e o bit 0
    ; recebe 0.
    ;
    ;   Antes:  [b7 b6 b5 b4 b3 b2 b1 b0]
    ;   Depois: [b6 b5 b4 b3 b2 b1 b0  0]  → Carry = b7
    ;
    ; Este é o equivalente a multiplicar por 2.
    ; ------------------------------------------------------------------
    ld a, 01h                 ; A = 0000 0001b
    out (porta), a            ; Mostra o valor inicial na Porta A

    sla a                     ; A = 0000 0010b (Carry = 0)
    out (porta), a            ; Mostra o resultado na Porta A

    sla a                     ; A = 0000 0100b (Carry = 0)
    out (porta), a            ; Mostra o resultado na Porta A

    sla a                     ; A = 0000 1000b (Carry = 0)
    out (porta), a            ; Mostra o resultado na Porta A

    sla a                     ; A = 0001 0000b (Carry = 0)
    out (porta), a            ; Mostra o resultado na Porta A

    sla a                     ; A = 0010 0000b (Carry = 0)
    out (porta), a            ; Mostra o resultado na Porta A

    sla a                     ; A = 0100 0000b (Carry = 0)
    out (porta), a            ; Mostra o resultado na Porta A

    sla a                     ; A = 1000 0000b (Carry = 0)
    out (porta), a            ; Mostra o resultado na Porta A

    sla a                     ; A = 0000 0000b (Carry = 1)
    out (porta), a            ; Mostra o resultado na Porta A
                              ; O bit 7 foi para o Carry

    ; ******************************************************************
    ; 3. EXEMPLO 2: SRA — Deslocamento à direita
    ; ******************************************************************
    ; A instrução SRA desloca o acumulador (ou registrador) um bit
    ; para a direita. O bit 0 vai para o Carry (flag C), e o bit 7
    ; é preservado (shift aritmético).
    ;
    ;   Antes:  [b7 b6 b5 b4 b3 b2 b1 b0]
    ;   Depois: [b7 b7 b6 b5 b4 b3 b2 b1]  → Carry = b0
    ;
    ; Este é o equivalente a dividir por 2 (com sinal).
    ; ------------------------------------------------------------------
    ld a, 80h                 ; A = 1000 0000b
    out (portc), a            ; Mostra o valor inicial na Porta C

    sra a                     ; A = 1100 0000b (Carry = 0)
    out (portc), a            ; Mostra o resultado na Porta C

    sra a                     ; A = 1110 0000b (Carry = 0)
    out (portc), a            ; Mostra o resultado na Porta C

    sra a                     ; A = 1111 0000b (Carry = 0)
    out (portc), a            ; Mostra o resultado na Porta C

    sra a                     ; A = 1111 1000b (Carry = 0)
    out (portc), a            ; Mostra o resultado na Porta C

    sra a                     ; A = 1111 1100b (Carry = 0)
    out (portc), a            ; Mostra o resultado na Porta C

    sra a                     ; A = 1111 1110b (Carry = 0)
    out (portc), a            ; Mostra o resultado na Porta C

    sra a                     ; A = 1111 1111b (Carry = 0)
    out (portc), a            ; Mostra o resultado na Porta C

    sra a                     ; A = 1111 1111b (Carry = 1)
    out (portc), a            ; Mostra o resultado na Porta C
                              ; O bit 0 foi para o Carry

    ; ******************************************************************
    ; 4. LOOP PRINCIPAL — Alterna entre SLA e SRA continuamente
    ; ******************************************************************
    ; A cada ciclo, o programa faz um deslocamento à esquerda (SLA)
    ; na Porta A e um deslocamento à direita (SRA) na Porta C.
    ;
    ; O resultado visual é um efeito de "corrida" nos LEDs:
    ;   Porta A: bit 0 acende, depois bit 1, depois bit 2...
    ;   Porta C: bit 7 acende, depois bit 6, depois bit 5...
    ; ------------------------------------------------------------------

loop_principal:
    ; --- SLA na Porta A ---
    ld a, 01h                 ; A = 0000 0001b
    ld b, 8                   ; 8 iterações

loop_sla:
    out (porta), a            ; Mostra o valor atual na Porta A
    sla a                     ; Desloca para a esquerda
    push af                   ; Salva A e F (para não corromper o loop)
    call delay_curto          ; Aguarda um pouco
    pop af                    ; Restaura A e F
    djnz loop_sla             ; Repete 8 vezes

    ; --- SRA na Porta C ---
    ld a, 80h                 ; A = 1000 0000b
    ld b, 8                   ; 8 iterações

loop_sra:
    out (portc), a            ; Mostra o valor atual na Porta C
    sra a                     ; Desloca para a direita
    push af                   ; Salva A e F (para não corromper o loop)
    call delay_curto          ; Aguarda um pouco
    pop af                    ; Restaura A e F
    djnz loop_sra             ; Repete 8 vezes

    ; --- Volta ao início do loop ---
    jp loop_principal         ; Repete indefinidamente

; =================================================================================
; SUB-ROTINA: delay_curto
; =================================================================================
; Gera um atraso curto, usando o par BC como contador.
; Para delays mais longos, aumente o valor de BC.
;
; IMPORTANTE:
;   Esta sub-rotina salva e restaura AF e BC, para não corromper
;   o acumulador A nem o contexto dos registradores.
; =================================================================================
delay_curto:
    push af                 ; Salva A e F (para não corromper o padrão)
    push bc                 ; Salva BC (para não corromper o chamador)
    ld bc, 0001h            ; Valor do contador (ajustar conforme a
                            ; velocidade do clock)
delay_loop:
    dec bc                  ; Decrementa BC
    ld a, b                 ; Carrega B em A
    or c                    ; OR com C — se ambos forem 0, o resultado é 0
    jr nz, delay_loop       ; Se não for zero, repete
    pop bc                  ; Restaura BC
    pop af                  ; Restaura A e F
    ret                     ; Retorna

; =================================================================================
.end
;**************************Fim******************************************************