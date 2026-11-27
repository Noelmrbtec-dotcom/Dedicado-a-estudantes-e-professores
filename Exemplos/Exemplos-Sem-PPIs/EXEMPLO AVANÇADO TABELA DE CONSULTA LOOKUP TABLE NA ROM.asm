; =================================================================================
; EXEMPLO AVANÇADO: TABELA DE CONSULTA (LOOKUP TABLE) NA ROM
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique Cerqueira Braga
;
; OBJETIVO:
;   Demonstrar como usar uma tabela de dados fixos na ROM para gerar padrões
;   visuais nos LEDs. O programa lê um valor de 0 a 7 nos switches (Porta B),
;   usa esse valor como um índice (offset) para buscar um padrão pré-definido
;   na tabela da ROM, e envia o padrão resultante para os LEDs (Porta A).
;
;   Este é o conceito fundamental de sistemas embarcados: evitar lógica
;   complexa (como contadores e comparadores) trocando-a por uma tabela
;   simples na memória.
;
; MAPA DE I/O (Conforme definido no esquema base):
;   Porta A (01h) = SAÍDA (LEDs) - Mostra o padrão da tabela
;   Porta B (02h) = ENTRADA (Switches) - Seleciona o índice (0 a 7)
; =================================================================================

porta       = 01h      ; Porta A - Saída (LEDs)
portb       = 02h      ; Porta B - Entrada (Switches)

    org 0000h
    jp init

    org 0038h
    ei
    reti               ; INT ignorada

    org 0066h
    retn               ; NMI ignorada

    org 0100h
init:
    ld sp, 0FFFFh      ; Inicializa a pilha no topo da RAM

; =================================================================================
; --- Loop Principal ---
; =================================================================================
loop:

; ---------------------------------------------------------------------------------
;   Abilita IM 1 (Vetor 038h)
; ---------------------------------------------------------------------------------
    IM 1           ; Configura INT para IM 1
    ei             ; Abilita INT(IM 1)

    ; 1. LÊ O SWITCH E ISOLA O ÍNDICE
    in a, (portb)      ; Lê o estado dos switches da Porta B
    and 07h            ; Máscara: mantém apenas os 3 bits mais baixos (0 a 7)
                       ; Garante que o índice nunca ultrapasse o tamanho da tabela!

    ; 2. CALCULA O ENDEREÇO DO ITEM NA TABELA
    ld hl, tabela_leds ; HL = Endereço base da tabela na ROM
    ld e, a            ; E = Índice (obtido do switch)
    ld d, 0            ; D = 0 (limpa a parte alta para não afetar a soma)
    add hl, de         ; HL = HL + DE (Endereço base + Índice)

    ; 3. BUSCA O PADRÃO NA ROM E ENVIA PARA OS LEDS
    ld a, (hl)         ; A = Valor apontado por HL (o padrão da tabela)
    out (porta), a     ; Envia o padrão para os LEDs da Porta A

    ; 4. DELAY (Pequeno delay para visualização)
    call delay_curto
    jr loop            ; Volta para ler o switch novamente

; =================================================================================
; --- Sub-rotina de Delay ---
; =================================================================================
delay_curto:
    push bc
    ld bc, 0001h       ; Valor do delay (ajustar conforme o clock)
delay_loop:
    dec bc
    ld a, b
    or c
    jr nz, delay_loop
    pop bc
    ret

; =================================================================================
; --- DADOS NA ROM (A Tabela de Consulta) ---
; =================================================================================
; A tabela abaixo define 8 padrões diferentes de LEDs.
; O aluno pode alterar esses valores livremente!
; ---------------------------------------------------------------------------------
tabela_leds:
    db 00000001b       ; Índice 0: Um LED aceso na ponta direita
    db 00000011b       ; Índice 1: Dois LEDs acesos
    db 00000111b       ; Índice 2: Três LEDs acesos
    db 00001111b       ; Índice 3: Quatro LEDs acesos
    db 00011111b       ; Índice 4: Cinco LEDs acesos
    db 00111111b       ; Índice 5: Seis LEDs acesos
    db 01111111b       ; Índice 6: Sete LEDs acesos
    db 11111111b       ; Índice 7: Todos os LEDs acesos

.end