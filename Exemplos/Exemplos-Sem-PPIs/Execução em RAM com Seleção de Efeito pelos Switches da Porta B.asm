; =================================================================================
; EXEMPLO: Execução em RAM com 5 Efeitos Selecionáveis pelos Switches
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique Cerqueira Braga
;
; EFEITOS:
;   Switch 00h: Pisca (55h / AAh)
;   Switch 01h: Barra (F0h / 0Fh)
;   Switch 02h: Corrida Esquerda -> Direita (RLCA)
;   Switch 03h: Tudo Aceso / Tudo Apagado (FFh / 00h)
;   Switch 04h: Corrida Direita -> Esquerda (RRCA)
; =================================================================================

porta    = 01h             ; Porta A (SAÍDA - LEDs)
portb    = 02h             ; Porta B (ENTRADA - Switches)

    org 0000h              ; Vetor de RESET
    jp main

; =================================================================================
; Vetor de NMI (Endereço fixo 0066h)
; =================================================================================
    org 0066h
nmi_handler:
    retn                   ; Retorna imediatamente (ignora a NMI)
                           ; Isso garante que o LDIR e outras instruções
                           ; de bloco sejam retomados corretamente.

                           ; ======================================================
; =================================================================================
; Vetor de INT no modo IM 1 (Endereço fixo 0038h)
; =================================================================================
    org 0038h
int_handler_im1:
    ; Se uma INT ocorrer (por ruído, bounce ou teste), o Z80 cai aqui.
    ei                     ; Reabilita interrupções (boa prática)
    reti                   ; Retorna da interrupção
                           ; Isso garante que o LDIR e outras instruções
                           ; de bloco sejam retomados corretamente.

; =================================================================================
; Programa principal (na ROM)
; =================================================================================
    org 0100h
main:
    ld sp, 0FFFFh          ; SP = topo da RAM

    ; --- Configuração de Interrupções (IM 1) ---
    im 1                   ; Define o modo de interrupção 1
    ei                     ; Habilita interrupções

    ; --- Cópia do Bloco de Código da ROM para a RAM ---
    ld hl, programa_principal
    ld de, 8000h
    ld bc, fim_programa - programa_principal
    ldir

    ; --- Salta para o Código Copiado na RAM ---
    jp 8000h

; =================================================================================
; Bloco de código copiado para a RAM
; =================================================================================
programa_principal:
loop_ram:
    ; 1. Lê o switch da Porta B

    in a, (portb)
    and 07h                ; Máscara: 3 bits (00h-07h)

    ; 2. Escolhe o efeito
    cp 00h
    jr z, efeito_pisca
    cp 01h
    jr z, efeito_barra
    cp 02h
    jr z, efeito_corrida_dir
    cp 03h
    jr z, efeito_tudo_aceso
    cp 04h
    jr z, efeito_corrida_esq
    jr efeito_tudo_aceso   ; Padrão para 05h-07h

; ---------------------------------------------------------------------------------
; Efeito 0: Pisca LEDs (Alterna entre 55h e AAh)
; ---------------------------------------------------------------------------------
efeito_pisca:
    ld a, 055h
    out (porta), a
    call delay_curto
    ld a, 0AAh
    out (porta), a
    call delay_curto
    jr loop_ram

; ---------------------------------------------------------------------------------
; Efeito 1: Barra (Alterna entre F0h e 0Fh)
; ---------------------------------------------------------------------------------
efeito_barra:
    ld a, 0F0h
    out (porta), a
    call delay_curto
    ld a, 0Fh
    out (porta), a
    call delay_curto
    jr loop_ram

; ---------------------------------------------------------------------------------
; Efeito 2: Corrida Esquerda -> Direita (Usa D como contador)
; ---------------------------------------------------------------------------------
efeito_corrida_dir:
    ld d, 8
    ld a, 01h
corrida_dir_loop:
    out (porta), a
    call delay_curto
    rlca
    dec d
    jr nz, corrida_dir_loop
    jr loop_ram

; ---------------------------------------------------------------------------------
; Efeito 3: Tudo Aceso / Tudo Apagado (FFh / 00h)
; ---------------------------------------------------------------------------------
efeito_tudo_aceso:
    ld a, 0FFh             ; Acende todos os LEDs
    out (porta), a
    call delay_curto
    xor a                  ; Zera A (00h) - apaga todos os LEDs
    out (porta), a
    call delay_curto
    jr loop_ram

; ---------------------------------------------------------------------------------
; Efeito 4: Corrida Direita -> Esquerda (Usa D como contador)
; ---------------------------------------------------------------------------------
efeito_corrida_esq:
    ld d, 8
    ld a, 80h
corrida_esq_loop:
    out (porta), a
    call delay_curto
    rrca
    dec d
    jr nz, corrida_esq_loop
    jr loop_ram

; =================================================================================
; SUB-ROTINA: delay_curto (Preserva AF e BC)
; =================================================================================
delay_curto:
    push af
    push bc
    ld bc, 0001h
delay_loop:
    dec bc
    ld a, b
    or c
    jr nz, delay_loop
    pop bc
    pop af
    ret

fim_programa:

    end
'oshonsoft_bookmarks_and_breakpoints_info:,201,291
