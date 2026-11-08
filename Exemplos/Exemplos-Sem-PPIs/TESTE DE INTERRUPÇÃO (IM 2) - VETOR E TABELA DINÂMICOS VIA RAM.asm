; =================================================================================
; TESTE DE INTERRUPÇÃO (IM 2) - VETOR E TABELA DINÂMICOS VIA RAM
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique Cerqueira Braga
;
; OBJETIVO:
;   Demonstrar o funcionamento do Modo de Interrupção 2 (IM 2) com a
;   tabela de vetores armazenada na RAM e o vetor (offset) também na RAM.
;
; COMO FUNCIONA:
;   1. A tabela de vetores (endereços dos handlers) fica em 8000h.
;   2. O programa lê um "vetor" (ex: 02h) guardado em 8008h e o envia
;      para o Latch (Porta 80h).
;   3. Quando a interrupção ocorre, o Z80 lê o vetor do Latch, junta com
;      o registrador I (80h) e consulta a tabela na RAM em 8002h.
;   4. Ele salta para o handler apontado pela tabela.
;
; COMO TESTAR:
;   1. Rode o programa. O programa vai gravar o vetor 02h no Latch.
;   2. Aperte INT. O Z80 vai para o handler em 00A0h (Padrão AAh).
;   3. No monitor de memória, mude o valor em 8002h (byte baixo) para 0Fh.
;   4. Aperte INT novamente. O Z80 vai para o handler em 00F0h (Padrão 0Fh).
; =================================================================================

porta        = 01h         ; LEDs
vector_latch = 80h         ; Latch de Vetores
ram_tabela   = 8000h       ; Base da tabela de vetores na RAM
ram_vetor    = 8008h       ; Local onde o vetor (offset) fica guardado

; ==================================================================================
; --- Vetor de RESET ---
; ==================================================================================
.org 0000h
    jp init

; ==================================================================================
; --- Handlers de Interrupção ---
; ==================================================================================
.org 0080h
isr_00:
    push af
    ld a, 0F1h            ; Padrão do handler 00
    out (porta), a
    pop af
    ei
    reti

.org 00A0h
isr_02:
    push af
    ld a, 0AAh            ; Padrão do handler 02
    out (porta), a
    pop af
    ei
    reti

.org 00C0h
isr_04:
    push af
    ld a, 055h            ; Padrão do handler 04
    out (porta), a
    pop af
    ei
    reti

.org 00E0h
isr_06:
    push af
    ld a, 0CCh            ; Padrão do handler 06
    out (porta), a
    pop af
    ei
    reti

.org 00F0h
isr_alt:                  ; Handler extra para testar alteração na RAM
    push af
    ld a, 0Fh             ; Padrão do handler alternativo
    out (porta), a
    pop af
    ei
    reti

; ==================================================================================
; --- Programa Principal ---
; ==================================================================================
.org 0100h
init:
    ld sp, 0FFFFh          ; Inicializa a pilha

; ==================================================================================
; 1. TABELA DE VETORES (IM 2) - INICIALIZADA NA RAM POR CÓDIGO
; ==================================================================================
; NOTA DIDÁTICA:
; Em sistemas reais (e no Z80-EMU), a RAM é volátil e não é programada
; pelo arquivo .hex (que contém apenas a ROM). Ao ligar, a RAM contém lixo.
;
; Portanto, é uma BOA PRÁTICA (e obrigatória) inicializar tabelas e variáveis
; na RAM usando instruções de código (LD) no início do programa.
;
; Dados declarados com .DB ou .DW na RAM (8000h+) não são carregados,
; pois a RAM deve ser preenchida em tempo de execução pelo próprio Z80.
; ==================================================================================
;
; MAPA DE MEMÓRIA (A tabela em RAM fica em 8000h):
;
;   Endereço RAM | Conteúdo                  | Handler Apontado | Padrão nos LEDs
;   -------------|---------------------------|------------------|----------------
;   8000h e 8001h| Endereço de isr_00 (0080h)| isr_00           | F1h
;   8002h e 8003h| Endereço de isr_02 (00A0h)| isr_02           | AAh
;   8004h e 8005h| Endereço de isr_04 (00C0h)| isr_04           | 55h
;   8006h e 8007h| Endereço de isr_06 (00E0h)| isr_06           | CCh
;   8008h        | Vetor Atual (offset 02h)  | (seleciona 8002h)| AAh
;
; PARA O ALUNO AJUSTAR:
;   Se quiser que o vetor 02h aponte para o handler alternativo (isr_alt),
;   basta mudar o código do "ld hl, isr_02" para "ld hl, isr_alt".
;   O Z80 então saltará para 00F0h em vez de 00A0h.
; ==================================================================================

    ; --- Vetor 00h -> Handler isr_00 (endereço 0080h) ---
    ld hl, isr_00
    ld (ram_tabela + 0), hl   ; 8000h (byte baixo) / 8001h (byte alto)

    ; --- Vetor 02h -> Handler isr_02 (endereço 00A0h) ---
    ; Para testar o handler alternativo, troque "isr_02" por "isr_alt".
    ld hl, isr_02
    ld (ram_tabela + 2), hl   ; 8002h (byte baixo) / 8003h (byte alto)

    ; --- Vetor 04h -> Handler isr_04 (endereço 00C0h) ---
    ld hl, isr_04
    ld (ram_tabela + 4), hl   ; 8004h (byte baixo) / 8005h (byte alto)

    ; --- Vetor 06h -> Handler isr_06 (endereço 00E0h) ---
    ld hl, isr_06
    ld (ram_tabela + 6), hl   ; 8006h (byte baixo) / 8007h (byte alto)

    ; 2. Inicializa o Vetor (offset) na RAM
    ld a, 02h
    ld (ram_vetor), a       ; 8008h = 02h

    ; 3. Configura IM 2 com I = 80h
    ld a, 80h
    ld i, a
    im 2

    ; 4. Habilita interrupções
    ei

loop:
    ; --- O "Coração" da alteração dinâmica ---
    ; Lê o vetor da RAM e joga no Latch
    ld a, (ram_vetor)
    out (vector_latch), a

    ; Delay curto
    ld b, 01h
delay_curto:
    djnz delay_curto

    jp loop

.end