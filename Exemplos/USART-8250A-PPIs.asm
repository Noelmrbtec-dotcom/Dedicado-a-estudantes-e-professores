;***********************************************************************************
; Entendendo o funcionamento de processadores (Z80) Zilog
; Autor: Marcos Roberto Braga
; Data: 17/09/2025
; Aluno: Pedro Henrique Cerqueira Braga
;
; PROGRAMA: Teste de USART 8250A com dois PPIs 8255
;
; OBJETIVO:
;   Demonstrar, em assembly Z80, como configurar e usar:
;     1. Dois chips PPI 8255 (Parallel Peripheral Interface)
;     2. Um chip USART 8250A (Universal Synchronous/Asynchronous Receiver/Transmitter)
;
; Este programa é executado no emulador Z80-PIC, que roda em um
; microcontrolador PIC18F6722 real (ou simulado no Proteus).
;
; HARDWARE NECESSÁRIO:
;   - CPU Z80 (emulada)
;   - 2x PPI 8255 (mapeados em I/O)
;   - 1x USART 8250A (mapeada em I/O)
;   - Terminal serial ou osciloscópio na saída serial (para ver os caracteres)
;***********************************************************************************

;***********************************************************************************
; ALOCAÇÃO DO PROGRAMA NA ROM
;***********************************************************************************
; O código começa em 0x0000 (vetor de reset do Z80)
; e o programa principal em 0x0100 (convenção de CP/M)

; ==================================================================================
; MAPEAMENTO DE I/O — PPI 1 (8255)
; ==================================================================================
; O 8255 tem 3 portas de 8 bits (A, B, C) + 1 registrador de controle.
; Cada PPI ocupa 4 endereços de I/O.
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
; MAPEAMENTO DE I/O — USART 8250A
; ==================================================================================
; O 8250A tem vários registradores, mapeados em 8 endereços de I/O.
; Aqui usamos apenas os essenciais:
;   - THR/RBR (Transmit/Receive Buffer) — mesmo endereço, depende de leitura/escrita
;   - LCR (Line Control Register)          — configuração da linha serial
;   - LSR (Line Status Register)           — status da transmissão
; ==================================================================================
uart_dado    = 10h    ; THR (escrita) / RBR (leitura) — dados seriais
uart_control = 13h    ; LCR — controle da linha (DLAB, paridade, stop bits)
uart_status  = 15h    ; LSR — status da linha (data ready, THR empty, etc.)

; ==================================================================================
; VETOR DE RESET — o Z80 começa a executar em 0x0000
; ==================================================================================
    .org 0000h
    jp start            ; Salta para o início do programa

; ==================================================================================
; PROGRAMA PRINCIPAL — começa em 0x0100
; ==================================================================================
    .org 0100h

start:
    ; --------------------------------------------------------------------------
    ; 1. Inicialização da pilha
    ; --------------------------------------------------------------------------
    ; O SP aponta para o topo da RAM. Como estamos no fim do espaço de
    ; endereçamento (0xFFFF), a pilha cresce para baixo.
    ld sp, 0FFFFh

    ; --------------------------------------------------------------------------
    ; 2. Teste dos PPIs
    ; --------------------------------------------------------------------------
    ; Chama a sub-rotina que testa os dois PPIs (8255).
    ; Ela configura as portas, escreve valores e lê de volta.
    call PPI_TESTE

    ; --------------------------------------------------------------------------
    ; 3. Configuração do 8250A
    ; --------------------------------------------------------------------------
    ; Para configurar o baud rate, precisamos setar o bit DLAB (Divisor
    ; Latch Access Bit) do registrador LCR.
    ; Quando DLAB=1, os endereços 0x10 e 0x11 viram DLL e DLM.

    ld a, 80h               ; 80h = 1000 0000b → DLAB=1
    out (uart_control), a   ; Escreve no LCR

    ; Configura o divisor para 9600 baud.
    ; A fórmula é: divisor = clock / (16 * baud)
    ; Com clock de 1.8432 MHz, o divisor para 9600 baud é 12 (0x000C).
    ld a, 0Ch               ; DLL = 0x0C (parte baixa do divisor)
    out (uart_dado), a      ; Escreve no endereço 0x10 (DLL)

    ld a, 00h
    out (11h), a            ; DLM = 0x00 (parte alta do divisor)

    ; Agora desabilita DLAB e configura o formato da linha: 8 bits, sem
    ; paridade, 1 stop bit (8N1).
    ; 03h = 0000 0011b → 8 bits, 1 stop, sem paridade
    ld a, 03h
    out (uart_control), a   ; Escreve no LCR (agora DLAB=0)

    ; --------------------------------------------------------------------------
    ; 4. Envio da mensagem inicial
    ; --------------------------------------------------------------------------
    ; Envia a string "Sistema 8250A OK!" seguida de CR+LF.
    ld hl, mensagem         ; HL aponta para o início da string

