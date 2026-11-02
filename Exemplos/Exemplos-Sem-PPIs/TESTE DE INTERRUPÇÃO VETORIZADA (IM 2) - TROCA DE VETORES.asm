; =================================================================================
; TESTE DE INTERRUPÇÃO VETORIZADA (IM 2) - VETOR FIXO
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique Cerqueira Braga
;
; OBJETIVO:
;   Demonstrar o funcionamento do IM 2 com um vetor fixo e fácil de alterar.
;   O aluno muda o valor da constante VETOR_ATUAL, recompila e observa
;   o Z80 saltando para o handler correspondente.
;
; COMO TESTAR:
;   1. Mude VETOR_ATUAL para 00h, 02h, 04h ou 06h
;   2. Monte o ASM e carregue no Z80-EMU
;   3. Aperte o botão INT
;   4. Veja no terminal o log: "VetorBYTE 02 -> PC=00A0"
;   5. Veja os LEDs mostrarem o valor dos switches
;
; MAPA DE PORTAS:
;   Porta 01h (porta)        = SAÍDA (LEDs)
;   Porta 10h (port_io)      = ENTRADA (Switches)
;   Porta 80h (vector_latch) = SAÍDA (Latch de Vetores)
; =================================================================================

; ---------------------------------------------------------------------------------
; >>> ALTERE AQUI PARA TESTAR OUTRO VETOR <<<
; ---------------------------------------------------------------------------------
VETOR_ATUAL  = 06h        ; Vetor fixo (00h, 02h, 04h ou 06h)

; ---------------------------------------------------------------------------------
; Definições de portas e constantes
; ---------------------------------------------------------------------------------
porta        = 01h        ; LEDs
portd        = 10h        ; Switches
vector_latch = 80h        ; Latch de vetores

; ==================================================================================
; --- Vetor de RESET ---
; ==================================================================================
.org 0000h
    jp init

; ==================================================================================
; --- Tabela de Vetores (Endereço 7000h) ---
; O registrador I = 70h aponta para esta tabela.
; ==================================================================================
.org 7000h
vector_table:
    .dw isr_handler_00  ; 7000h - Vetor 00h -> Handler em 0080h
    .dw isr_handler_02  ; 7002h - Vetor 02h -> Handler em 00A0h
    .dw isr_handler_04  ; 7004h - Vetor 04h -> Handler em 00C0h
    .dw isr_handler_06  ; 7006h - Vetor 06h -> Handler em 00E0h

; ==================================================================================
; --- Handlers de Interrupção ---
; Cada handler tem um padrão de LED diferente para você identificar qual foi usado.
; ==================================================================================

; --- Handler do Vetor 00h ---
.org 0080h
isr_handler_00:
    push af
    ld a, 0F1h            ; Padrão do Timer
    out (porta), a
    pop af
    ei
    reti

; --- Handler do Vetor 02h ---
.org 00A0h
isr_handler_02:
    push af
    ld a, 0AAh            ; Padrão do Serial
    out (porta), a
    pop af
    ei
    reti

; --- Handler do Vetor 04h ---
.org 00C0h
isr_handler_04:
    push af
    ld a, 055h            ; Padrão do Keyboard
    out (porta), a
    pop af
    ei
    reti

; --- Handler do Vetor 06h ---
.org 00E0h
isr_handler_06:
    push af
    ld a, 0CCh            ; Padrão do Default
    out (porta), a
    pop af
    ei
    reti

; ==================================================================================
; --- Programa Principal ---
; ==================================================================================
.org 0100h
init:
    ld sp, 0FFFFh         ; Inicializa a pilha

    ; 1. Grava o vetor fixo no Latch (Porta 80h)
    ld a, VETOR_ATUAL
    out (vector_latch), a

    ; 2. Configura o Modo de Interrupção 2 (IM 2)
    ld a, 70h             ; I = 70h (parte alta da tabela em 7000h)
    ld i, a
    im 2

    ; 3. Habilita interrupções
    ei

; Loop infinito — espera a interrupção
loop:
    nop
    jp loop

.end