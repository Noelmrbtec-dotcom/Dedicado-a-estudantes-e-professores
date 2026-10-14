; =================================================================================
; Entendendo funcionamento de processadores (Z80) Zilog
; Autor: Marcos Roberto Braga
; Data: 14/10/2025
; Aluno: Pedro Henrique Cerqueira Braga
;
; TESTE DA INSTRUÇÃO: ADD A,(HL)  —  opcode 86h
;
; OBJETIVO:
;   Demonstrar o uso da instrução ADD A,(HL) do Z80, que soma o conteúdo
;   da memória apontada por HL ao acumulador A.
;
;   Os valores do vetor foram escolhidos para FORÇAR a
;   flag H (Half-Carry) a ser setada, permitindo ao aluno visualizar
;   o efeito do carry do nibble baixo para o nibble alto.
;
;   Este exemplo ensina, na prática:
;     - Instrução ADD A,(HL) — soma com operando em memória
;     - Uso do par HL como ponteiro de memória
;     - Acumulação de valores em um vetor
;     - Efeito nas flags (S, Z, H, P/V, N, C)
;     - COMO A FLAG H REFLETE O CARRY DO NIBBLE BAIXO
;     - Reprodução do resultado nas Portas A e C do PPI1
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
    ; 2. PREPARAÇÃO DO VETOR NA MEMÓRIA
    ; ******************************************************************
    ; Vamos somar 4 valores armazenados em memória, a partir do
    ; endereço VETOR. O par HL apontará para o início do vetor.
    ;
    ; Vetor escolhido: 0Fh, 01h, 08h, 04h
    ;
    ; Cálculo esperado:
    ;   00h + 0Fh = 0Fh  → H = 0
    ;   0Fh + 01h = 10h  → H = 1  ← CARRY DO NIBBLE BAIXO!
    ;   10h + 08h = 18h  → H = 0
    ;   18h + 04h = 1Ch  → H = 0
    ;
    ; Resultado final: A = 1Ch, H = 0 (última operação), C = 0
    ; ------------------------------------------------------------------
    ld hl, VETOR              ; HL aponta para o início do vetor

    ; ******************************************************************
    ; 3. SOMA DO VETOR COM ADD A,(HL)
    ; ******************************************************************
    ; A instrução ADD A,(HL) soma o conteúdo apontado por HL ao
    ; acumulador A.
    ;
    ;   A ← A + (HL)
    ;
    ; A cada iteração, incrementamos HL para apontar para o próximo
    ; valor do vetor.
    ;
    ; [DIDÁTICO] A flag H é alterada a cada iteração. Na 2ª iteração,
    ;            ela é setada (H = 1) porque Fh + 1h gera carry do
    ;            nibble baixo para o nibble alto.
    ; ------------------------------------------------------------------
    xor a                     ; A = 0 (limpa o acumulador)
    ld b, 04h                 ; B = 4 (contador: 4 valores a somar)

loop_soma:
    add a, (hl)               ; A ← A + (HL)  (afeta S, Z, H, P/V, N, C)
    inc hl                    ; Avança para o próximo valor
    djnz loop_soma            ; Repete até somar todos

    ; ******************************************************************
    ; 4. REPRODUÇÃO DO RESULTADO NAS PORTAS A E C
    ; ******************************************************************
    ; O resultado da soma fica em A (1Ch). Vamos exibir esse valor
    ; nas duas portas de saída do PPI1 (A e C), simultaneamente.
    ; ------------------------------------------------------------------
    out (porta), a            ; Porta A = 1Ch (LEDs: 0001 1100b)
    out (portc), a            ; Porta C = 1Ch (LEDs: 0001 1100b)

    ; ******************************************************************
    ; 5. LOOP INFINITO — Alterna padrão de teste e resultado
    ; ******************************************************************
    ; Para tornar o efeito visível, o programa alterna entre:
    ;   - Mostrar o resultado da soma nas duas portas
    ;   - Mostrar a flag H em um bit específico (teste visual)
    ; ------------------------------------------------------------------

loop_principal:
    ; --- Fase 1: mostra o resultado da soma (1Ch) ---
    ld a, (RESULTADO)         ; Recupera o resultado guardado
    out (porta), a            ; Porta A = resultado
    out (portc), a            ; Porta C = resultado
    call delay_curto          ; Aguarda

    ; --- Fase 2: mostra padrão para confirmar flag H ---
    ; Para visualizar a flag H, usamos um padrão fixo:
    ;   0Fh + 01h é refeito para forçar H = 1.
    ;   Exibimos o resultado (10h) nas duas portas.
    ld a, 0Fh                 ; A = 0Fh
    add a, 01h                ; A = 10h, H = 1  ← aqui H é setada
    out (porta), a            ; Porta A = 10h
    out (portc), a            ; Porta C = 10h
    call delay_curto

    jp loop_principal         ; Repete indefinidamente

; =================================================================================
; DADOS NA MEMÓRIA
; =================================================================================
; Vetor de 4 valores escolhidos para FORÇAR a flag H na 2ª iteração.
;
; Cálculo esperado:
;   00h + 0Fh = 0Fh  → H = 0, C = 0
;   0Fh + 01h = 10h  → H = 1, C = 0  ← CARRY DO NIBBLE BAIXO
;   10h + 08h = 18h  → H = 0, C = 0
;   18h + 04h = 1Ch  → H = 0, C = 0
;
; Resultado final: A = 1Ch
; =================================================================================
    org 0100h                 ; Endereço do vetor (evita conflito com código)

VETOR:
    db 0Fh                    ; Valor 1 — prepara o nibble baixo cheio
    db 01h                    ; Valor 2 — FORÇA H = 1 (Fh + 1h = 10h)
    db 08h                    ; Valor 3
    db 04h                    ; Valor 4

RESULTADO:
    db 1Ch                    ; Resultado pré-calculado da soma

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