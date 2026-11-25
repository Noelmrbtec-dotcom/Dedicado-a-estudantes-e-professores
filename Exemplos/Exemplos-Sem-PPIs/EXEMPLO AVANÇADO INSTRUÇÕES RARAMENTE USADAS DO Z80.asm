; =================================================================================
; EXEMPLO AVANÇADO: INSTRUÇÕES RARAMENTE USADAS DO Z80
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique Cerqueira Braga
;
; OBJETIVO:
;   Explorar instruções pouco convencionais do Z80 que são frequentemente
;   ignoradas em tutoriais, mas que demonstram a profundidade da arquitetura.
;   O foco está em:
;     1. RLD e RRD (Rotação Decimal de Nibbles entre A e (HL))
;     2. ADC HL, rr e SBC HL, rr (Aritmética de 16 bits com Carry)
;     3. LD (nn), BC / DE / SP (Armazenamento de 16 bits em memória absoluta)
;     4. LD A, I e LD A, R (Leitura dos registradores de Interrupção e Refresh)
;
; MAPA DE I/O:
;   Porta A (01h) = Saída (LEDs) - Usada para visualizar o resultado final.
; =================================================================================

porta   = 01h      ; Porta A (Saída)
ram_base = 8000h   ; Endereço base na RAM

    org 0000h
    jp init

    org 0038h
    ei
    reti

    org 0066h
    retn

    org 0100h
init:
    ld sp, 0FFFFh  ; Inicializa a pilha

; ---------------------------------------------------------------------------------
; PARTE 1: RLD e RRD (Rotação de Nibbles) - Aplicação em BCD
; ---------------------------------------------------------------------------------
    ; Vamos preparar os dados para a rotação decimal.
    ; O Z80 tem a capacidade de rotacionar 4 bits (um dígito BCD) entre A e (HL).

    ld a, 12h      ; A = 12h
    ld hl, ram_base; HL = 8000h
    ld (hl), 34h   ; (8000h) = 34h

    ; --- RLD (Rotate Left Decimal) ---
    ; O bit baixo de A (2h) vai para o bit baixo de (HL).
    ; O bit alto de (HL) (3h) vai para o bit baixo de A.
    ; Resultado esperado: A = 13h, (HL) = 42h
    rld

    ; --- RRD (Rotate Right Decimal) ---
    ; O bit baixo de A (3h) vai para o bit alto de (HL).
    ; O bit baixo de (HL) (2h) vai para o bit baixo de A.
    ; Resultado esperado: A = 12h, (HL) = 32h
    rrd

    ; Mostra A nos LEDs (Esperado: 12h)
    out (porta), a

; ---------------------------------------------------------------------------------
; PARTE 2: ADC HL, rr e SBC HL, rr (16-bit com Carry)
; ---------------------------------------------------------------------------------
    ; Aritmética de 16 bits com carry é feita pelo prefixo ED.
    ; Vamos somar e subtrair pares, considerando o carry.

    ld hl, 1234h   ; HL = 1234h
    ld bc, 1000h   ; BC = 1000h
    ld de, 0120h   ; DE = 0120h

    or a           ; Limpa o Carry (A = A OR A)

    adc hl, bc     ; HL = HL + BC + Carry = 1234h + 1000h + 0 = 2234h
    sbc hl, de     ; HL = HL - DE - Carry = 2234h - 0120h - 0 = 2114h

    ; Mostra o byte baixo (L) nos LEDs (Esperado: 14h)
    out (porta), a ; (Nota: estamos enviando A, mas o resultado está em L. Vamos ajustar)
    ld a, l
    out (porta), a

; ---------------------------------------------------------------------------------
; PARTE 3: Armazenamento de Pares em Memória Absoluta
; ---------------------------------------------------------------------------------
    ; Normalmente usamos LD (nn), HL. Mas o Z80 permite armazenar BC, DE e SP.
    ; Essas instruções usam o prefixo ED e são raramente vistas.

    ld bc, 0BCBCh
    ld de, 0DEDEh

    ld (ram_base + 1), bc  ; Armazena BC em 8001h e 8002h
    ld (ram_base + 3), de  ; Armazena DE em 8003h e 8004h
    ld (ram_base + 5), sp  ; Armazena SP em 8005h e 8006h

; ---------------------------------------------------------------------------------
; PARTE 4: LD A, I e LD A, R (Registradores de Sistema)
; ---------------------------------------------------------------------------------
    ; O registrador I é usado no modo IM 2 para vetores de interrupção.
    ; O registrador R é o contador de refresh da memória dinâmica.
    ; Estas instruções são as únicas formas de ler esses registradores.

    ld a, 70h
    ld i, a        ; Configura I com 70h

    ; Vamos ler o I e o R.
    ld a, i        ; A recebe o valor de I (70h)
    out (porta), a ; Mostra nos LEDs

    ld a, r        ; A recebe o valor de R (contador de refresh)
    out (porta), a ; Mostra nos LEDs (valor incrementará a cada opcode)

; ---------------------------------------------------------------------------------
; FIM DO PROGRAMA
; ---------------------------------------------------------------------------------
fim:
    halt
    jp fim

.end