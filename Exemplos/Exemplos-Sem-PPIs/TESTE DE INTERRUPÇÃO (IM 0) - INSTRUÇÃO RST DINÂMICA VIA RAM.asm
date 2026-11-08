; =================================================================================
; TESTE DE INTERRUPÇÃO (IM 0) - INSTRUÇÃO RST DINÂMICA VIA RAM
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique Cerqueira Braga
;
; OBJETIVO:
;   Demonstrar o funcionamento do Modo de Interrupção 0 (IM 0) onde
;   o Z80 lê uma instrução (RST) direto do hardware.
;
;   Neste exemplo, o programa principal lê um opcode (ex: FFh) guardado
;   na RAM (8000h) e o envia para o Latch (Porta 80h). Quando a interrupção
;   ocorre, o Z80 lê esse opcode e salta para o handler correspondente.
;
; COMO TESTAR:
;   1. Rode o código. O programa vai gravar FFh no Latch.
;   2. Aperte o botão INT. O Z80 vai para o handler RST 38h (Padrão FFh).
;   3. Mude o valor em 8000h (via monitor de memória) para CFh.
;   4. O programa atualiza o Latch com CFh.
;   5. Aperte INT novamente. O Z80 vai para o handler RST 08h (Padrão F1h).
;
; =================================================================================
; TABELA DE INSTRUÇÕES ÚTEIS PARA IM 0
; =================================================================================
;  Opcode | Instrução | Destino | Handler no ASM (Padrão)
; --------|-----------|---------|------------------
;  CFh    | RST 08h   | 0008h   | isr_rst_08 (F1h)
;  D7h    | RST 10h   | 0010h   | isr_rst_10 (AAh)
;  DFh    | RST 18h   | 0018h   | isr_rst_18 (55h)
;  E7h    | RST 20h   | 0020h   | isr_rst_20 (CCh)
;  EFh    | RST 28h   | 0028h   | isr_rst_28 (F0h)
;  F7h    | RST 30h   | 0030h   | isr_rst_30 (0Fh)
;  FFh    | RST 38h   | 0038h   | isr_rst_38 (FFh)
; =================================================================================

porta        = 01h         ; LEDs
vector_latch = 80h         ; Latch de Instrução
ram_opcode   = 8000h       ; Endereço na RAM onde o opcode fica guardado

; ==================================================================================
; --- Vetor de RESET ---
; ==================================================================================
.org 0000h
    jp init

; ==================================================================================
; --- Handlers de Interrupção (Endereços Fixos do RST) ---
; ==================================================================================
.org 0008h
isr_rst_08:
    push af
    ld a, 0F1h
    out (porta), a
    halt                        ;<- Para CPU (Visualizar leds).
    pop af
    ei
    reti

.org 0010h
isr_rst_10:
    push af
    ld a, 0AAh
    out (porta), a
    halt                        ;<- Para CPU (Visualizar leds).
    pop af
    ei
    reti

.org 0018h
isr_rst_18:
    push af
    ld a, 055h
    out (porta), a
    halt                        ;<- Para CPU (Visualizar leds).
    pop af
    ei
    reti

.org 0020h
isr_rst_20:
    push af
    ld a, 0CCh
    out (porta), a
    halt                        ;<- Para CPU (Visualizar leds).
    pop af
    ei
    reti

.org 0028h
isr_rst_28:
    push af
    ld a, 0F0h
    out (porta), a
    halt                        ;<- Para CPU (Visualizar leds).
    pop af
    ei
    reti

.org 0030h
isr_rst_30:
    push af
    ld a, 0Fh
    out (porta), a
    halt                        ;<- Para CPU (Visualizar leds).
    pop af
    ei
    reti

.org 0038h
isr_rst_38:
    push af
    ld a, 0FFh
    out (porta), a
    halt                        ;<- Para CPU (Visualizar leds).
    pop af
    ei
    reti

; ==================================================================================
; --- Programa Principal ---
; ==================================================================================
.org 0100h
init:
    ld sp, 0FFFFh          ; Inicializa a pilha

    ; Inicializa a variável na RAM com o opcode FFh (RST 38h)
    ; (Como o DB em ORG alto as vezes não carrega, fazemos por código)
    ld a, 0DFh
    ld (ram_opcode), a

    ; Configura IM 0
    im 0

    ; Habilita interrupções
    ei

loop:
    ; --- O "Coração" da alteração dinâmica ---
    ; O Z80 lê o valor da RAM e joga no Latch.
    ; Se você mudar o valor em 8000h no monitor de memória,
    ; o Latch será atualizado automaticamente no próximo loop!
    ld a, (ram_opcode)
    out (vector_latch), a

    ; Delay curto para não sobrecarregar o barramento
    ; (Opcional, mas ajuda na simulação do Proteus)
    ld b, 01h
delay_curto:
    djnz delay_curto

    jp loop

.end