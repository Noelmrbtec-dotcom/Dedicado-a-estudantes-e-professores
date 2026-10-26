
# Hardware — Z80-PIC (com PPI e USART 8250A)

Esta pasta contém os arquivos de hardware do emulador **Z80-PIC** 
com interface **PPI 8255** e **USART 8250A**: os esquemas do Proteus 
e os binários do PIC18F6722.

---

## 📂 Conteúdo

| Arquivo | Descrição | Binário Compatível |
|---------|-----------|-------------------|
| `Z80-PIC18F-EMU-MAPEADO-POR-MREQ+ROM-PPI-USART-8250A-INT-HARDWARE.DSN` | **Esquema NOVO** — NMI por hardware real (Timer0 no pino RA4) | `main-rom.hex` |
| `Z80-PIC18F-EMU-MAPEADO-POR-MREQ+ROM-PPI-USART-8250A.DSN` | Esquema ANTIGO — NMI por polling (pino RE4) | `old-main-rom.hex` |
| `main-rom.hex` | **Binário ATUALIZADO** — NMI por hardware real (Timer0 no pino RA4). Interrompe instruções de bloco (LDIR, CPIR, OTIR, etc.) | `...INT-HARDWARE.DSN` |
| `old-main-rom.hex` | Binário ANTIGO (legado) — NMI por polling de software no pino **RE4** | `...8250A.DSN` |

---

## ⚠️ Correspondência Obrigatória Esquema ↔ Binário

Para o emulador funcionar corretamente, **use o binário com o esquema correspondente**:

| Se você quer usar... | Carregue o binário... | No esquema... |
|----------------------|----------------------|---------------|
| **NMI por Hardware Real** (novo) | `main-rom.hex` | `Z80-PIC18F-EMU-MAPEADO-POR-MREQ+ROM-PPI-USART-8250A-INT-HARDWARE.DSN` |
| **NMI por Polling** (antigo) | `old-main-rom.hex` | `Z80-PIC18F-EMU-MAPEADO-POR-MREQ+ROM-PPI-USART-8250A.DSN` |

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

## 🔌 Mapeamento de I/O (PPI 8255 e USART 8250A)

| Dispositivo | Endereço Base | Descrição |
|-------------|--------------|-----------|
| **PPI 8255** | `00h – 03h` | Portas A, B, C e Controle |
| **USART 8250A** | `A definir` | Comunicação Serial (RS-232) |

*(Os endereços específicos estão documentados no esquema do Proteus.)*

## 🔧 Pinagem do NMI

| Esquema | Pino do PIC | Tipo de Interrupção |
|---------|-------------|---------------------|
| `...INT-HARDWARE.DSN` (novo) | **RA4** (Timer0) | Hardware real (Timer0 como contador externo) |
| `...8250A.DSN` (antigo) | **RE4** | Polling de software no `main()` |

## 🧩 Componentes Utilizados

- **Z80-EMU** (emulada no Proteus)
- **PPI 8255** — Interface Paralela Programável (Portas A, B e C)
- **USART 8250A** — Comunicação Serial Assíncrona
- **DIP switches** — entrada de dados
- **LEDs** — visualização das saídas
- **Decodificador de endereço** (74LS138 ou similar)

## 📌 Recomendação

- **Para produção e novos testes:** use `main-rom.hex` + `...INT-HARDWARE.DSN`.
- **Para comparação histórica:** use `old-main-rom.hex` + `...8250A.DSN`.

**Não misture os arquivos entre as duas configurações.**
