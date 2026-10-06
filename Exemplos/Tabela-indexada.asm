; =================================================================================
; Entendendo funcionamento de processadores (Z80) Zilog
; Autor: Marcos Roberto Braga
; Data: 17/09/2025
; Aluno: Pedro Henrique Cerqueira Braga
; Tabela indexada — Busca e escrita na PPI1
;
; OBJETIVO:
;   Demonstrar o uso de tabelas indexadas no Z80, com busca linear usando
;   IX como ponteiro. Após encontrar o valor, o programa escreve esse valor
;   na Porta A do PPI1 (LEDs).
;
; HARDWARE MAPEADO:
;   PPI1: porta   = 00h (Porta A — LEDs)
;         ppi_confg1 = 03h (Registrador de controle)
; =================================================================================

; =================================================================================
; MAPEAMENTO DE I/O — PPI 1 (8255)
; =================================================================================
porta      = 00h    ; Porta A do PPI1 (LEDs)
ppi_confg1 = 03h    ; Registrador de controle do PPI1

; =================================================================================
; --- Vetor de RESET ---
; =================================================================================
    org 0000h
    jp inicio

; =================================================================================
; --- Vetor de Interrupção ---
; =================================================================================
    org 0038h
    reti              ; Retorno de interrupção mascarável (INT)

    org 0066h
    retn              ; Retorno de interrupção não-mascárável (NMI)

; =================================================================================
; --- Dados em ROM ---
; =================================================================================
    org 0100h

tabela_dados:
    db 11h, 22h, 33h, 44h, 55h, 66h, 77h, 88h
    ; Tabela de 8 bytes, usada para busca

estrutura_origem:
    db 0AAh, 0BBh, 0CCh, 0DDh, 0EEh, 0FFh
    ; Estrutura de 6 bytes, usada para cópia com offsets

; =================================================================================
; --- Área de trabalho em RAM ---
; =================================================================================
    org 8000h

buffer_destino:
    ds 10h            ; Reserva 16 bytes para o destino da cópia

estrutura_destino:
    ds 8              ; Reserva 8 bytes para a estrutura destino

; =================================================================================
; --- Variáveis ---
; =================================================================================
    org 8100h

resultado_busca:
    db 0              ; Armazena a posição do valor encontrado (0 a 7)

; =================================================================================
; --- Programa Principal ---
; =================================================================================
    org 0030h

inicio:
    ld sp, FFFFh              ; Inicializa o Stack Pointer no topo da RAM

    ; ******************************************************************
    ; 1. CONFIGURAÇÃO DA PPI1 — Modo 0, todas as portas como SAÍDA
    ; ******************************************************************
    ; Byte de controle:
    ;   1000 0000b = 80h
    ;       │││
    ;       ││└── Porta C: saída
    ;       │└─── Porta B: saída
    ;       └──── Porta A: saída
    ; ------------------------------------------------------------------
    ld a, 80h                 ; 80h = Modo 0, A=out, B=out, C=out
    out (ppi_confg1), a       ; Configura o PPI1

    ; ******************************************************************
    ; 2. EXEMPLO 1: Cópia simples usando IX e IY como ponteiros
    ; ******************************************************************
    ld ix, tabela_dados       ; IX aponta para origem (tabela_dados)
    ld iy, buffer_destino     ; IY aponta para destino (buffer_destino)
    ld b, 8                   ; 8 bytes para copiar

