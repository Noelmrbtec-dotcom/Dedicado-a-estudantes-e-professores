;***********************************************************************************
; Entendendo o funcionamento de processadores (Z80) Zilog
; Autor: Marcos Roberto Braga
; Data: 17/09/2025
; Aluno: Pedro Henrique Cerqueira Braga
;
; Z80-PIC — Exemplo: Controle das PPIs 8255 (somente saída)
;
; OBJETIVO:
;   Demonstrar o uso de duas PPIs 8255 configuradas SOMENTE como SAÍDA.
;   Cada porta (A, B, C) recebe um padrão diferente, e o programa alterna
;   entre dois estados com um delay curto entre eles.
;
; HARDWARE NECESSÁRIO:
;   - CPU Z80 (emulada)
;   - 2x PPI 8255 (mapeadas em I/O)
;   - LEDs (ou osciloscópio) nas portas A, B, C
;
; HARDWARE MAPEADO:
;   PPI 1: endereços 0x00-0x03
;   PPI 2: endereços 0x08-0x0B
;***********************************************************************************

; ==================================================================================
; MAPEAMENTO DE I/O — PPI 1 (8255)
; ==================================================================================
porta1     = 00h    ; Porta A do PPI1
portb1     = 01h    ; Porta B do PPI1
portc1     = 02h    ; Porta C do PPI1
ppi_confg1 = 03h    ; Registrador de controle do PPI1

; ==================================================================================
; MAPEAMENTO DE I/O — PPI 2 (8255)
; ==================================================================================
porta2     = 08h    ; Porta A do PPI2
portb2     = 09h    ; Porta B do PPI2
portc2     = 0Ah    ; Porta C do PPI2
ppi_confg2 = 0Bh    ; Registrador de controle do PPI2

; ==================================================================================
; VETOR DE RESET
; ==================================================================================
    .org 0000h
    jp start

; ==================================================================================
; PROGRAMA PRINCIPAL
; ==================================================================================
    .org 0100h

start:
    ; --------------------------------------------------------------------------
    ; 1. Inicialização da pilha
    ; --------------------------------------------------------------------------
    ld sp, 0FFFFh

    ; --------------------------------------------------------------------------
    ; 2. Configuração das PPIs — Modo 0, todas as portas como SAÍDA
    ; --------------------------------------------------------------------------
    ; Byte de controle para o Modo 0 com todas as portas como saída:
    ;   1000 0000b = 80h
    ;       │││
    ;       ││└── Porta C: saída
    ;       │└─── Porta B: saída
    ;       └──── Porta A: saída
    ; --------------------------------------------------------------------------
    ld a, 80h               ; 80h = Modo 0, A=out, B=out, C=out
    out (ppi_confg1), a     ; Configura o PPI1
    out (ppi_confg2), a     ; Configura o PPI2

    ; --------------------------------------------------------------------------
    ; 3. Loop principal — alterna entre dois padrões
    ; --------------------------------------------------------------------------
loop_principal:

    ; --- Estado 1: 0xAA / 0x55 / 0xF0 ---
    ld a, 0AAh              ; 1010 1010b
    out (porta1), a
    out (porta2), a

    ld a, 55h               ; 0101 0101b
    out (portb1), a
    out (portb2), a

    ld a, 0F0h              ; 1111 0000b
    out (portc1), a
    out (portc2), a

    call delay_curto        ; Aguarda um pouco

    ; --- Estado 2: padrões invertidos ---
    ld a, 55h
    out (porta1), a
    out (porta2), a

    ld a, 0AAh
    out (portb1), a
    out (portb2), a

    ld a, 0Fh               ; 0000 1111b
    out (portc1), a
    out (portc2), a

    call delay_curto        ; Aguarda um pouco

    jr loop_principal       ; Repete indefinidamente

; ==================================================================================
; SUB-ROTINA: delay_curto
; ==================================================================================
; Gera um atraso curto, usando o par BC como contador.
; Para delays mais longos, aumente o valor de BC.
; ==================================================================================
delay_curto:
    push bc                 ; Salva BC (para não corromper o chamador)
    ld bc, 0001h            ; Valor do contador (ajustar conforme a
                            ; velocidade do clock)
delay_loop:
    dec bc                  ; Decrementa BC
    ld a, b                 ; Carrega B em A
    or c                    ; OR com C — se ambos forem 0, o resultado é 0
    jr nz, delay_loop       ; Se não for zero, repete
    pop bc                  ; Restaura BC
    ret                     ; Retorna

.end
; ==================================================================================