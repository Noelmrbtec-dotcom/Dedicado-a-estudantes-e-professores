; =================================================================================
; Exemplo: Leitura de Bit Específico do PORTB e Escrita Condicional
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique Cerqueira Braga
;
; OBJETIVO:
;   Demonstrar como ler um bit específico de uma porta de entrada (Porta B)
;   e, dependendo do seu estado (0 ou 1), escrever um valor diferente em
;   outra porta de saída (Porta A ou Porta C).
;
; COMO FUNCIONA:
;   1. O programa lê o estado da Porta B (02h) inteira.
;   2. Testa o BIT 0 dessa leitura usando a instrução BIT 0,A (opcode CB 47h).
;   3. Se o bit for 0 (Z=1), escreve 0x11 na Porta A (LEDs).
;   4. Se o bit for 1 (Z=0), escreve 0x22 na Porta C (LEDs).
;   5. O programa fica em loop infinito, repetindo a leitura continuamente.
;
; CIRCUITO NO PROTEUS:
;   - Porta B (02h) = Chaves (switches) de entrada
;   - Porta A (01h) = LEDs de saída (para bit = 0)
;   - Porta C (10h) = LEDs de saída (para bit = 1)
;
; RESULTADO ESPERADO:
;   - Se o BIT 0 da Porta B for 0: Porta A = 11h, Porta C = 00h
;   - Se o BIT 0 da Porta B for 1: Porta A = 00h, Porta C = 22h
; =================================================================================

porta   = 01h              ; Porta A (SAÍDA) — LEDs (bit = 0)
portb   = 02h              ; Porta B (ENTRADA) — Chaves
portc   = 10h              ; Porta C (SAÍDA) — LEDs (bit = 1)

    org 0000h              ; Vetor de RESET
    jp inicio

    org 0100h              ; Programa principal
inicio:
    ld sp, 0FFFFh          ; SP = topo da RAM (pilha segura)

loop:
    ; --- Lê a Porta B (chaves) ---
    in a, (portb)          ; A = estado das chaves

    ; --- Testa o BIT 0 de A ---
    bit 0, a               ; Testa bit 0 (Z=1 se for 0, Z=0 se for 1)

    ; --- Decide o que escrever ---
    jr z, bit_zero         ; Se Z=1 (bit 0 = 0), salta para bit_zero

    ; --- Bit 0 = 1: escreve 22h na Porta C ---
    ld a, 22h              ; A = 22h
    out (portc), a         ; Porta C = 22h
    xor a                  ; A = 0
    out (porta), a         ; Porta A = 00h (apaga)
    jr loop                ; Repete o loop

bit_zero:
    ; --- Bit 0 = 0: escreve 11h na Porta A ---
    ld a, 11h              ; A = 11h
    out (porta), a         ; Porta A = 11h
    xor a                  ; A = 0
    out (portc), a         ; Porta C = 00h (apaga)
    jr loop                ; Repete o loop

    end