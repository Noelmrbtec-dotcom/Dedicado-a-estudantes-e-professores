# Hardware — Z80-PIC (com PPI e USART 8250A)

Esta pasta contém os arquivos de hardware do emulador **Z80-PIC** 
com interface **PPI 8255** e **USART 8250A**: os esquemas do Proteus 
e os binários do PIC18F6722.

---

## 📂 Conteúdo

| Arquivo | Descrição | Binário Compatível |
|---------|-----------|-------------------|
| `Z80-PIC18F-EMU-MAPEADO-POR-MREQ+ROM-PPI-USART-8250A-NMI-INT-HARDWARE.DSN` | **Esquema NOVO** — INT e NMI por hardware real (porta AND + Timer0 no pino RA4) | `main-rom.hex` |
| `Z80-PIC18F-EMU-MAPEADO-POR-MREQ+ROM-PPI-USART-8250A.DSN` | Esquema ANTIGO — NMI por polling (pino RE4) | `old-main-rom.hex` |
| `main-rom.hex` | **Binário ATUALIZADO** — INT e NMI por hardware real (porta AND + Timer0 no RA4). Interrompe instruções de bloco (LDIR, CPIR, OTIR, etc.) | `...NMI-INT-HARDWARE.DSN` |
| `old-main-rom.hex` | Binário ANTIGO (legado) — NMI por polling de software no pino **RE4** | `...8250A.DSN` |

---

## ⚠️ Correspondência Obrigatória Esquema ↔ Binário

Para o emulador funcionar corretamente, **use o binário com o esquema correspondente**:

| Se você quer usar... | Carregue o binário... | No esquema... |
|----------------------|----------------------|---------------|
| **INT e NMI por Hardware Real** (novo) | `main-rom.hex` | `Z80-PIC18F-EMU-MAPEADO-POR-MREQ+ROM-PPI-USART-8250A-NMI-INT-HARDWARE.DSN` |
| **NMI por Polling** (antigo) | `old-main-rom.hex` | `Z80-PIC18F-EMU-MAPEADO-POR-MREQ+ROM-PPI-USART-8250A.DSN` |

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

## 🔌 Mapeamento de I/O (PPI 8255 e USART 8250A)

| Dispositivo | Endereço Base | Descrição |
|-------------|--------------|-----------|
| **PPI 8255** | `00h – 03h` | Portas A, B, C e Controle |
| **USART 8250A** | `A definir` | Comunicação Serial (RS-232) |

*(Os endereços específicos estão documentados no esquema do Proteus.)*

## 🔧 Pinagem das Interrupções

| Esquema | Pino do PIC | Tipo de Interrupção |
|---------|-------------|---------------------|
| `...NMI-INT-HARDWARE.DSN` (novo) | **RA4** (Timer0) | Hardware real (porta AND + Timer0 como contador externo) |
| `...8250A.DSN` (antigo) | **RE4** | Polling de software no `main()` |

### Lógica da Porta AND (Esquema Novo)

```text
INT (Z80, RE3) ──┐
                 ├── 74LS08 (AND) ──→ RA4 (Timer0)
NMI (Z80, RE4) ──┘
