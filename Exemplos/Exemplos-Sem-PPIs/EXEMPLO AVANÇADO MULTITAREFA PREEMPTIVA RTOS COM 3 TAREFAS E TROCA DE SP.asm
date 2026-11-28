; =================================================================================
; EXEMPLO AVANÇADO: MULTITAREFA PREEMPTIVA (RTOS) COM 3 TAREFAS E TROCA DE SP
; Autor: Marcos Roberto Braga
; Aluno: Pedro Henrique Cerqueira Braga
;
; OBJETIVO:
;   Demonstrar a essência de um Sistema Operacional (RTOS): a troca de contexto.
;   O programa roda 3 tarefas independentes. A cada pulso no pino INT (IM 1),
;   uma interrupção pausa a tarefa atual, salva o estado dela e passa o controle
;   para a próxima tarefa (Escalonamento Round-Robin).
;
; TAREFAS:
;   - Tarefa 0: Conta de 0 a 255 na Porta A (01h)
;   - Tarefa 1: Conta de 255 a 0 na Porta C (10h)
;   - Tarefa 2: Corrida de LEDs na Porta E (20h)
;
; MAPA DE I/O:
;   Porta A (01h) = Saída (LEDs)
;   Porta C (10h) = Saída (LEDs)
;   Porta E (20h) = Saída (LEDs)
;
; CONCEITOS ABORDADOS:
;   - Task Control Block (TCB): Variáveis na RAM que salvam o estado das tarefas.
;   - Context Switch: A arte de salvar e restaurar registradores e SP.
;   - Thread Safety: Pilhas independentes para cada tarefa.
; =================================================================================
; ---------------------------------------------------------------------------------
; Definições de portas e variáveis (TCB - Task Control Block)
; ---------------------------------------------------------------------------------
porta       = 01h      ; Porta A - Saída
portc       = 10h      ; Porta C - Saída
porte       = 20h      ; Porta E - Saída

sp_task0    = 8000h    ; Endereço na RAM que guarda o Stack Pointer da Tarefa 0
sp_task1    = 8002h    ; Endereço na RAM que guarda o Stack Pointer da Tarefa 1
sp_task2    = 8004h    ; Endereço na RAM que guarda o Stack Pointer da Tarefa 2
current_task = 8006h   ; Contador global: Indica qual tarefa está ativa (0, 1 ou 2)

; ==================================================================================
; --- Vetor de RESET ---
; ==================================================================================
    org 0000h
    jp init

; ==================================================================================
; --- VETOR INT (IM 1): O ESCALONADOR (SCHEDULER) ---
; Este código roda a cada pulso no pino INT.
; ==================================================================================
    org 0038h
int_handler:
    ; 1. SALVA O CONTEXTO DA TAREFA ATUAL
    ; Empilha todos os registradores que o Z80 possui no topo da pilha da tarefa atual.
    ; Isso preserva o estado exato da tarefa (variáveis, flags, ponteiros).
    push af
    push bc
    push de
    push hl
    push ix
    push iy
    ; Neste ponto, o SP aponta para o topo do contexto salvo da tarefa atual.

    ; 2. ATUALIZA O TCB (TASK CONTROL BLOCK)
    ; Descobre qual tarefa estava rodando e salva o SP dela na RAM.
    ld a, (current_task)
    cp 0
    jr z, save_t0      ; Se era a Tarefa 0, salva em sp_task0
    cp 1
    jr z, save_t1      ; Se era a Tarefa 1, salva em sp_task1
    ; Se chegou até aqui, a Tarefa 2 estava rodando. Salva e pula para o escalonador.
    ld (sp_task2), sp
    jr next_task
save_t1:
    ld (sp_task1), sp
    jr next_task
save_t0:
    ld (sp_task0), sp

; ---------------------------------------------------------------------------------
next_task:
    ; 3. ESCALONADOR ROUND-ROBIN
    ; Incrementa o ID da tarefa. Se chegar a 3, volta para 0.
    ld a, (current_task)
    inc a
    cp 3
    jr c, set_task     ; Se A < 3, pula para salvar
    xor a              ; Se A == 3, zera (Round-Robin)
set_task:
    ld (current_task), a

    ; 4. CARREGA O SP DA PRÓXIMA TAREFA
    ; Agora que sabemos qual é a próxima tarefa, carregamos o SP dela.
    cp 0
    jr z, load_t0
    cp 1
    jr z, load_t1
    ld sp, (sp_task2)  ; Carrega o SP da Tarefa 2
    jr restore
load_t1:
    ld sp, (sp_task1)
    jr restore
load_t0:
    ld sp, (sp_task0)

; ---------------------------------------------------------------------------------
restore:
    ; 5. RESTAURA O CONTEXTO DA NOVA TAREFA
    ; Desempilha os registradores da nova tarefa.
    ; A ordem do POP deve ser exatamente o inverso do PUSH para não bagunçar os dados!
    pop iy
    pop ix
    pop hl
    pop de
    pop bc
    pop af

    ; 6. PREPARA O RETORNO
    ; O EI tem um delay de 1 instrução. Como o RETI vem logo abaixo,
    ; a CPU não será interrompida no meio, mas o IFF1 será setado para 1.
    ; Isso é ESSENCIAL para que a próxima INT seja atendida!
    ei
    reti           ; Retorna da interrupção e retoma a execução no PC da nova tarefa

