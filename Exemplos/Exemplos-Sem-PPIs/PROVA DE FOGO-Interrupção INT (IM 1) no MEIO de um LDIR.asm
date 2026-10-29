; =================================================================================
; PROVA DE FOGO DEFINITIVA: Interrupção INT (IM 1) no MEIO de um LDIR
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique Cerqueira Braga
;
; OBJETIVO:
;   Provar que o Timer0 (hardware real) consegue interromper o Z80 durante
;   um LDIR (instrução de bloco), executar o handler da INT mascarada (IM 1),
;   e RETORNAR para continuar a cópia de onde parou.
;
; ARQUITETURA DE HARDWARE (NOVA):
;   - Os sinais de INT (Z80) e NMI (Z80) são combinados por uma porta AND (74LS08).
;   - A saída da AND vai para o pino RA4 do PIC (entrada do Timer0).
;   - Quando qualquer interrupção é acionada, o Timer0 estoura e gera uma
;     interrupção REAL no PIC.
;   - A ISR do Timer0 lê os pinos originais (RE3 = INT, RE4 = NMI) para
;     identificar qual fonte disparou.
;
; COMO FUNCIONA:
;   1. O programa copia 200 bytes da ROM para a RAM com LDIR.
;   2. Enquanto o LDIR está rodando (leva alguns ms), você aperta o botão
;      de INT (pino RE3 do PIC).
;   3. O Timer0 do PIC estoura → chama timer0_isr() → lê RE3 (ativo) →
;      seta interrupt_pending.
;   4. O emulador vê a flag no ldir() e quebra o loop do LDIR.
;   5. O check_interrupts() vê interrupt_pending && IFF1 → chama handle_interrupt().
;   6. O handle_interrupt() empilha o PC e salta para 0x0038 (IM 1).
;   7. O handler da INT escreve 0xBB na Porta C e executa RETI.
;   8. O RETI restaura o PC → o Z80 retoma o LDIR de onde parou.
;   9. Ao final, a Porta A mostra 11h (primeiro byte) e a Porta C mostra 99h
;      (último byte) - prova que a cópia terminou 100% correta.
;
; RESULTADO ESPERADO (após apertar INT no meio do LDIR):
;   - Durante a cópia: Porta C pisca BBh (INT atendida!)
;   - Após o LDIR terminar: Porta A = 11h, Porta C = 99h
;     (o 99h sobrescreve o BBh, provando que a cópia continuou e terminou)
; =================================================================================

porta   = 01h              ; Porta A (SAÍDA) — Primeiro byte copiado
portc   = 10h              ; Porta C (SAÍDA) — Último byte / Valor de teste da INT

    org 0000h              ; Vetor de RESET
    jp inicio

; =================================================================================
; Vetor de INT (IM 1) — endereço fixo 0x0038
; =================================================================================
    org 0038h
    push af                ; Salva A e F
    ld a, 0BBh             ; Valor de teste (BBh = INT mascarada)
    out (portc), a         ; Porta C = BBh (acende o LED, prova que a INT foi atendida)
    pop af                 ; Restaura A e F
    ei                     ; Reabilita interrupções (IFF1 = IFF2 = 1)
    reti                   ; Retorna da interrupção (restaura PC e IFF1)

; =================================================================================
; Programa principal
; =================================================================================
    org 0100h
inicio:
    ld sp, 0FFFFh          ; SP = topo da RAM (pilha segura)
    im 1                   ; Configura modo de interrupção 1 (INT → 0x0038)
    ei                     ; Habilita interrupções (IFF1 = IFF2 = 1)

    ; --- Prepara LDIR de 200 bytes (ROM → RAM) ---
    ld hl, DADOS           ; HL = Origem (ROM)
    ld de, 8000h           ; DE = Destino (RAM)
    ld bc, 00C8h           ; BC = 200 bytes

    ; --- Executa LDIR (aqui o Timer0 pode interromper!) ---
    ldir

    ; --- Leitura do primeiro byte (prova que a cópia começou) ---
    ld a, (8000h)          ; A = RAM[8000h] = 11h
    out (porta), a         ; Porta A = 11h

    ; --- Leitura do último byte (prova que a cópia terminou) ---
    ld a, (80C7h)          ; A = RAM[80C7h] = 99h
    out (portc), a         ; Porta C = 99h (sobrescreve o BBh da INT!)

fim:
    jp fim                 ; Loop infinito para inspeção

; =================================================================================
; BLOCO DE DADOS NA ROM (200 bytes)
; =================================================================================
    org 0200h
DADOS:
    db 11h                 ; Byte 0 (primeiro)
    ds 198, 55h            ; 198 bytes de preenchimento
    db 99h                 ; Byte 199 (último)

    end