; =================================================================================
; Entendendo funcionamento de processadores (Z80) Zilog
; Autor: Marcos Roberto Braga
; Data: 17/09/2025
; Aluno: Pedro Henrique Cerqueira Braga
;
; TESTE DA INSTRUÇÃO: IN B,(C)  —  opcode ED 40h
;
; OBJETIVO:
;   Demonstrar o uso da instrução IN B,(C) do Z80, que realiza leitura
;   de porta de I/O de forma INDIRETA (endereço contido em C).
;
;   Este exemplo ensina, na prática:
;     - Instrução IN r,(C) — leitura indireta de I/O
;     - Diferença entre IN A,(n) e IN r,(C)
;     - Como as flags são afetadas (S, Z, H, P/V, N)
;     - Uso combinado com OUT (C),r para espelhar entradas
;
; HARDWARE MAPEADO:
;   PPI1: porta      = 00h (Porta A — SAÍDA, LEDs)
;         portb      = 01h (Porta B — ENTRADA, chaves)
;         portc      = 02h (Porta C — SAÍDA, LEDs)
;         ppi_confg1 = 03h (Registrador de controle)
;
; CONFIGURAÇÃO DO PPI1 (8255) — Modo 0:
;   Porta A = SAÍDA   (LEDs)
;   Porta B = ENTRADA (chaves)
;   Porta C = SAÍDA   (LEDs)
;   Byte de controle: 1000 0010b = 82h
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
    ;    Porta A = SAÍDA   (LEDs)
    ;    Porta B = ENTRADA (chaves)
    ;    Porta C = SAÍDA   (LEDs)
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
    ; 2. TESTE 1: IN B,(C) — leitura indireta simples
    ; ******************************************************************
    ; Coloca o endereço da Porta B (01h) em C, e lê o valor para B.
    ; Este é o uso mais básico de IN B,(C).
    ; ------------------------------------------------------------------
    ld c, portb               ; C = 01h (endereço da Porta B = chaves)
    in b, (c)                 ; B ← conteúdo da porta apontada por C
    ld a, b                   ; Move o valor lido para A
    out (porta), a            ; Espelha o valor lido nos LEDs da Porta A

    ; ******************************************************************
    ; 3. TESTE 2: IN B,(C) lendo a mesma porta, mas escrevendo em C
    ; ******************************************************************
    ; Mesmo mecanismo, agora espelhando o resultado na Porta C.
    ; Demonstra que o mesmo código funciona para qualquer porta de saída.
    ; ------------------------------------------------------------------
    ld c, portb               ; C = 01h (Porta B — chaves)
    in b, (c)                 ; B ← conteúdo das chaves
    ld a, b
    out (portc), a            ; Espelha em Porta C (LEDs)

    ; ******************************************************************
    ; 4. TESTE 3: IN B,(C) — leitura com endereço FIXO em C
    ; ******************************************************************
    ; Demonstra que IN B,(C) usa SEMPRE o endereço em C.
    ; Como a Porta B é a única entrada, a leitura sempre aponta
    ; para 01h. O resultado é escrito nas duas saídas (A e C).
    ; ------------------------------------------------------------------
    ld c, portb               ; C = 01h (Porta B — entrada)
    in b, (c)                 ; B ← conteúdo das chaves
    ld a, b
    out (porta), a            ; Escreve na Porta A (LEDs)
    out (portc), a            ; Escreve na Porta C (LEDs)

    ; ******************************************************************
    ; 5. TESTE 4: Loop infinito — lê chaves e espelha em A e C
    ; ******************************************************************
    ; O código lê continuamente a Porta B (chaves) e espelha o valor
    ; nas duas portas de saída (A e C). O efeito visual é que os LEDs
    ; das duas portas refletem sempre o estado das chaves.
    ; ------------------------------------------------------------------

loop_leitura:
    ld c, portb               ; C = 01h (Porta B — entrada)
    in b, (c)                 ; B ← leitura das chaves
    ld a, b                   ; Move para A
    out (porta), a            ; Espelha na Porta A (LEDs)
    out (portc), a            ; Espelha na Porta C (LEDs)

    call delay_curto          ; Pequeno atraso anti-bounce
    jp loop_leitura           ; Repete indefinidamente

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
    ld bc, 0001h            ; Valor do contador (ajustar conforme clock)
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