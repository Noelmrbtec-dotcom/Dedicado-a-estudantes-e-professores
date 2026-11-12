; =================================================================================
; TESTE DE ECO SERIAL VIA POLLING E EFEITO VISUAL NA PPI 2
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique Cerqueira Braga
;
; OBJETIVO:
;   Demonstrar a comunicação serial bidirecional (Eco) com a USART 8250A
;   enquanto um efeito visual de corrida de LEDs roda na PPI 2.
;
; COMO FUNCIONA:
;   O loop principal faz duas coisas alternadas:
;   1. Verifica se a serial tem dado (Polling). Se tiver, lê, exibe na PPI 1 e ecoa.
;   2. Se não tiver, avança o efeito de LEDs na PPI 2 e faz um delay curto.
;
; MAPA DE I/O:
;   PPI 1 (00h-03h): Porta A (00h) = LEDs do dado serial
;   PPI 2 (08h-0Bh): Porta A (08h) = LEDs do efeito visual
;   USART 8250A (10h-17h): RBR, IER, IIR, LCR, LSR
; =================================================================================

porta1       = 00h         ; PPI 1 - Porta A (Saída de dados serial)
ppi_confg1   = 03h         ; PPI 1 - Registro de Controle

porta2       = 08h         ; PPI 2 - Porta A (Efeito visual)
ppi_confg2   = 0Bh         ; PPI 2 - Registro de Controle

uart_dado    = 10h         ; 8250A - RBR / THR / DLL
uart_ier     = 11h         ; 8250A - IER / DLM
uart_iir     = 12h         ; 8250A - IIR
uart_control = 13h         ; 8250A - LCR
uart_status  = 15h         ; 8250A - LSR

    org 0000h
    jp init

    org 0100h
init:
    ld sp, 0FFFFh

    ; 1. Configura as PPIs (Modo 0, Portas A como saída)
    ld a, 82h
    out (ppi_confg1), a
    out (ppi_confg2), a

    ; 2. Configura a USART 8250A (9600, 8N1)
    ld a, 80h              ; DLAB = 1
    out (uart_control), a
    ld a, 0Ch              ; DLL = 12 (9600 baud)
    out (uart_dado), a
    ld a, 00h              ; DLM = 0
    out (11h), a
    ld a, 03h              ; 8N1, DLAB = 0
    out (uart_control), a

    ; Limpa resíduos
    in a, (uart_dado)
    in a, (uart_status)
    in a, (uart_iir)

    ; 3. Desabilita interrupção no 8250A (IER = 0)
    xor a
    out (uart_ier), a

    ; Inicializa o padrão do efeito visual na PPI 2
    ld a, 01h
    out (porta2), a
    ld e, a                ; E guarda o padrão atual do LED

; =================================================================================
; --- Loop Principal: Polling da Serial + Efeito Visual na PPI 2 ---
; =================================================================================
loop:
    ; 1. Verifica se há dado na serial (Polling rápido)
    in a, (uart_status)
    bit 0, a
    jr nz, le_serial       ; Se há dado, pula para tratar

    ; 2. Se não há dado, avança o efeito visual da PPI 2
    ld a, e
    rlca                   ; Rotaciona o LED para a esquerda
    jr nc, salva_efeito    ; Se não gerou carry, E = padrão normal
    ld a, 01h              ; Se gerou carry (passou do bit 7), recomeça em 01h
salva_efeito:
    ld e, a
    out (porta2), a        ; Escreve na PPI 2

    ; Pequeno delay para o olho humano ver o efeito
    call delay_curto
    jr loop                ; Volta ao início do loop

; =================================================================================
; --- Tratamento da Serial (chamado quando há dado) ---
; =================================================================================
le_serial:
    ; 1. Lê o caractere
    in a, (uart_dado)

    ; 2. Salva em B
    ld b, a

    ; 3. Envia para a PPI 1 (LEDs)
    out (porta1), a

    ; 4. Aguarda o transmissor estar livre (THRE - Bit 5 do LSR)
espera_tx:
    in a, (uart_status)
    bit 5, a
    jr z, espera_tx

    ; 5. Envia o eco
    ld a, b
    out (uart_dado), a

    ; 6. Limpa o IIR (boa prática)
    in a, (uart_iir)

    ; 7. Volta ao loop principal
    jr loop

; =================================================================================
; --- Sub-rotina de delay curto ---
; =================================================================================
delay_curto:
    push bc
    ld bc, 0001h
delay_loop:
    dec bc
    ld a, b
    or c
    jr nz, delay_loop
    pop bc
    ret

.end