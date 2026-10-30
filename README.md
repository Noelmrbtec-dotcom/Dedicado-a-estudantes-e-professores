# Z80-PIC — Emulador de Z80 para Ensino de Arquitetura de Computadores

![Platform](https://img.shields.io/badge/platform-PIC18F6722-blue)
![CPU](https://img.shields.io/badge/CPU-Zilog%20Z80-red)
![Instructions](https://img.shields.io/badge/Instructions-244%20%2B%20Extensions-brightgreen)
![Completeness](https://img.shields.io/badge/Completeness-100%25-success)
![License](https://img.shields.io/badge/license-MIT-blue)



## 📖 Sobre este repositório

Este repositório é dedicado ao **ensino de arquitetura de computadores** 
usando o processador **Zilog Z80** como ferramenta didática.

Aqui você encontra:

- **Arquivo `.hex`** do emulador Z80-PIC (para gravar no PIC18F6722 ou 
  carregar no Proteus)
- **Esquema do Proteus** para simulação
- **Programas de exemplo em assembly Z80** para testar o emulador

**O código-fonte do emulador não está disponível publicamente.** 
Este repositório disponibiliza apenas os binários e os exemplos, para 
que alunos e professores possam **usar** o emulador, mas não modificá-lo.

---

## 🎯 Objetivo pedagógico

O Z80 é um dos processadores mais importantes da história da computação. 
Seu conjunto de instruções é **didático**, seu **barramento é explícito**, 
e seu comportamento é **determinístico**.

Este emulador permite que alunos e professores:

1. **Visualizem o funcionamento da arquitetura von Neumann** 
   (memória unificada para dados e instruções)
2. **Executem programas em assembly Z80** e vejam o resultado em tempo real
3. **Observem o estado do barramento** (MREQ, IOREQ, RD, WR, M1, etc.)
4. **Compreendam o ciclo de instrução** (fetch-decode-execute) na prática
5. **Testem conceitos de interrupção, I/O e temporização**

---

## 🆕 Interrupções por Hardware Real (INT e NMI)

O Z80-EMU implementa **interrupções reais de hardware** usando o Timer0 do
PIC18F6722 como contador externo no pino RA4. Os sinais de **INT** (RE3) e
**NMI** (RE4) são combinados por uma porta AND (74LS08) e conectados ao RA4.

### Como funciona

```text
INT (Z80, RE3) ──┐
                 ├── 74LS08 (AND) ──→ RA4 (Timer0)
NMI (Z80, RE4) ──┘


- Quando **qualquer** interrupção é acionada, a saída da AND vai para 0.
- O Timer0 detecta a borda de descida e gera uma **interrupção real** no PIC.
- A ISR lê RE3 e RE4 para identificar a fonte (INT ou NMI).
- O emulador pausa a execução, empilha o PC do Z80 e salta para o vetor
  correto (`0x0038` para INT, `0x0066` para NMI).
- Após `RETI`/`RETN`, o Z80 **retoma a execução exatamente de onde parou**.
```
### O que foi validado

- **8 instruções de bloco** (`LDIR`, `LDDR`, `CPIR`, `CPDR`, `INIR`, `INDR`,
  `OTIR`, `OTDR`) interrompidas por **INT e NMI reais** durante a execução.
- **Contexto preservado:** `BC`, `HL`, `DE` e flags não são corrompidos.
- **Fidelidade ao Z80 real:** o comportamento é idêntico ao silício da Zilog,
  que testa os pinos INT/NMI a cada ciclo de máquina.

---

## ⚠️ Limitações Conhecidas

### 1. Versões de Binário (Novo vs. Antigo)

A versão **nova** (`main-rom.hex`) implementa INT e NMI por hardware real.
A versão **antiga** (`old-main-rom.hex`) usava polling de software para a NMI
e é mantida apenas para referência histórica.

**Recomendação:** use sempre o `main-rom.hex` com o esquema do Proteus que
inclui a porta AND (`...NMI-INT-HARDWARE.DSN`).

### 2. Outras Observações

- O emulador roda a ~100 kHz com debug ativado (para fins didáticos) e
  ~4 MHz sem debug (versão interna, não distribuída).
- O foco do projeto é o **ensino** e a **visualização do barramento**,
  não a execução em alta velocidade.

---

## 💚 Contribuição voluntária

O desenvolvimento do emulador Z80-PIC levou meses de trabalho, e a 
documentação continua sendo refinada. Se este material foi útil para 
você (ou para seus alunos), e você deseja contribuir voluntariamente 
para que o projeto continue evoluindo, considere uma doação.

**Não é obrigatório.** O projeto permanece livre e acessível para todos, 
independentemente de qualquer contribuição.

### Como contribuir

🔹 **PIX:** 15481313855  

### Outras formas de contribuir (sem dinheiro)

• Compartilhar o projeto nas redes sociais  
• Enviar feedback ou sugestões  
• Reportar bugs ou problemas  
• Citar o projeto em trabalhos acadêmicos  
• Usar em sala de aula e contar como foi

Toda contribuição — financeira ou não — é muito bem-vinda! 🙏
