; =================================================================================
; TESTE DEFINITIVO DE INTERRUPÇÃO NÃO-VETORIZADA (IM 0) - INSTRUÇÃO RST
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique Cerqueira Braga
;
; OBJETIVO:
;   Demonstrar o funcionamento do Modo de Interrupção 0 (IM 0) do Z80.
;   O hardware externo coloca uma instrução de 1 byte no barramento.
;   O Z80 executa a instrução (geralmente um RST), saltando para um
;   endereço fixo.
;
; MAPA DE PORTAS:
;   Porta 01h (porta)        = SAÍDA (LEDs)
;   Porta 80h (vector_latch) = SAÍDA (Latch de Instrução para IM 0)
;
; =================================================================================
; TABELA DE INSTRUÇÕES ÚTEIS PARA IM 0 (1 byte)
; =================================================================================
;
;  Opcode | Instrução | Destino | Handler no ASM
; --------|-----------|---------|------------------
;  C7h    | RST 00h   | 0000h   | (Reinicia o programa via jp init)
;  CFh    | RST 08h   | 0008h   | isr_rst_08 (Padrão: F1h)
;  D7h    | RST 10h   | 0010h   | isr_rst_10 (Padrão: AAh)
;  DFh    | RST 18h   | 0018h   | isr_rst_18 (Padrão: 55h)
;  E7h    | RST 20h   | 0020h   | isr_rst_20 (Padrão: CCh)
;  EFh    | RST 28h   | 0028h   | isr_rst_28 (Padrão: F0h)
;  F7h    | RST 30h   | 0030h   | isr_rst_30 (Padrão: 0Fh)
;  FFh    | RST 38h   | 0038h   | isr_rst_38 (Padrão: FFh)

;
;  RECOMENDAÇÃO: Use sempre os RST (C7h a FFh) para segurança.
; =================================================================================

; ---------------------------------------------------------------------------------
; >>> ALTERE AQUI PARA TESTAR OUTRA INSTRUÇÃO <<<
; ---------------------------------------------------------------------------------
INSTRUCAO_IM0 = 0F7h       ; Opcode fixo (FFh = RST 38h)

; ---------------------------------------------------------------------------------
; Definições de portas e constantes
; ---------------------------------------------------------------------------------
porta        = 01h         ; LEDs
vector_latch = 80h         ; Latch de Instrução

; ==================================================================================
; --- Vetor de RESET ---
; ==================================================================================
.org 0000h
    jp init

; ==================================================================================
; --- Handlers de Interrupção (Endereços Fixos do RST) ---
; ==================================================================================

; Todos os handlers escrevem um padrão na Porta A e depois param no HALT
; para que você consiga ver o LED aceso.

.org 0008h
isr_rst_08:
    push af
    ld a, 0F1h
    out (porta), a
    halt                  ; <--- PARA A CPU AQUI PARA VOCÊ VER O LED
    pop af
    ei
    reti

.org 0010h
isr_rst_10:
    push af
    ld a, 0AAh
    out (porta), a
    halt                  ; <--- PARA A CPU AQUI
    pop af
    ei
    reti

.org 0018h
isr_rst_18:
    push af
    ld a, 055h
    out (porta), a
    halt                  ; <--- PARA A CPU AQUI
    pop af
    ei
    reti

.org 0020h
isr_rst_20:
    push af
    ld a, 0CCh
    out (porta), a
    halt
    pop af
    ei
    reti

.org 0028h
isr_rst_28:
    push af
    ld a, 0F0h
    out (porta), a
    halt                  ; <--- PARA A CPU AQUI
    pop af
    ei
    reti

.org 0030h
isr_rst_30:
    push af
    ld a, 0Fh
    out (porta), a
    halt
    pop af
    ei
    reti

.org 0038h
isr_rst_38:
    push af
    ld a, 0FFh
    out (porta), a
    halt                  ; <--- PARA A CPU AQUI
    pop af
    ei
    reti

; ==================================================================================
; --- Programa Principal ---
; ==================================================================================
.org 0100h
init:
    ld sp, 0FFFFh          ; Inicializa a pilha

    ; 1. Grava a instrução no Latch
    ld a, INSTRUCAO_IM0
    out (vector_latch), a

    ; 2. Configura IM 0
    im 0

    ; 3. Habilita interrupções
    ei

; Loop infinito
loop:
    nop
    jp loop

.end