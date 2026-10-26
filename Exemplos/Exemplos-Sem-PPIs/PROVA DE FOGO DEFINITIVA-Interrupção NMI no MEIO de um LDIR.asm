; =================================================================================
; PROVA DE FOGO DEFINITIVA: Interrupção NMI no MEIO de um LDIR
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique Cerqueira Braga
;
; OBJETIVO:
;   Provar que o Timer0 (hardware real) consegue interromper o Z80 durante
;   um LDIR (instrução de bloco), executar o handler da NMI, e RETORNAR
;   para continuar a cópia de onde parou.
;
; COMO FUNCIONA:
;   1. O programa copia 200 bytes da ROM para a RAM com LDIR.
;   2. Enquanto o LDIR está rodando (leva alguns ms), você aperta o botão
;      de NMI (pino RA4 do PIC).
;   3. O Timer0 do PIC estoura → chama timer0_isr() → seta hardware_nmi_pending.
;   4. O emulador vê a flag no ldir() e quebra o loop do LDIR.
;   5. O handle_nmi() empilha o PC e salta para 0x0066.
;   6. O handler da NMI escreve 0xAA na Porta C e executa RETN.
;   7. O RETN restaura o PC → o Z80 retoma o LDIR de onde parou.
;   8. Ao final, a Porta A mostra 11h (primeiro byte) e a Porta C mostra 99h
;      (último byte) - prova que a cópia terminou 100% correta.
;
; RESULTADO ESPERADO (após apertar NMI no meio do LDIR):
;   - Durante a cópia: Porta C pisca AAh (NMI atendida!)
;   - Após o LDIR terminar: Porta A = 11h, Porta C = 99h
;     (o 99h sobrescreve o AAh, provando que a cópia continuou e terminou)
; =================================================================================

porta   = 01h              ; Porta A (SAÍDA) — Primeiro byte copiado
portc   = 10h              ; Porta C (SAÍDA) — Último byte / Valor de teste da NMI

    org 0000h              ; Vetor de RESET
    jp inicio

    org 0066h              ; Vetor de NMI
    push af                ; Salva A e F
    ld a, 0AAh             ; Valor de teste
    out (portc), a         ; Porta C = AAh (acende o LED, prova que a NMI foi atendida)
    pop af                 ; Restaura A e F
    retn                   ; Retorna para o meio do LDIR

    org 0100h              ; Programa principal
inicio:
    ld sp, 0FFFFh          ; SP = topo da RAM (pilha segura)

    ; --- Prepara LDIR de 200 bytes (ROM -> RAM) ---
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
    out (portc), a         ; Porta C = 99h (sobrescreve o AAh da NMI!)

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