; ==================================================================================
; --- PROGRAMA PRINCIPAL (INICIALIZAÇÃO DO SISTEMA) ---
; ==================================================================================
    org 0100h
init:
    ld sp, 0FFFFh      ; Inicializa a pilha principal (que não será usada pelas tarefas)
    im 1               ; Configura a interrupção INT no modo IM 1 (vetor 0038h)

    ; Zera a tarefa atual (começaremos pela Tarefa 0)
    xor a
    ld (current_task), a

    ; -----------------------------------------------------------------------------
    ; PREPARAÇÃO DA PILHA DA TAREFA 0
    ; -----------------------------------------------------------------------------
    ; Para o Z80 "iniciar" uma tarefa via RET, precisamos criar uma falsa
    ; pilha que pareça que a tarefa foi interrompida e está prestes a retornar.
    ld sp, 8200h       ; Define uma área segura na RAM para a pilha da Tarefa 0
    ld hl, tarefa0     ; Carrega o endereço inicial da rotina da Tarefa 0
    push hl            ; Empilha o PC de retorno (o RET vai pular para 'tarefa0')

    ; Empilha valores dummy (0) para simular os registradores salvos.
    ; O 'pop' no restore espera 6 pares (12 bytes).
    ld hl, 0000h
    push hl            ; AF
    push hl            ; BC
    push hl            ; DE
    push hl            ; HL
    push hl            ; IX
    push hl            ; IY
    ld (sp_task0), sp  ; Salva o SP resultante em sp_task0 (RAM)

    ; -----------------------------------------------------------------------------
    ; PREPARAÇÃO DA PILHA DA TAREFA 1
    ; -----------------------------------------------------------------------------
    ld sp, 8300h       ; Área diferente na RAM para a Tarefa 1
    ld hl, tarefa1
    push hl
    ld hl, 0000h
    push hl
    push hl
    push hl
    push hl
    push hl
    push hl
    ld (sp_task1), sp

    ; -----------------------------------------------------------------------------
    ; PREPARAÇÃO DA PILHA DA TAREFA 2
    ; -----------------------------------------------------------------------------
    ld sp, 8400h       ; Área diferente na RAM para a Tarefa 2
    ld hl, tarefa2
    push hl
    ld hl, 0000h
    push hl
    push hl
    push hl
    push hl
    push hl
    push hl
    ld (sp_task2), sp

    ; -----------------------------------------------------------------------------
    ; INICIA A PRIMEIRA TAREFA (TAREFA 0)
    ; -----------------------------------------------------------------------------
    ei                 ; Habilita interrupções globais (necessário para o INT)
    ld sp, (sp_task0)  ; Carrega o SP preparado para a Tarefa 0
    pop iy             ; Desempilha todos os registradores dummy
    pop ix
    pop hl
    pop de
    pop bc
    pop af
    ret                ; O RET puxa o PC empilhado (tarefa0) e a inicia!

; ==================================================================================
; --- ROTINAS DAS TAREFAS ---
; ==================================================================================

; ---------------------------------------------------------------------------------
; TAREFA 0: Contador na Porta A
; ---------------------------------------------------------------------------------
tarefa0:
    ld a, 0            ; Começa com o valor 0
loop_t0:
    out (porta), a     ; Envia o valor de A para a Porta A
    inc a              ; Incrementa A
    call delay         ; Chama o delay (preserva o A)
    jr loop_t0         ; Loop infinito

; ---------------------------------------------------------------------------------
; TAREFA 1: Contador Decrescente na Porta C
; ---------------------------------------------------------------------------------
tarefa1:
    ld a, 0FFh         ; Começa com o valor 255
loop_t1:
    out (portc), a     ; Envia o valor de A para a Porta C
    dec a              ; Decrementa A
    call delay
    jr loop_t1

; ---------------------------------------------------------------------------------
; TAREFA 2: Corrida de LEDs na Porta E
; ---------------------------------------------------------------------------------
tarefa2:
    ld a, 01h          ; Começa com o LED 0 aceso
loop_t2:
    out (porte), a     ; Envia o padrão para a Porta E
    rlca               ; Rotaciona A para a esquerda (próximo LED)
    call delay
    jr loop_t2

; ==================================================================================
; --- SUB-ROTINA: DELAY ---
; ==================================================================================
delay:
    push af            ; Salva A e Flags (A será usado no loop)
    push bc            ; Salva BC (o loop usa BC)
    ld bc, 0001h       ; Ajuste o valor de BC para mudar a velocidade (aumente para mais lento)
delay_loop:
    dec bc             ; Decrementa o contador de 16 bits
    ld a, b            ; Move a parte alta para A
    or c               ; OR com a parte baixa
    jr nz, delay_loop  ; Se não for zero, continua o loop
    pop bc             ; Restaura o BC original
    pop af             ; Restaura o A original (e as flags)
    ret

.end