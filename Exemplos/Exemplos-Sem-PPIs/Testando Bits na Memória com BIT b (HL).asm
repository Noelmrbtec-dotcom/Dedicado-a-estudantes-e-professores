; =================================================================================
; EXEMPLO: Testando Bits na Memória com BIT b,(HL)
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique Cerqueira Braga
;
; OBJETIVO:
;   Demonstrar o funcionamento da instrução BIT b,(HL) (opcode CB 46+b*8).
;   Esta instrução testa um bit específico na memória RAM apontada por HL.
;   Se o bit for 0, a flag Z (Zero) é ativada (Z=1).
;   Se o bit for 1, a flag Z é desativada (Z=0).
;
;   O programa vai testar os bits de um byte na memória e acender os LEDs
;   da Porta A com um padrão que indica o resultado.
;
; COMO FUNCIONA:
;   1. O programa grava um valor fixo (ex: 0Fh) na memória RAM em 8000h.
;   2. Aponta HL para 8000h.
;   3. Testa o bit 7 (o mais significativo) desse byte.
;   4. Se o bit 7 for 0 (Z=1), acende os LEDs com o padrão 0Fh.
;   5. Se o bit 7 for 1 (Z=0), acende os LEDs com o padrão F0h.
;   6. Testa o bit 4 e faz o mesmo com outros padrões.
;
; MAPA DE PORTAS:
;   Porta 01h (porta) = SAÍDA (LEDs)
; =================================================================================

porta    = 01h             ; Porta A (SAÍDA - LEDs)
ram_end  = 8000h           ; Endereço na RAM para o teste

    org 0000h              ; Vetor de RESET
    jp main

; =================================================================================
; Programa Principal
; =================================================================================
    org 0100h
main:
    ld sp, 0FFFFh          ; Inicializa a pilha

    ; --- Inicializa a memória RAM com um valor de teste ---
    ; Vamos usar 0000 1111b (0Fh).
    ; Os bits 7, 6, 5, 4 estão em 0. Os bits 3, 2, 1, 0 estão em 1.
    ld a, 0Fh
    ld (ram_end), a        ; (8000h) = 0Fh

    ; --- Aponta HL para o endereço na RAM ---
    ld hl, ram_end          ; HL = 8000h

    ; --- Teste 1: Bit 7 (0) ---
    bit 7, (hl)             ; Testa o bit 7 da memória apontada por HL
    jr z, bit7_zero         ; Se Z=1 (bit era 0), salta
    ; Se chegou aqui, o bit era 1
    ld a, 0FFh              ; Padrão se bit 7 for 1
    out (porta), a
    jr teste_2

bit7_zero:
    ld a, 0Fh               ; Padrão se bit 7 for 0
    out (porta), a

teste_2:
    call delay_curto        ; Pausa para ver o LED

    ; --- Teste 2: Bit 4 (0) ---
    bit 4, (hl)             ; Testa o bit 4 da memória apontada por HL
    jr z, bit4_zero         ; Se Z=1 (bit era 0), salta
    ; Se chegou aqui, o bit era 1
    ld a, 0F0h              ; Padrão se bit 4 for 1
    out (porta), a
    jr teste_3

bit4_zero:
    ld a, 0AAh              ; Padrão se bit 4 for 0
    out (porta), a

teste_3:
    call delay_curto

    ; --- Teste 3: Bit 2 (1) ---
    bit 2, (hl)             ; Testa o bit 2
    jr z, bit2_zero         ; Se Z=1 (bit era 0), salta
    ; Se chegou aqui, o bit era 1
    ld a, 55h               ; Padrão se bit 2 for 1
    out (porta), a
    jr fim_testes

bit2_zero:
    ld a, 0CCh              ; Padrão se bit 2 for 0
    out (porta), a

fim_testes:
    halt                    ; Para a CPU

; =================================================================================
; SUB-ROTINA: delay_curto
; =================================================================================
delay_curto:
    push af
    push bc
    ld bc, 0001h            ; Valor do delay
delay_loop:
    dec bc
    ld a, b
    or c
    jr nz, delay_loop
    pop bc
    pop af
    ret

.end