; =================================================================================
; PROVA DE FOGO DEFINITIVA: INT e NMI no MEIO de um LDIR
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique Cerqueira Braga
;
; OBJETIVO:
;   Provar que o Timer0 (hardware real) consegue interromper o Z80 durante
;   um LDIR, executar os handlers de INT (0x0038) e NMI (0x0066), e RETORNAR
;   para continuar a cópia de onde parou.
;
; ARQUITETURA DE HARDWARE (NOVA):
;   - Os sinais de INT (Z80, RE3) e NMI (Z80, RE4) são combinados por uma
;     porta AND (74LS08).
;   - A saída da AND vai para o pino RA4 do PIC (entrada do Timer0).
;   - Quando qualquer interrupção é acionada, o Timer0 estoura e gera uma
;     interrupção REAL no PIC.
;   - A ISR do Timer0 lê os pinos originais (RE3 = INT, RE4 = NMI) para
;     identificar qual fonte disparou.
;
; COMO FUNCIONA:
;   1. O programa copia 200 bytes da ROM para a RAM com LDIR.
;   2. Enquanto o LDIR está rodando, você aperta:
;      - o botão de INT (RE3) → Porta C pisca BBh
;      - o botão de NMI (RE4) → Porta C pisca AAh
;   3. Cada interrupção é atendida pelo vetor correto (0x0038 ou 0x0066).
;   4. O RETI/RETN restaura o PC → o Z80 retoma o LDIR de onde parou.
;   5. Ao final, a Porta A mostra 11h (primeiro byte) e a Porta C mostra 99h
;      (último byte) - prova que a cópia terminou 100% correta, independente
;      de quantas interrupções foram atendidas.
;
; RESULTADO ESPERADO (após apertar INT e/ou NMI no meio do LDIR):
;   - Durante a cópia:
;       INT (RE3) → Porta C = BBh (pisca)
;       NMI (RE4) → Porta C = AAh (pisca)
;   - Após o LDIR terminar: Porta A = 11h, Porta C = 99h
;     (o 99h sobrescreve o último valor de teste, provando que a cópia
;      continuou e terminou corretamente)
; =================================================================================

porta   = 01h              ; Porta A (SAÍDA) — Primeiro byte copiado
portc   = 10h              ; Porta C (SAÍDA) — Último byte / Valor de teste das interrupções

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
; Vetor de NMI — endereço fixo 0x0066
; =================================================================================
    org 0066h
    push af                ; Salva A e F
    ld a, 0AAh             ; Valor de teste (AAh = NMI)
    out (portc), a         ; Porta C = AAh (acende o LED, prova que a NMI foi atendida)
    pop af                 ; Restaura A e F
    retn                   ; Retorna da NMI (restaura PC e IFF1 = IFF2)

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
    out (portc), a         ; Porta C = 99h (sobrescreve o valor de teste!)

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