; =================================================================================
; Entendendo funcionamento de processadores (Z80) Zilog
; Autor: Marcos Roberto Braga
; Data: 15/10/2025
; Aluno: Pedro Henrique Cerqueira Braga
;
; TESTE DA INSTRUÇÃO: CPDR (ED B9h) — Compara, Decrementa e Repete
;
; OBJETIVO:
;   Demonstrar o uso da instrução CPDR do Z80, que repete CPD até
;   encontrar o byte procurado (Z=1) ou esgotar BC.
;
; FLUXO:
;   1. Configura a PPI1 (A=out, B=in, C=out)
;   2. Procura o byte 33h no bloco DADOS (decrescente)
;   3. Escreve o estado final (HL) nas Portas A e C
;   4. Para (loop infinito) para inspeção
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
; RESULTADO ESPERADO:
;   DADOS contém: 11h, 22h, 33h, 44h, 55h, 66h, 77h, 88h
;   Procura por:  33h
;   CPDR varre: 88h, 77h, 66h, 55h, 44h, 33h (encontrou!)
;
;   Após a busca:
;     A  = 33h
;     HL = 0101h (aponta para 22h — anterior ao encontrado)
;     BC = 0002h
;     Z  = 1 (encontrou)
;
; Saída nas portas:
;   Porta A = H = 01h
;   Porta C = L = 01h
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
    ; ******************************************************************
    ld a, 82h
    out (ppi_confg1), a

    ; ******************************************************************
    ; 2. PREPARAÇÃO PARA A CPDR
    ; ******************************************************************
    ; Configura:
    ;   A  = 33h        (byte a procurar)
    ;   HL = DADOS + 7  (fim do bloco — CPDR varre decrescendo)
    ;   BC = 0008h      (8 bytes a varrer)
    ; ******************************************************************
    ld a, 33h                 ; A = byte a procurar
    ld hl, DADOS + 7          ; HL = fim do bloco
    ld bc, 0008h              ; BC = 8 bytes

    ; ******************************************************************
    ; 3. EXECUÇÃO DA CPDR
    ; ******************************************************************
    ; CPDR executa CPD repetidamente até:
    ;   - Encontrar 33h (Z = 1), OU
    ;   - Esgotar BC (BC = 0)
    ;
    ; Como 33h está em DADOS+2 (0102h), a CPDR vai parar após
    ; encontrar o byte na 6ª iteração.
    ; ******************************************************************
    cpdr

    ; ******************************************************************
    ; 4. EXIBE O ESTADO FINAL DE HL NAS PORTAS A E C
    ; ******************************************************************
    ld a, h
    out (porta), a            ; Porta A = H

    ld a, l
    out (portc), a            ; Porta C = L

    ; ******************************************************************
    ; 5. FIM
    ; ******************************************************************
fim:
    jp fim

; =================================================================================
; BLOCO DE DADOS NA ROM
; =================================================================================
    org 0100h

DADOS:
    db 11h, 22h, 33h, 44h, 55h, 66h, 77h, 88h

; =================================================================================
.end
;**************************Fim******************************************************