envia_string:
    ld a, (hl)              ; Carrega o caractere atual
    or a                    ; Verifica se é o terminador (0x00)
    jr z, loop_principal    ; Se for zero, termina o envio
    out (uart_dado), a      ; Envia o caractere pela serial
    inc hl                  ; Avança para o próximo caractere
    jr envia_string         ; Repete

    ; --------------------------------------------------------------------------
    ; 5. Loop principal — envia caracteres continuamente
    ; --------------------------------------------------------------------------
loop_principal:
    ld a, 30h               ; Começa com '0' (0x30 na tabela ASCII)

loop:
    out (uart_dado), a      ; Envia o caractere atual
    push af                 ; Salva A (o caractere)
    call delay              ; Chama a sub-rotina de delay
    pop af                  ; Restaura A
    inc a                   ; Incrementa o caractere ('0' → '1' → '2' ...)
    jr loop                 ; Repete

; ==================================================================================
; SUB-ROTINA: delay
; ==================================================================================
; Gera um atraso simples, usando o par BC como contador.
; O valor de BC controla a duração do atraso.
; ==================================================================================
delay:
    push bc                 ; Salva BC (para não corromper o chamador)
    ld bc, 0001h            ; Valor inicial do contador
                            ; (ajustar conforme a velocidade desejada)
delay_loop:
    dec bc                  ; Decrementa BC
    ld a, b                 ; Carrega B em A
    or c                    ; OR com C — se ambos forem 0, o resultado é 0
    jr nz, delay_loop       ; Se não for zero, repete
    pop bc                  ; Restaura BC
    ret                     ; Retorna

; ==================================================================================
; SUB-ROTINA: PPI_TESTE
; ==================================================================================
; Testa os dois chips PPI 8255, configurando as portas e verificando
; se os valores escritos podem ser lidos de volta.
;
; O 8255 tem 3 modos de operação. Aqui usamos o Modo 0 (I/O simples):
;   - Porta A: saída
;   - Porta B: entrada
;   - Porta C: saída
;
; O byte de configuração para o Modo 0 é:
;   1000 0010b = 82h
; ==================================================================================
PPI_TESTE:
    ; --------------------------------------------------------------------------
    ; Teste do PPI1 (endereços 0x00-0x03)
    ; --------------------------------------------------------------------------
    ld a, 82h               ; 82h = 1000 0010b → Modo 0, A=out, B=in, C=out
    out (ppi_confg1), a     ; Configura o PPI1

    ld a, 0AAh              ; 1010 1010b — padrão de teste
    out (porta1), a         ; Escreve na Porta A do PPI1

    ld a, 55h               ; 0101 0101b — padrão complementar
    out (portc1), a         ; Escreve na Porta C do PPI1

    in a, (portb1)          ; Lê a Porta B do PPI1
    out (portc1), a         ; Mostra o valor lido na Porta C

    ; --------------------------------------------------------------------------
    ; Teste do PPI2 (endereços 0x08-0x0B)
    ; --------------------------------------------------------------------------
    ld a, 82h               ; Mesma configuração do PPI1
    out (ppi_confg2), a     ; Configura o PPI2

    ld a, 0AAh
    out (porta2), a         ; Escreve na Porta A do PPI2

    ld a, 55h
    out (portc2), a         ; Escreve na Porta C do PPI2

    in a, (portb2)          ; Lê a Porta B do PPI2
    out (portc2), a         ; Mostra o valor lido na Porta C

    ; --------------------------------------------------------------------------
    ; Limpeza — zera todas as portas
    ; --------------------------------------------------------------------------
    ld a, 00h
    out (porta1), a
    out (portc1), a
    out (porta2), a
    out (portc2), a

    ret                     ; Retorna ao chamador

; ==================================================================================
; DADOS
; ==================================================================================
mensagem:
    db "Sistema 8250A OK!", 0Dh, 0Ah, 0
    ; 0Dh = CR (Carriage Return)
    ; 0Ah = LF (Line Feed)
    ; 00h = terminador de string

.end
