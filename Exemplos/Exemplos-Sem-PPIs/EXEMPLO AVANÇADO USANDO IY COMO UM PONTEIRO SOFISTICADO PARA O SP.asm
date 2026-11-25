; =================================================================================
; EXEMPLO AVANÇADO: USANDO IY COMO UM PONTEIRO SOFISTICADO PARA O SP
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique Cerqueira Braga
;
; OBJETIVO:
;   Demonstrar a instrução LD SP, IY. Ela permite carregar o Stack Pointer (SP)
;   com o valor do registrador de índice IY. Dessa forma, podemos usar o IY
;   para calcular um endereço de memória na RAM (como um bloco de dados) e,
;   em seguida, usar a pilha (PUSH/POP) para manipular essa memória de forma
;   extremamente eficiente.
;
; MAPA DE I/O (Conforme definido no esquema):
;   Porta A (01h) = Saída (LEDs)
;   Porta C (10h) = Saída (LEDs)
; =================================================================================

porta   = 01h      ; Porta A - Saída
portc   = 10h      ; Porta C - Saída

    org 0000h
    jp init

    org 0038h
    ei
    reti

    org 0100h
init:
    ld sp, 0FFFFh  ; Inicializa a pilha "oficial" no topo da RAM
    ld iy, 8100h   ; Aponta IY para o endereço 8100h (área de dados na RAM)

; ---------------------------------------------------------------------------------
;   Abilita IM 1 (Vetor 038h)
; ---------------------------------------------------------------------------------
    IM 1           ; Configura INT para IM 1
    ei             ; Abilita INT(IM 1)

; ---------------------------------------------------------------------------------
; PARTE 1: Usando IY como Ponteiro para o Stack Pointer
; ---------------------------------------------------------------------------------
    ; Vamos carregar o SP com o endereço que está em IY.
    ; O opcode FD F9 executa essa transferência.
    ld sp, iy      ; SP agora aponta para 8100h (e não mais para FFFFh)

    ; Agora, a "pilha" está no endereço 8100h.
    ; ATENÇÃO: O SP cresce para baixo (decrementa antes de escrever).
    ; Se SP = 8100h, um PUSH vai escrever em 80FFh e 80FEh.
    ; Para mantermos os dados visíveis a partir de 8100h, vamos
    ; ajustar o SP para 8102h.

    ld sp, 8102h   ; Força o SP para 8102h (via valor imediato)
    ; (Ou poderíamos fazer: INC IY, INC IY, LD SP, IY)

    ; Vamos empilhar dados. O SP vai para 8101h e 8100h.
    ld bc, 0ABCDh  ; BC = ABCDh
    push bc        ; (8100h) = CDh, (8101h) = ABh, SP = 8100h

    ; Empilha mais dados. O SP vai para 80FFh e 80FEh.
    ld de, 1234h   ; DE = 1234h
    push de        ; (80FEh) = 34h, (80FFh) = 12h, SP = 80FEh

; ---------------------------------------------------------------------------------
; PARTE 2: Recuperando os dados usando POP (Lendo a Memória)
; ---------------------------------------------------------------------------------
    ; Agora vamos ler os dados de volta para os registradores.
    ; Como o SP está em 80FEh, o primeiro POP vai ler de 80FEh e 80FFh.
    pop de         ; DE = 1234h, SP = 8100h
    pop bc         ; BC = ABCDh, SP = 8102h

; ---------------------------------------------------------------------------------
; PARTE 3: Verificando o resultado nas portas
; ---------------------------------------------------------------------------------
    ; Mostra o byte baixo de BC (CDh) e DE (34h) nas portas.
    ld a, c
    out (porta), a ; Porta A = CDh

    ld a, e
    out (portc), a ; Porta C = 34h

fim:
    halt
    jp fim

.end