loop_copia_simples:
    ld a, (ix + 0)            ; Lê byte da origem
    ld (iy + 0), a            ; Escreve byte no destino
    inc ix                    ; Próxima posição origem
    inc iy                    ; Próxima posição destino
    djnz loop_copia_simples   ; Repete até B=0

    ; ******************************************************************
    ; 3. EXEMPLO 2: Acesso com offsets fixos (estruturas de dados)
    ; ******************************************************************
    ld ix, estrutura_origem   ; IX aponta para estrutura origem
    ld iy, estrutura_destino  ; IY aponta para estrutura destino

    ; Copia campos específicos com offsets
    ld a, (ix + 0)            ; Campo 1 (offset 0)
    ld (iy + 0), a            ; Para campo 1 do destino

    ld a, (ix + 2)            ; Campo 3 (offset 2)
    ld (iy + 2), a            ; Para campo 3 do destino

    ld a, (ix + 4)            ; Campo 5 (offset 4)
    ld (iy + 4), a            ; Para campo 5 do destino

    ; ******************************************************************
    ; 4. EXEMPLO 3: Manipulação de array com índice variável
    ; ******************************************************************
    ld ix, tabela_dados       ; IX = base do array origem
    ld iy, buffer_destino     ; IY = base do destino
    ld b, 4                   ; Número de elementos
    ld c, 0                   ; Índice inicial

loop_array:
    ; Calcula offset: origem[índice*2]
    ld a, c                   ; A = índice
    add a, a                  ; A = índice * 2
    ld e, a
    ld d, 0                   ; DE = offset

    push ix
    pop hl                    ; HL = base do array origem
    add hl, de                ; HL = base + offset
    ld a, (hl)                ; Lê elemento

    ; Escreve no destino[índice]
    ld e, c
    ld d, 0                   ; DE = índice
    push iy
    pop hl                    ; HL = base destino
    add hl, de                ; HL = base + índice
    ld (hl), a                ; Armazena elemento

    inc c                     ; Próximo índice
    djnz loop_array           ; Repete

    ; ******************************************************************
    ; 5. EXEMPLO 4: Busca em tabela usando IX
    ; ******************************************************************
    ; Esta é a parte principal do exemplo: busca o valor 0x55 na tabela.
    ; Se encontrado, escreve o valor na PPI1 (Porta A).
    ; ------------------------------------------------------------------
    ld b, 8                   ; Número de elementos da tabela
    ld c, 55h                 ; Valor a buscar (0x55)
    ld ix, tabela_dados       ; IX aponta para o início da tabela

    ld e, 0FFh                ; E = posição encontrada (FFh = não encontrado)

busca_loop:
    ld a, (ix + 0)            ; Lê o elemento atual da tabela
    cp c                      ; Compara com o valor buscado (0x55)
    jr nz, nao_encontrado     ; Se não é igual, continua a busca

    ; --- Valor encontrado! ---
    ; Calcula a posição relativa:
    ;   posição = (endereço atual) - (início da tabela)
    ; ------------------------------------------------------------------
    push ix
    pop hl                    ; HL = endereço atual
    ld de, tabela_dados       ; DE = início da tabela
    xor a                     ; A = 0 (limpa carry)
    sbc hl, de                ; HL = posição relativa (0 a 7)
    ld e, l                   ; E = posição encontrada

    ; --- ESCREVE O VALOR ENCONTRADO NA PPI1 (Porta A) ---
    ; O valor encontrado (0x55) é escrito na Porta A do PPI1,
    ; acendendo os LEDs correspondentes.
    ; ------------------------------------------------------------------
    ld a, (ix + 0)            ; Recarrega o valor encontrado (0x55)
    out (porta), a            ; Escreve na Porta A do PPI1 (LEDs)

    jr fim_busca              ; Sai da busca

nao_encontrado:
    inc ix                    ; Próximo elemento da tabela
    djnz busca_loop           ; Continua a busca

fim_busca:
    ; --- Armazena o resultado em RAM ---
    ; Salva a posição encontrada (0-7) ou FFh (não encontrado).
    ; ------------------------------------------------------------------
    ld a, e                   ; A = posição encontrada
    ld (resultado_busca), a   ; Armazena resultado em RAM

    ; --- Fim do programa ---
    halt                      ; Para a CPU

; =================================================================================
.end
;**************************Fim******************************************************