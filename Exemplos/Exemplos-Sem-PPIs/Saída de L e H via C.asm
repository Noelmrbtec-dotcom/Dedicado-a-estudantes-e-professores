; =================================================================================
; Entendendo funcionamento de processadores (Z80) Zilog
; Autor: Marcos Roberto Braga
; Data: 19/10/2025
; Aluno: Pedro Henrique Cerqueira Braga
;
; TESTE: OUT (C),H e OUT (C),L — Saída de H e L via C
;        (hardware sem PPI — portas discretas)
;
; OBJETIVO:
;   Demonstrar o uso das instruções OUT (C),H e OUT (C),L do Z80,
;   que escrevem os registradores H e L na porta de I/O apontada
;   por C.
;
;   Este exemplo usa hardware SEM PPI:
;     - Porta A = 01h (SAÍDA)
;     - Porta B = 02h (ENTRADA)
;     - Porta C = 10h (SAÍDA)
;
; FLUXO:
;   1. Carrega HL com um valor conhecido (ex.: 1234h)
;   2. OUT (C),H  — escreve H (12h) na Porta A
;   3. OUT (C),L  — escreve L (34h) na Porta A
;   4. Para (loop infinito) para inspeção
;
; MAPA DE MEMÓRIA:
;   ROM: 0000h – 7FFFh  (código)
;   RAM: 8000h – FFFFh  (pilha)
;
; HARDWARE (sem PPI):
;   porta   = 01h   (SAÍDA)
;   portb   = 02h   (ENTRADA)
;   portc   = 10h   (SAÍDA)
;
; RESULTADO ESPERADO:
;   Porta A = 12h (valor de H após o primeiro OUT)
;   Porta A = 34h (valor de L após o segundo OUT)
;
;   Como as duas instruções escrevem na MESMA porta (01h),
;   o valor final na Porta A será 34h (o último escrito).
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
    ; 1. CARREGA HL COM UM VALOR CONHECIDO
    ; ******************************************************************
    ; HL = 1234h
    ;   H = 12h
    ;   L = 34h
    ; ******************************************************************
    ld hl, 1234h              ; HL = 1234h (H=12h, L=34h)

    ; ******************************************************************
    ; 2. OUT (C),H — Escreve H na porta apontada por C
    ; ******************************************************************
    ; OUT (C),H (ED 61h)
    ;   (C) ← H
    ;
    ; Configura C = porta (01h) e escreve H (12h) na Porta A.
    ; ******************************************************************
    ld c, porta               ; C = 01h (Porta A)
    out (c), h                ; Porta A ← H = 12h

    ; ******************************************************************
    ; 3. OUT (C),L — Escreve L na porta apontada por C
    ; ******************************************************************
    ; OUT (C),L (ED 69h)
    ;   (C) ← L
    ;
    ; C ainda é 01h, então escreve L (34h) na Porta A.
    ; ******************************************************************
    out (c), l                ; Porta A ← L = 34h

    ; ******************************************************************
    ; 4. FIM — loop infinito para inspeção
    ; ******************************************************************
fim:
    jp fim

; =================================================================================
.end
;**************************Fim******************************************************