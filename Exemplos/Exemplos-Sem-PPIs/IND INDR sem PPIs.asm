; =================================================================================
; Entendendo funcionamento de processadores (Z80) Zilog
; Autor: Marcos Roberto Braga
; Data: 16/10/2025
; Aluno: Pedro Henrique Cerqueira Braga
;
; TESTE COMPARATIVO: CÓPIA DECRESCENTE COM IND e INDR
;                     (hardware sem PPI — portas discretas)
;
; OBJETIVO:
;   Demonstrar o uso das instruções IND e INDR do Z80, que leem da
;   porta de I/O apontada por C e escrevem na memória apontada por HL,
;   decrementando HL e B.
;
;   Este exemplo usa hardware SEM PPI:
;     - Porta A = 01h (SAÍDA)
;     - Porta B = 02h (ENTRADA)
;     - Porta C = 10h (SAÍDA)
;
; FLUXO:
;   1. TESTE A: IND isolada — lê 1 byte da Porta B para (HL)
;   2. TESTE B: INDR — lê 8 bytes da Porta B para BUFFER (decrescente)
;   3. Exibe o resultado nas Portas A e C
;   4. Para (loop infinito) para inspeção
;
; MAPA DE MEMÓRIA:
;   ROM: 0000h – 7FFFh  (código)
;   RAM: 8000h – FFFFh  (buffers + pilha)
;
; HARDWARE (sem PPI):
;   porta   = 01h   (SAÍDA)
;   portb   = 02h   (ENTRADA)
;   portc   = 10h   (SAÍDA)
; =================================================================================

; =================================================================================
; MAPEAMENTO DE I/O
; =================================================================================
porta   = 01h    ; Porta A (SAÍDA)
portb   = 02h    ; Porta B (ENTRADA)
portc   = 10h    ; Porta C (SAÍDA)

; =================================================================================
; --- Vetor de RESET ---
; =================================================================================
    org 0000h
    jp inicio

; =================================================================================
; --- Programa Principal ---
; =================================================================================
    org 0030h

inicio:
    ld sp, 0FFFFh             ; Stack Pointer no topo da RAM

    ; ******************************************************************
    ; 1. TESTE A — IND (uma única leitura da Porta B)
    ; ******************************************************************
    ; IND (ED AAh) — Input and Decrement
    ;   (HL) ← (C); HL--; B--
    ;
    ; Lê 1 byte da Porta B (endereço 02h) e escreve em BUFFER+7 (8007h).
    ; ******************************************************************
    ld hl, BUFFER + 7         ; HL = fim do buffer (8007h)
    ld c, portb               ; C = Porta B (02h)
    ld b, 01h                 ; B = 1 byte

    ind                       ; Lê 1 byte da PPI para (HL), HL--, B--

    ; ******************************************************************
    ; 2. TESTE B — INDR (8 bytes decrescentes da Porta B)
    ; ******************************************************************
    ; INDR (ED BAh) — Input, Decrement and Repeat
    ;   (HL) ← (C); HL--; B--; repete até B=0
    ;
    ; Lê 8 bytes da Porta B para BUFFER (8000h–8007h), decrementando HL.
    ; ******************************************************************
    ld hl, BUFFER + 7         ; HL = fim do buffer (8007h)
    ld c, portb               ; C = Porta B (02h)
    ld b, 08h                 ; B = 8 bytes

    indr                      ; Lê 8 bytes, decrementando HL e B

    ; ******************************************************************
    ; 3. EXIBE O RESULTADO NAS PORTAS A e C
    ; ******************************************************************
    ; Escreve o conteúdo de BUFFER+0 nas Portas A e C para inspeção.
    ; ******************************************************************
    ld a, (BUFFER)            ; A = 1º byte do buffer
    out (porta), a            ; Porta A = A
    out (portc), a            ; Porta C = A

    ; ******************************************************************
    ; 4. FIM — loop infinito para inspeção
    ; ******************************************************************
fim:
    jp fim

; =================================================================================
; BUFFER NA RAM (>= 8000h)
; =================================================================================
    org 8000h

BUFFER:
    ds 8                      ; 8 bytes reservados

; =================================================================================
.end
;**************************Fim******************************************************