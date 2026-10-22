; =================================================================================
; Teste de Interrupções (INT e NMI) com Cópia de A para Porta C (10h)
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique Cerqueira Braga
;
; OBJETIVO:
;   Testar as interrupções INT (mascarada) e NMI (não mascarada) de forma real.
;   No momento em que qualquer uma for atendida, o valor atual de A é escrito
;   na Porta C (10h).
;
; COMO FUNCIONA:
;   1. O programa principal configura SP e IM 1, habilita interrupções (EI),
;      e entra em um loop infinito incrementando a Porta A (01h).
;   2. INT (PIN_E3) acionada:
;      - Z80 salva PC, desabilita IFF1, salta para 0x0038.
;      - Handler de INT escreve A em (10h), executa RETI.
;   3. NMI (PIN_E4) acionada:
;      - Z80 salva PC, desabilita IFF1, salta para 0x0066.
;      - Handler de NMI escreve A em (10h), executa RETN.
;   4. O loop principal retoma o incremento da Porta A após a interrupção.
;
; RESULTADO ESPERADO:
;   - Porta A (01h): incrementa constantemente.
;   - Porta C (10h): recebe o valor atual de A no momento da interrupção.
;   - Se o RETI/RETN funcionar, a Porta A continua incrementando.
; =================================================================================

porta   = 01h              ; Porta A (SAÍDA) — contador do loop
portc   = 10h              ; Porta C (SAÍDA) — valor capturado na interrupção

    org 0000h              ; Vetor de RESET
    jp inicio

    org 0038h              ; Vetor de INT (IM 1)
    jp handler_int

    org 0066h              ; Vetor de NMI
    jp handler_nmi

    org 0100h              ; Programa principal
inicio:
    ld sp, 0FFFFh          ; SP = topo da RAM (pilha segura)
    im 1                   ; FORÇA MODO DE INTERRUPÇÃO 1
    ld a, 00h              ; A = 0 (contador do loop)
    ei                     ; Habilita interrupções (IFF1 = IFF2 = 1)

loop:
    inc a                  ; Incrementa A
    out (porta), a         ; Porta A = A (contador visível)
    jp loop                ; Loop infinito

; =================================================================================
; Handler de INT (IM 1) — vetor em 0x0038
; =================================================================================
handler_int:
    push af                ; Salva A e F
    out (portc), a         ; Porta C (10h) = A (valor atual do contador)
    pop af                 ; Restaura A e F
    ei                     ; Reabilita interrupções (IM 1)
    reti                   ; Retorna da interrupção (IFF1 = IFF2)

; =================================================================================
; Handler de NMI — vetor em 0x0066
; =================================================================================
handler_nmi:
    push af                ; Salva A e F
    out (portc), a         ; Porta C (10h) = A (valor atual do contador)
    pop af                 ; Restaura A e F
    retn                   ; Retorna da NMI (IFF1 = IFF2)

    end