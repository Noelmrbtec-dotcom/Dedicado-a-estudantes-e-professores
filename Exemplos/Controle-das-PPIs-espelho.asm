;***********************************************************************************
; Entendendo o funcionamento de processadores (Z80) Zilog
; Autor: Marcos Roberto Braga
; Data: 17/09/2025
; Aluno: Pedro Henrique Cerqueira Braga
;
; Z80-PIC — Exemplo: Espelhar a Porta B nas Portas A e C
;
; OBJETIVO:
;   Demonstrar o uso de duas PPIs 8255 configuradas com portas de
;   ENTRADA e SAÍDA. O programa lê o valor da Porta B do PPI1 (entrada)
;   e replica esse valor nas Portas A e C das duas PPIs.
;
;   Este exemplo ensina, na prática, o conceito de:
;     - Leitura de portas paralelas (IN)
;     - Escrita em portas paralelas (OUT)
;     - Mapeamento de I/O no Z80
;     - Replicação de dados em múltiplas saídas
;
; HARDWARE NECESSÁRIO:
;   - CPU Z80 (emulada)
;   - 2x PPI 8255 (mapeadas em I/O)
;   - Chaves (dip switch) conectadas na Porta B do PPI1 (entrada)
;   - LEDs conectados nas Portas A e C das duas PPIs (saídas)
;
; HARDWARE MAPEADO:
;   PPI 1: endereços 0x00-0x03
;   PPI 2: endereços 0x08-0x0B
;***********************************************************************************

; ==================================================================================
; MAPEAMENTO DE I/O — PPI 1 (8255)
; ==================================================================================
porta1     = 00h    ; Porta A do PPI1  — SAÍDA (LEDs)
portb1     = 01h    ; Porta B do PPI1  — ENTRADA (chaves)
portc1     = 02h    ; Porta C do PPI1  — SAÍDA (LEDs)
ppi_confg1 = 03h    ; Registrador de controle do PPI1

; ==================================================================================
; MAPEAMENTO DE I/O — PPI 2 (8255)
; ==================================================================================
porta2     = 08h    ; Porta A do PPI2  — SAÍDA (LEDs)
portb2     = 09h    ; Porta B do PPI2  — SAÍDA (LEDs)
portc2     = 0Ah    ; Porta C do PPI2  — SAÍDA (LEDs)
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
    ; 2. Configuração das PPIs
    ; --------------------------------------------------------------------------
    ; PPI1 — Porta B = ENTRADA, Portas A e C = SAÍDA
    ;   Byte de controle:
    ;     1000 0010b = 82h
    ;        │││
    ;        ││└── Porta C (baixa): saída
    ;        │└─── Porta B: entrada
    ;        └──── Porta A: saída
    ;   (Porta C alta: saída)
    ; --------------------------------------------------------------------------
    ld a, 82h               ; 82h = Modo 0, A=out, B=in, C=out
    out (ppi_confg1), a     ; Configura o PPI1

    ; PPI2 — Todas as portas como SAÍDA
    ;   Byte de controle:
    ;     1000 0000b = 80h
    ; --------------------------------------------------------------------------
    ld a, 80h               ; 80h = Modo 0, A=out, B=out, C=out
    out (ppi_confg2), a     ; Configura o PPI2

    ; --------------------------------------------------------------------------
    ; 3. Loop principal — lê da Porta B e espelha em A e C
    ; --------------------------------------------------------------------------
loop_principal:

    ; --- 3.1: Lê o valor das chaves (Porta B do PPI1) ---
    in a, (portb1)          ; Lê a Porta B do PPI1
                            ; A = valor das chaves (0x00-0xFF)

    ; --- 3.2: Espelha o valor lido na Porta A das duas PPIs ---
    out (porta1), a         ; Porta A do PPI1 (LEDs)
    out (porta2), a         ; Porta A do PPI2 (LEDs)

    ; --- 3.3: Espelha o valor lido na Porta C das duas PPIs ---
    out (portc1), a         ; Porta C do PPI1 (LEDs)
    out (portc2), a         ; Porta C do PPI2 (LEDs)

    ; --- 3.4: Espelha também na Porta B do PPI2 (LEDs) ---
    out (portb2), a         ; Porta B do PPI2 (LEDs)

    ; --- 3.5: Aguarda um curto delay ---
    call delay_curto

    ; --- 3.6: Volta ao início do loop ---
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