
# 🧪 Exemplos com PPI 8255 e USART 8250A — Z80-PIC

Exemplos de código do Z80 e comunicação serial testadas em hardware
com **duas PPIs 8255** (portas de I/O) e **USART 8250A** (comunicação serial),
utilizando o barramento completo do Z80.

## 🎯 Objetivo

Demonstrar o funcionamento das instruções do Z80 que dependem de
portas de I/O complexas e comunicação serial, incluindo o mapeamento
de registradores internos dos periféricos e o polling de status.

## 💾 Mapa de Memória Principal

| Componente | Endereço | Tamanho | Descrição |
|------------|----------|---------|-----------|
| **ROM** | `0000h` - `7FFFh` | 32 KB | Programa e vetores (firmware) |
| **RAM** | `8000h` - `FFFFh` | 32 KB | Dados, pilha e variáveis |

## 🔌 Mapeamento de I/O

### PPI 1 (8255)

| Dispositivo | Endereço | Direção / Função |
|-------------|----------|------------------|
| Porta A | `00h` | SAÍDA / ENTRADA |
| Porta B | `01h` | SAÍDA / ENTRADA |
| Porta C | `02h` | SAÍDA / ENTRADA |
| Configuração | `03h` | Escrita (Registro de Controle) |

### PPI 2 (8255)

| Dispositivo | Endereço | Direção / Função |
|-------------|----------|------------------|
| Porta A | `08h` | SAÍDA / ENTRADA |
| Porta B | `09h` | SAÍDA / ENTRADA |
| Porta C | `0Ah` | SAÍDA / ENTRADA |
| Configuração | `0Bh` | Escrita (Registro de Controle) |

### USART 8250A

*(Endereços conforme descrição no hardware: tipicamente a partir de `10h`)*

| Dispositivo | Endereço | Direção / Função |
|-------------|----------|------------------|
| THR / RBR / DLL | `10h` | Transmissão / Recepção / Divisor LSB |
| IER / DLM | `11h` | Habilitação de Interrupção / Divisor MSB |
| IIR / FCR | `12h` | Identificação de Interrupção / Controle FIFO |
| LCR | `13h` | Controle de Linha (formato, paridade) |
| MCR | `14h` | Controle de Modem |
| LSR | `15h` | Status da Linha (pronto para TX/RX) |
| MSR | `16h` | Status do Modem |

**Hardware**: Duas PPIs 8255, uma USART 8250A e lógica de decodificação
conectadas ao barramento do Z80.
