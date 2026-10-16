
# 🔌 Hardware de Simulação — Sem PPI

Esquema do hardware simulado no Proteus para testar as instruções
do Z80-EMU **sem PPI 8255**, usando portas discretas com latches.

## 🎯 Objetivo

Demonstrar um hardware mínimo que mantém o dado **estável** entre
leituras consecutivas, permitindo testar corretamente as instruções
da família INM (`IND`, `INDR`, `INI`, `INIR`).

## 🔌 Mapeamento de I/O

| Porta | Endereço | Direção | Função |
|-------|----------|---------|--------|
| Porta A | `01h` | SAÍDA | LEDs |
| Porta B | `02h` | ENTRADA | Chaves / latch |
| Porta C | `10h` | SAÍDA | LEDs |

## 🧩 Componentes Utilizados

- **Z80-EMU** (emulada no Proteus)
- **74LS373** — latch de 8 bits para a Porta B (entrada)
- **74LS244** — buffer tri-state para as Portas A e C (saída)
- **DIP switches** — entrada de dados para o latch
- **LEDs** — visualização das saídas
- **Decodificador de endereço** (74LS138 ou similar)


