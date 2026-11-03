
# 🧪 Exemplos sem PPI — Z80-PIC

Exemplos de instruções do Z80 testadas em hardware **sem PPI 8255**,
usando latches discretos para as portas de entrada e saída.

## 🎯 Objetivo

Demonstrar o funcionamento das instruções do Z80 que dependem de
portas de I/O, sem a limitação do modelo da PPI 8255 em simuladores.

## 💾 Mapa de Memória Principal

| Componente | Endereço | Tamanho | Descrição |
|------------|----------|---------|-----------|
| **ROM** | `0000h` - `7FFFh` | 32 KB | Programa e vetores (firmware) |
| **RAM** | `8000h` - `FFFFh` | 32 KB | Dados, pilha e variáveis |


## 🔌 Mapeamento de I/O

| Porta | Endereço | Direção |
|-------|----------|---------|
| Porta A | `01h` | SAÍDA |
| Porta B | `02h` | ENTRADA |
| Porta C | `10h` | SAÍDA |

**Hardware**: portas discretas com latches (74LS273, 74LS373, 74LS374) ou
buffers tri-state (74LS244, 74LS245).

