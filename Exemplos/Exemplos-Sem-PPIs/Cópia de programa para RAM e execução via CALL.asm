; =================================================================================
; Exemplo: Cópia de programa para RAM e execução via CALL
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique Cerqueira Braga
;
; OBJETIVO:
;   Demonstrar a cópia de um bloco de código da ROM para a RAM usando LDIR
;   e a execução de sub-rotinas encadeadas via CALL/RET.
;
; COMO FUNCIONA:
;   1. O programa principal em ROM (main) configura a pilha e usa o LDIR
;      para copiar o bloco "programa_principal" até "fim_programa" para a
;      RAM no endereço 8000h.
;   2. Em seguida, salta para o código copiado.
;   3. O código na RAM executa uma sequência de chamadas (CALL) a sub-rotinas.
;   4. Cada sub-rotina escreve um valor em uma porta (A ou C) e retorna (RET).
;   5. O programa termina com HALT.
;
; RESULTADO ESPERADO:
;   - Porta A (01h): recebe AAh, depois 81h, depois FFh.
;   - Porta C (10h): recebe 44h (chamado de dentro do teste_3).
; =================================================================================

porta    = 01h             ; Porta A (SAÍDA)
portb    = 02h             ; Porta B (SAÍDA) - não usada neste exemplo
portc    = 10h             ; Porta C (SAÍDA)

    org 0000h              ; Vetor de RESET
    jp main

    org 0030h              ; Programa principal (na ROM)
main:
    ; --- Configuração e Cópia para RAM ---
    ld sp, 0FFFFh          ; SP = topo da RAM (pilha segura)
    ld hl, programa_principal  ; HL = origem (endereço na ROM)
    ld de, 8000h               ; DE = destino (endereço na RAM)
    ld bc, fim_programa - programa_principal ; BC = tamanho do bloco
    ldir                       ; Copia bloco de (HL) para (DE) até BC=0

    ; --- Execução ---
    ; O jp abaixo salta para o código original na ROM.
    ; Se quiser executar o código COPIADO na RAM, troque por: jp 8000h
    jp programa_principal

; =================================================================================
; Bloco de código a ser copiado para a RAM (a partir daqui até fim_programa)
; =================================================================================
programa_principal:
    call teste_1           ; Chama a sub-rotina teste_1
    call teste_2           ; Chama a sub-rotina teste_2
    halt                   ; Para a CPU

; ---------------------------------------------------------------------------------
; Sub-rotina teste_1: Escreve AAh na Porta A
; ---------------------------------------------------------------------------------
teste_1:
    ld a, 0AAh             ; A = AAh
    out (porta), a         ; Porta A = AAh
    ret                    ; Retorna

; ---------------------------------------------------------------------------------
; Sub-rotina teste_2: Escreve 81h na Porta A e chama teste_3
; ---------------------------------------------------------------------------------
teste_2:
    ld a, 81h              ; A = 81h
    out (porta), a         ; Porta A = 81h
    call teste_3           ; Chama a sub-rotina teste_3
    ret                    ; Retorna

; ---------------------------------------------------------------------------------
; Sub-rotina teste_3: Escreve 44h na Porta C e chama teste_4
; ---------------------------------------------------------------------------------
teste_3:
    ld a, 44h              ; A = 44h
    out (portc), a         ; Porta C = 44h
    call teste_4           ; Chama a sub-rotina teste_4
    ret                    ; Retorna

; ---------------------------------------------------------------------------------
; Sub-rotina teste_4: Escreve FFh na Porta A
; ---------------------------------------------------------------------------------
teste_4:
    ld a, 0FFh             ; A = FFh
    out (porta), a         ; Porta A = FFh
    ret                    ; Retorna

fim_programa:              ; Marca o fim do bloco para o cálculo do tamanho (LDIR)

    end