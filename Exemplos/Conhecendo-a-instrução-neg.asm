;***********************************************************************************
; Entendendo o funcionamento de processadores (Z80) Zilog
; Autor: Marcos Roberto Braga
; Data: 17/09/2025
; Aluno: Pedro Henrique Cerqueira Braga
;
; Z80-PIC — Exemplo: Incrementar e alternar valores com NEG nas PPIs
;
; OBJETIVO:
;   Demonstrar o uso da instrução NEG (complemento de 2) combinada com
;   INC (incremento) para gerar uma sequência variada de valores escritos
;   alternadamente nas duas PPIs 8255.
;
;   Este exemplo ensina, na prática, o conceito de:
;     - Instrução NEG (complemento de 2)
;     - Instrução INC (incremento)
;     - Uso de registradores auxiliares (D)
;     - Geração de sequência numérica com overflow natural
;     - Escrita em múltiplas portas paralelas
;
; HARDWARE NECESSÁRIO:
;   - CPU Z80 (emulada)
;   - 2x PPI 8255 (mapeadas em I/O)
;   - LEDs conectados nas portas A, B e C das duas PPIs (saídas)
;
; HARDWARE MAPEADO:
;   PPI 1: endereços 0x00-0x03
;   PPI 2: endereços 0x08-0x0B
;***********************************************************************************

; ==================================================================================
; MAPEAMENTO DE I/O — PPI 1 (8255)
; ==================================================================================
porta1     = 00h    ; Porta A do PPI1  — SAÍDA (LEDs)
portb1     = 01h    ; Porta B do PPI1  — SAÍDA (LEDs)
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
; O Z80 começa a executar em 0x0000 após o reset.
; Aqui colocamos um salto para o início do programa (0x0100).
; ==================================================================================
    .org 0000h
    jp start

; ==================================================================================
; PROGRAMA PRINCIPAL — começa em 0x0100
; ==================================================================================
    .org 0100h

start:
    ; --------------------------------------------------------------------------
    ; 1. Inicialização da pilha
    ; --------------------------------------------------------------------------
    ; O Stack Pointer (SP) é inicializado no topo da RAM (0xFFFF).
    ; A pilha cresce para baixo. Isso é necessário para o CALL/RET.
    ; --------------------------------------------------------------------------
    ld sp, 0FFFFh

    ; --------------------------------------------------------------------------
    ; 2. Configuração das PPIs — Modo 0, todas as portas como SAÍDA
    ; --------------------------------------------------------------------------
    ; Byte de controle:
    ;   1000 0000b = 80h
    ;       │││
    ;       ││└── Porta C: saída
    ;       │└─── Porta B: saída
    ;       └──── Porta A: saída
    ;
    ; O bit 7 = 1 ativa o modo de configuração.
    ; Os bits 6-5 = 00 selecionam o Modo 0 (I/O simples).
    ; Os bits 4, 3, 1, 0 = 0 configuram as portas como SAÍDA.
    ; --------------------------------------------------------------------------
    ld a, 80h               ; 80h = Modo 0, A=out, B=out, C=out
    out (ppi_confg1), a     ; Configura o PPI1
    out (ppi_confg2), a     ; Configura o PPI2

    ; --------------------------------------------------------------------------
    ; 3. Inicialização do valor de trabalho (no registrador D)
    ; --------------------------------------------------------------------------
    ; Usamos D para guardar o valor, porque o delay usa BC.
    ; Se usássemos B, o delay iria destruir o valor guardado.
    ;
    ; O valor inicial é 0x01 (0000 0001b).
    ; A cada ciclo, INC incrementa o valor, gerando uma sequência:
    ;   0x01, 0x02, 0x03, ..., 0xFF, 0x00, 0x01, ...
    ; --------------------------------------------------------------------------
    ld d, 01h               ; D = 0x01 (valor inicial)

    ; --------------------------------------------------------------------------
    ; 4. Loop principal — escreve, nega, escreve, incrementa
    ; --------------------------------------------------------------------------
    ; O ciclo do programa é:
    ;   4.1: Escreve o valor atual (D) no PPI1
    ;   4.2: Nega o valor (NEG) e escreve no PPI2
    ;   4.3: Incrementa o valor guardado (D)
    ;   4.4: Aguarda um curto delay
    ;   4.5: Volta ao início do loop
    ; --------------------------------------------------------------------------
loop_principal:

    ; --- 4.1: Escreve o valor atual (D) nas portas do PPI1 ---
    ; Carrega o valor guardado em D para o acumulador A,
    ; e escreve nas três portas do PPI1.
    ; --------------------------------------------------------------------------
    ld a, d                 ; A = D (valor atual)
    out (porta1), a         ; Porta A do PPI1 = A
    out (portb1), a         ; Porta B do PPI1 = A
    out (portc1), a         ; Porta C do PPI1 = A

    ; --- 4.2: Nega o valor e escreve nas portas do PPI2 ---
    ; A instrução NEG calcula o complemento de 2 (0 - A).
    ; Exemplo:
    ;   0x01 (1)  -> NEG -> 0xFF (-1)
    ;   0x02 (2)  -> NEG -> 0xFE (-2)
    ;   0x03 (3)  -> NEG -> 0xFD (-3)
    ;   ...
    ;   0xFF (-1) -> NEG -> 0x01 (1)
    ; --------------------------------------------------------------------------
    neg                     ; A = 0 - A (complemento de 2)
    out (porta2), a         ; Porta A do PPI2 = A
    out (portb2), a         ; Porta B do PPI2 = A
    out (portc2), a         ; Porta C do PPI2 = A

    ; --- 4.3: Incrementa o valor guardado em D ---
    ; O próximo ciclo usará o valor original + 1.
    ; O overflow natural do INC (0xFF + 1 = 0x00) reinicia a sequência.
    ; --------------------------------------------------------------------------
    inc d                   ; D = D + 1 (próximo ciclo)

    ; --- 4.4: Aguarda um curto delay ---
    ; Isso dá tempo para o olho humano perceber a mudança nos LEDs.
    ; --------------------------------------------------------------------------
    call delay_curto

    ; --- 4.5: Volta ao início do loop ---
    ; O programa repete indefinidamente.
    ; --------------------------------------------------------------------------
    jr loop_principal       ; Repete indefinidamente

; ==================================================================================
; SUB-ROTINA: delay_curto
; ==================================================================================
; Gera um atraso curto, usando o par BC como contador.
; Para delays mais longos, aumente o valor de BC.
;
; IMPORTANTE:
;   Esta sub-rotina usa BC. Por isso o valor de trabalho é guardado em D.
;   Se usássemos B para guardar o valor, o delay iria destruí-lo.
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