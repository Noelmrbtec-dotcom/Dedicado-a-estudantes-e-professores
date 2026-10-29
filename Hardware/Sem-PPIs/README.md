# 🔌 Hardware de Simulação — Sem PPI

Esquema do hardware simulado no Proteus para testar as instruções
do Z80-EMU **sem PPI 8255**, usando portas discretas com latches.

## 🎯 Objetivo

Demonstrar um hardware mínimo que mantém o dado **estável** entre
leituras consecutivas, permitindo testar corretamente as instruções
da família INM (`IND`, `INDR`, `INI`, `INIR`) e as instruções de
interrupção (INT e NMI).

## 📂 Conteúdo

| Arquivo | Descrição | Binário Compatível |
|---------|-----------|-------------------|
| `Z80-PIC18F-EMU-MAPEADO-POR-MREQ+ROM-M2-VETORES-NMI-INT-HARDWARE.DSN` | **Esquema NOVO** — INT e NMI por hardware real (porta AND + Timer0 no pino RA4) | `main-rom.hex` |
| `Z80-PIC18F-EMU-MAPEADO-POR-MREQ+ROM-M2-VETORES.DSN` | Esquema ANTIGO — NMI por polling (pino RE4) | `old-main-rom.hex` |
| `main-rom.hex` | **Binário ATUALIZADO** — INT e NMI por hardware real (porta AND + Timer0 no RA4). Interrompe instruções de bloco (LDIR, CPIR, OTIR, etc.) | `...NMI-INT-HARDWARE.DSN` |
| `old-main-rom.hex` | Binário ANTIGO (legado) — NMI por polling de software no pino **RE4** | `...VETORES.DSN` |

---

## ⚠️ Correspondência Obrigatória Esquema ↔ Binário

Para o emulador funcionar corretamente, **use o binário com o esquema correspondente**:

| Se você quer usar... | Carregue o binário... | No esquema... |
|----------------------|----------------------|---------------|
| **INT e NMI por Hardware Real** (novo) | `main-rom.hex` | `Z80-PIC18F-EMU-MAPEADO-POR-MREQ+ROM-M2-VETORES-NMI-INT-HARDWARE.DSN` |
| **NMI por Polling** (antigo) | `old-main-rom.hex` | `Z80-PIC18F-EMU-MAPEADO-POR-MREQ+ROM-M2-VETORES.DSN` |

**Misturar esquema novo com binário antigo (ou vice-versa) NÃO funciona**, porque a pinagem das interrupções é fisicamente diferente:

- **Esquema novo:** INT (RE3) e NMI (RE4) são combinadas por uma porta AND (74LS08) e a saída vai para o **RA4** (Timer0).
- **Esquema antigo:** NMI conectado diretamente ao **RE4** (polling).

Se você carregar o `old-main-rom.hex` no esquema novo, o botão de NMI estará no pino errado, e a interrupção **nunca será detectada**.

---

## 🆕 O que mudou no novo binário (`main-rom.hex`)

- **INT e NMI por Hardware Real:** Os sinais de INT (RE3) e NMI (RE4) são combinados por uma porta AND (74LS08), e a saída vai para o pino **RA4** (Timer0). Quando qualquer uma das interrupções é acionada, o Timer0 gera uma interrupção real no PIC.
- **Identificação da Fonte:** A ISR do Timer0 lê os pinos originais (RE3 e RE4) para identificar qual interrupção disparou.
- **Interrupção em Blocos:** As 8 instruções de bloco (`LDIR`, `LDDR`, `CPIR`, `CPDR`, `INIR`, `INDR`, `OTIR`, `OTDR`) foram validadas com INT e NMI reais durante a execução.
- **Retomada de Contexto:** Após o `RETI`/`RETN`, o Z80 retoma a instrução de bloco exatamente de onde parou, sem perder o contador `BC` ou os ponteiros `HL`/`DE`.

## 📜 Sobre o binário antigo (`old-main-rom.hex`)

Este binário é mantido **apenas para referência histórica**. Nele, a NMI é detectada por **polling de software** no loop principal, então:
- A interrupção **não** é atendida durante instruções de bloco.
- O botão precisa ser pressionado por mais tempo (mais de 1 segundo) para ser detectado.

**Para novos testes e desenvolvimento, use sempre o `main-rom.hex` com o esquema `...NMI-INT-HARDWARE.DSN`.**

---

## 🔌 Mapeamento de I/O

| Porta | Endereço | Direção | Função |
|-------|----------|---------|--------|
| Porta A | `01h` | SAÍDA | LEDs |
| Porta B | `02h` | ENTRADA | Chaves / latch |
| Porta C | `10h` | SAÍDA | LEDs |

## 🔧 Pinagem das Interrupções

| Esquema | Pino do PIC | Tipo de Interrupção |
|---------|-------------|---------------------|
| `...NMI-INT-HARDWARE.DSN` (novo) | **RA4** (Timer0) | Hardware real (porta AND + Timer0 como contador externo) |
| `...VETORES.DSN` (antigo) | **RE4** | Polling de software no `main()` |

### Lógica da Porta AND (Esquema Novo)

```text
INT (Z80, RE3) ──┐
                 ├── 74LS08 (AND) ──→ RA4 (Timer0)
NMI (Z80, RE4) ──┘
