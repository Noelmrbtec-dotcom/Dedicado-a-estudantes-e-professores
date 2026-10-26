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
| `Z80-PIC18F-EMU-MAPEADO-POR-MREQ+ROM-M2-VETORES-INT-HARDWARE.DSN` | **Esquema NOVO** — NMI por hardware real (Timer0 no pino RA4) | `main-rom.hex` |
| `Z80-PIC18F-EMU-MAPEADO-POR-MREQ+ROM-M2-VETORES.DSN` | Esquema ANTIGO — NMI por polling (pino RE4) | `old-main-rom.hex` |
| `main-rom.hex` | **Binário ATUALIZADO** — NMI por hardware real (Timer0 no pino RA4). Interrompe instruções de bloco (LDIR, CPIR, OTIR, etc.) | `...INT-HARDWARE.DSN` |
| `old-main-rom.hex` | Binário ANTIGO (legado) — NMI por polling de software no pino **RE4** | `...VETORES.DSN` |

---

## ⚠️ Correspondência Obrigatória Esquema ↔ Binário

Para o emulador funcionar corretamente, **use o binário com o esquema correspondente**:

| Se você quer usar... | Carregue o binário... | No esquema... |
|----------------------|----------------------|---------------|
| **NMI por Hardware Real** (novo) | `main-rom.hex` | `Z80-PIC18F-EMU-MAPEADO-POR-MREQ+ROM-M2-VETORES-INT-HARDWARE.DSN` |
| **NMI por Polling** (antigo) | `old-main-rom.hex` | `Z80-PIC18F-EMU-MAPEADO-POR-MREQ+ROM-M2-VETORES.DSN` |

**Misturar esquema novo com binário antigo (ou vice-versa) NÃO funciona**, porque o pino do NMI está fisicamente diferente:

- **Esquema novo:** NMI conectado ao **RA4** (Timer0).
- **Esquema antigo:** NMI conectado ao **RE4**.

Se você carregar o `old-main-rom.hex` no esquema novo, o botão de NMI estará no pino errado, e a interrupção **nunca será detectada**.

---

## 🆕 O que mudou no novo binário (`main-rom.hex`)

- **NMI por Hardware Real:** O Timer0 do PIC18F6722 foi configurado como contador externo no pino RA4. O botão de NMI agora gera uma interrupção real do PIC, que interrompe até loops de instruções de bloco do Z80.
- **Interrupção em Blocos:** As 8 instruções de bloco (`LDIR`, `LDDR`, `CPIR`, `CPDR`, `INIR`, `INDR`, `OTIR`, `OTDR`) foram validadas com NMI real durante a execução.
- **Retomada de Contexto:** Após o `RETN`, o Z80 retoma a instrução de bloco exatamente de onde parou, sem perder o contador `BC` ou os ponteiros `HL`/`DE`.

## 📜 Sobre o binário antigo (`old-main-rom.hex`)

Este binário é mantido **apenas para referência histórica**. Nele, a NMI é detectada por **polling de software** no loop principal, então:
- A interrupção **não** é atendida durante instruções de bloco.
- O botão precisa ser pressionado por mais tempo (mais de 1 segundo) para ser detectado.

**Para novos testes e desenvolvimento, use sempre o `main-rom.hex` com o esquema `...INT-HARDWARE.DSN`.**

---

## 🔌 Mapeamento de I/O

| Porta | Endereço | Direção | Função |
|-------|----------|---------|--------|
| Porta A | `01h` | SAÍDA | LEDs |
| Porta B | `02h` | ENTRADA | Chaves / latch |
| Porta C | `10h` | SAÍDA | LEDs |

## 🔧 Pinagem do NMI

| Esquema | Pino do PIC | Tipo de Interrupção |
|---------|-------------|---------------------|
| `...INT-HARDWARE.DSN` (novo) | **RA4** (Timer0) | Hardware real (Timer0 como contador externo) |
| `...VETORES.DSN` (antigo) | **RE4** | Polling de software no `main()` |

## 🧩 Componentes Utilizados

- **Z80-EMU** (emulada no Proteus)
- **74LS244** — latch de 8 bits para a Porta B (entrada)
- **74LS273** — buffer tri-state para as Portas A e C (saída)
- **DIP switches** — entrada de dados para o latch
- **LEDs** — visualização das saídas
- **Decodificador de endereço** (74LS138 ou similar)

## 📌 Recomendação

- **Para produção e novos testes:** use `main-rom.hex` + `...INT-HARDWARE.DSN`.
- **Para comparação histórica:** use `old-main-rom.hex` + `...VETORES.DSN`.

**Não misture os arquivos entre as duas configurações.**

