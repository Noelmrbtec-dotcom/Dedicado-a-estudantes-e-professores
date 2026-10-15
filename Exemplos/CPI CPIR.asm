; =================================================================================
; Entendendo funcionamento de processadores (Z80) Zilog
; Autor: Marcos Roberto Braga
; Data: 15/10/2025
; Aluno: Pedro Henrique Cerqueira Braga
;
; TESTE: CPI e CPIR — Comparação crescente com decremento de BC
;
; OBJETIVO:
;   Demonstrar o uso das instruções CPI e CPIR do Z80, que comparam
;   o acumulador A com o byte apontado por HL, INCREMENTAM HL e
;   DECREMENTAM BC.
;
;   Este exemplo ensina, na prática:
;     - CPI  (ED A1h) — compara e incrementa (uma vez)
;     - CPIR (ED B1h) — repete CPI até encontrar ou esgotar BC
;     - Diferença entre CPI (uma vez) e CPIR (busca completa)
;     - Efeito nas flags (Z quando encontra)
;
; FLUXO:
;   1. Configura a PPI1 (A=out, B=in, C=out)
;   2. TESTE 1: CPI isolada — compara A=33h com o 1º byte (11h)
;   3. TESTE 2: CPIR — busca 33h no bloco inteiro
;   4. Exibe o resultado nas Portas A e C
;   5. Para (loop infinito) para inspeção
;
; MAPA DE MEMÓRIA:
;   ROM: 0000h – 7FFFh  (código + bloco de dados)
;   RAM: 8000h – FFFFh  (variáveis + pilha)
;
; HARDWARE:
;   PPI1: porta      = 00h (Porta A — SAÍDA, LEDs)
;         portb      = 01h (Porta B — ENTRADA, chaves)
;         portc      = 02h (Porta C — SAÍDA, LEDs)
;         ppi_confg1 = 03h (Controle)
;
; CONFIGURAÇÃO DO PPI1:
;   Byte de controle: 1000 0010b = 82h  (A=out, B=in, C=out)
;
; RESULTADO ESPERADO:
;   TESTE 1 (CPI isolada):
;     A  = 33h
;     HL = 0101h (aponta para 22h)
;     BC = 0007h
;     Z  = 0 (não encontrou — 11h ≠ 33h)
;
;   TESTE 2 (CPIR — busca crescente):
;     A  = 33h
;     HL = 0103h (aponta para 44h — APÓS o 33h)
;     BC = 0005h
;     Z  = 1 (encontrou 33h em DADOS+2)
; =================================================================================

; =================================================================================
; MAPEAMENTO DE I/O — PPI 1 (8255)
; =================================================================================
porta      = 00h    ; Porta A do PPI1 (SAÍDA — LEDs)
portb      = 01h    ; Porta B do PPI1 (ENTRADA — chaves)
portc      = 02h    ; Porta C do PPI1 (SAÍDA — LEDs)
ppi_confg1 = 03h    ; Registrador de controle do PPI1

; =================================================================================
; --- Vetor de RESET ---
; =================================================================================
    org 0000h
    jp inicio

; =================================================================================
; --- Programa Principal ---
; =================================================================================
    org 0030h

inicio:
    ld sp, 0FFFFh             ; Stack Pointer no topo da RAM

    ; ******************************************************************
    ; 1. CONFIGURAÇÃO DA PPI1
    ;    Porta A = SAÍDA, Porta B = ENTRADA, Porta C = SAÍDA
    ;    Byte de controle: 82h
    ; ******************************************************************
    ld a, 82h
    out (ppi_confg1), a

    ; ******************************************************************
    ; 2. TESTE 1 — CPI ISOLADA
    ; ******************************************************************
    ; Executa UMA CPI, comparando A=33h com o 1º byte do bloco (11h).
    ;
    ; Após a CPI:
    ;   A  = 33h (não muda)
    ;   HL = 0101h (incrementado de 0100h)
    ;   BC = 0007h (decrementado de 0008h)
    ;   Z  = 0 (11h ≠ 33h)
    ; ******************************************************************
    ld a, 33h                 ; A = byte procurado
    ld hl, DADOS              ; HL = início do bloco (0100h)
    ld bc, 0008h              ; BC = 8 bytes

    cpi                       ; Uma única comparação com incremento

    ; ******************************************************************
    ; 3. TESTE 2 — CPIR (BUSCA CRESCENTE COMPLETA)
    ; ******************************************************************
    ; Configura HL e BC novamente para a busca completa.
    ; A CPIR varre o bloco até encontrar 33h (em DADOS+2 = 0102h).
    ;
    ; Após a CPIR:
    ;   A  = 33h (não muda)
    ;   HL = 0103h (aponta para 44h — APÓS o 33h)
    ;   BC = 0005h
    ;   Z  = 1 (encontrou)
    ; ******************************************************************
    ld a, 33h                 ; A = byte procurado (reconfirma)
    ld hl, DADOS              ; HL = início do bloco (recomeça)
    ld bc, 0008h              ; BC = 8 bytes (recomeça)

    cpir                      ; Busca crescente completa

    ; ******************************************************************
    ; 4. EXIBE O ESTADO FINAL DE HL NAS PORTAS A E C
    ; ******************************************************************
    ; Porta A = H (parte alta de HL)
    ; Porta C = L (parte baixa de HL)
    ; ******************************************************************
    ld a, h
    out (porta), a            ; Porta A = H

    ld a, l
    out (portc), a            ; Porta C = L

    ; ******************************************************************
    ; 5. FIM — loop infinito para inspeção
    ; ******************************************************************
fim:
    jp fim

; =================================================================================
; BLOCO DE DADOS NA ROM
; =================================================================================
; Bloco de 8 bytes para ser varrido pela CPI/CPIR.
;
; A CPI/CPIR varre do início para o fim:
;   DADOS+0 = 11h (≠ 33h)
;   DADOS+1 = 22h (≠ 33h)
;   DADOS+2 = 33h (É! Encontrou!)
; =================================================================================
    org 0100h

DADOS:
    db 11h, 22h, 33h, 44h, 55h, 66h, 77h, 88h

; =================================================================================
.end
;**************************Fim******************************************************