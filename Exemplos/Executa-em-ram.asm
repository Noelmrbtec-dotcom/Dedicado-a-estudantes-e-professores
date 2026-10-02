; =================================================================================
; Entendendo funcionamento de processadores (Z80) Zilog
; Autor: Marcos Roberto Braga
; Data: 17/09/2025
; Aluno: Pedro Henrique Cerqueira Braga
; Programa em ROM que roda na RAM
;
; OBJETIVO:
;   Demonstrar o uso de um programa auto-copiativo, que é gravado na ROM
;   mas executado na RAM. O código configura as duas PPIs 8255 e escreve
;   valores alternados nas Portas A e C de ambas, criando um efeito
;   visual de "pisca-pisca".
;
; HARDWARE MAPEADO:
;   PPI 1: endereços 0x00-0x03
;   PPI 2: endereços 0x08-0x0B
;***********************************************************************************

; ==================================================================================
; MAPEAMENTO DE I/O — PPI 1 (8255)
; ==================================================================================
porta1     = 00h    ; Porta A do PPI1 (LEDs)
portb1     = 01h    ; Porta B do PPI1 (LEDs)
portc1     = 02h    ; Porta C do PPI1 (LEDs)
ppi_confg1 = 03h    ; Registrador de controle do PPI1

; ==================================================================================
; MAPEAMENTO DE I/O — PPI 2 (8255)
; ==================================================================================
porta2     = 08h    ; Porta A do PPI2 (LEDs)
portb2     = 09h    ; Porta B do PPI2 (LEDs)
portc2     = 0Ah    ; Porta C do PPI2 (LEDs)
ppi_confg2 = 0Bh    ; Registrador de controle do PPI2

; ==================================================================================
; --- Vetor de RESET ---
; ==================================================================================
.org 0000h
    jp inicio_rom

; ==================================================================================
; --- Código principal na ROM ---
; ==================================================================================
.org 0030h

inicio_rom:
    ; --------------------------------------------------------------------------
    ; 1. Inicialização da pilha
    ; --------------------------------------------------------------------------
    ld sp, 0FFFFh           ; SP no topo da RAM disponível

    ; --------------------------------------------------------------------------
    ; 2. Cópia do programa da ROM para a RAM
    ; --------------------------------------------------------------------------
    ; Copia o código de inicio_rom até fim_programa para 0x8000.
    ; Usa LDIR: (HL) → (DE), incrementa HL e DE, decrementa BC até 0.
    ; --------------------------------------------------------------------------
    ld hl, inicio_rom                       ; Origem: código na ROM
    ld de, 8000h                            ; Destino: RAM (0x8000)
    ld bc, fim_programa - inicio_rom        ; Tamanho do código
    ldir                                    ; Copia bloco inteiro

    ; --------------------------------------------------------------------------
    ; 3. Salto para execução na RAM
    ; --------------------------------------------------------------------------
    jp 8000h + (inicio_ram - inicio_rom)

; ==================================================================================
; --- Esta parte será executada na RAM ---
; ==================================================================================
inicio_ram:
    ; --------------------------------------------------------------------------
    ; 4. Configuração das duas PPIs — Modo 0, todas as portas como SAÍDA
    ; --------------------------------------------------------------------------
    ; Byte de controle:
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
    ; 5. Inicialização do valor de trabalho
    ; --------------------------------------------------------------------------
    ; Padrão inicial: 0x55 (0101 0101b).
    ; O CPL vai alternar entre 0x55 e 0xAA a cada ciclo.
    ; --------------------------------------------------------------------------
    ld a, 55h               ; Padrão inicial 01010101

; --------------------------------------------------------------------------
; 6. Loop principal — alterna nas Portas A e C das duas PPIs
; --------------------------------------------------------------------------
loop_ram:
    ; --- 6.1: Escreve o valor atual nas Portas A e C do PPI1 ---
    out (porta1), a         ; Porta A do PPI1
    out (portc1), a         ; Porta C do PPI1

    ; --- 6.2: Escreve o valor atual nas Portas A e C do PPI2 ---
    out (porta2), a         ; Porta A do PPI2
    out (portc2), a         ; Porta C do PPI2

    ; --- 6.3: Inverte os bits e repete ---
    ; CPL: complemento de 1 (0x55 → 0xAA, 0xAA → 0x55)
    ; --------------------------------------------------------------------------
    cpl                     ; A = ~A (alterna o padrão)

    ; --- 6.4: Volta ao início do loop ---
    jp loop_ram             ; Repete indefinidamente

fim_programa:
;==================================================================================
.end
;**************************Fim******************************************************