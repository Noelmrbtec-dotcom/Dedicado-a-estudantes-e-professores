; =================================================================================
; Entendendo funcionamento de processadores (Z80) Zilog
; Autor: Marcos Roberto Braga
; Data: 17/09/2025
; Aluno: Pedro Henrique Cerqueira Braga
; Troca de contexto com EXX
;
; OBJETIVO:
;   Demonstrar o uso da instrução EXX (Exchange) para troca de contexto.
;   O Z80 possui dois conjuntos de registradores (BC, DE, HL) e (BC', DE', HL').
;   A instrução EXX alterna entre eles, permitindo "trocar de contexto"
;   sem salvar nada na pilha.
;
;   Este exemplo ensina, na prática:
;     - Instrução EXX (troca de registradores)
;     - Contexto primário vs. contexto alternativo
;     - Uso do EXX para troca rápida de dados
;     - Alternância de padrões nos LEDs via troca de contexto
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
    ; 2. INICIALIZAÇÃO DOS DOIS CONTEXTOS
    ; ******************************************************************
    ; O Z80 tem dois conjuntos de registradores:
    ;   Contexto PRIMÁRIO:    BC, DE, HL
    ;   Contexto ALTERNATIVO: BC', DE', HL'
    ;
    ; A instrução EXX troca os valores entre eles.
    ;
    ; Aqui, preparamos o contexto primário com um padrão (0x55)
    ; e o contexto alternativo com outro padrão (0xAA).
    ; ------------------------------------------------------------------

    ; --- Contexto PRIMÁRIO: HL = 0x55 ---
    ld hl, 0055h              ; HL (primário) = 0x0055
                              ; L = 0x55 (padrão dos LEDs)

    ; --- Troca para o contexto ALTERNATIVO ---
    exx                       ; Agora HL' é acessível como HL

    ; --- Contexto ALTERNATIVO: HL = 0xAA ---
    ld hl, 00AAh              ; HL (alternativo) = 0x00AA
                              ; L = 0xAA (padrão dos LEDs)

    ; --- Volta para o contexto PRIMÁRIO ---
    exx                       ; Agora HL é o primário novamente

    ; ******************************************************************
    ; 3. LOOP PRINCIPAL — Alterna entre os dois contextos
    ; ******************************************************************
    ; A cada iteração:
    ;   1. Escreve o valor de L (contexto atual) na Porta A
    ;   2. Troca de contexto com EXX
    ;   3. Repete
    ;
    ; O resultado visual é a alternância entre 0x55 e 0xAA nos LEDs.
    ; ------------------------------------------------------------------

loop_principal:
    ; --- Escreve o valor atual de L na Porta A ---
    ld a, l                   ; A = L (valor do contexto atual)
    out (porta), a            ; Escreve na Porta A (LEDs)

    ; --- Troca de contexto ---
    exx                       ; Alterna entre primário e alternativo

    ; --- Aguarda um curto delay ---
    call delay_curto

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