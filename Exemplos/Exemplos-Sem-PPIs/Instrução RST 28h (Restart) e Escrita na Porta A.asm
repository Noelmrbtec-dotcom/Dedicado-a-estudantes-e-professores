; =================================================================================
; Exemplo: Instrução RST 28h (Restart) e Escrita na Porta A
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique Cerqueira Braga
;
; OBJETIVO:
;   Demonstrar o uso da instrução RST 28h (opcode EFh), que empilha o PC e
;   salta para o endereço fixo 0028h. A rotina em 0028h escreve um valor
;   na Porta A (01h).
;
; COMO FUNCIONA:
;   1. O programa principal configura o SP e incrementa um contador (A).
;   2. A cada iteração, executa RST 28h (chamada de sub-rotina).
;   3. O Z80 empilha o PC (endereço da instrução após o RST) e salta para 0028h.
;   4. A rotina em 0028h escreve o valor de A na Porta A (01h).
;   5. A rotina executa RET (C9h) e retorna para o programa principal.
;   6. O programa principal continua incrementando o contador.
;
; CIRCUITO NO PROTEUS:
;   - Porta A (01h) = LEDs de saída (exibe o contador)
;
; RESULTADO ESPERADO:
;   - A Porta A deve incrementar continuamente: 01h, 02h, 03h, ...
; =================================================================================

porta   = 01h              ; Porta A (SAÍDA) — LEDs

    org 0000h              ; Vetor de RESET
    jp inicio

; =================================================================================
; Rotina de serviço em 0x0028h (chamada por RST 28h)
; =================================================================================
    org 0028h              ; Endereço fixo do RST 28h
rst_28:
    out (porta), a         ; Porta A = A (escreve o contador)
    ret                    ; Retorna para o programa principal

; =================================================================================
; Programa principal
; =================================================================================
    org 0100h
inicio:
    ld sp, 0FFFFh          ; SP = topo da RAM (pilha segura)
    xor a                  ; A = 0 (zera o contador)

loop:
    inc a                  ; Incrementa A (contador)
    rst 28h                ; Chama a rotina em 0x0028h (escreve A na Porta A)
    jp loop                ; Repete o loop

    end