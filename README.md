# Z80-PIC — Emulador de Z80 para Ensino de Arquitetura de Computadores

![Platform](https://img.shields.io/badge/platform-PIC18F6722-blue)
![CPU](https://img.shields.io/badge/CPU-Zilog%20Z80-red)
![Instructions](https://img.shields.io/badge/Instructions-244%20%2B%20Extensions-brightgreen)
![Completeness](https://img.shields.io/badge/Completeness-100%25-success)
![License](https://img.shields.io/badge/license-MIT-blue)

---

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
   
## ⚠️ Limitações Conhecidas

### 1. Acionamento de Interrupções (IM 0, IM 1 e IM 2)

O Z80-EMU agora utiliza **interrupção real de hardware** via Timer0 do PIC18F6722 
(configurado como contador externo no pino RA4) para a NMI. Isso permite que 
instruções de bloco (LDIR, CPIR, INIR, OTIR, etc.) sejam interrompidas e retomadas 
corretamente, algo raro em emuladores baseados em PIC.

**A limitação restante:** O pino de interrupção **mascarada (INT)** ainda utiliza 
polling de software no loop principal (`main()`). Isso significa que, para os modos 
`IM 0`, `IM 1` e `IM 2`, a interrupção só é detectada quando o Z80 retorna ao 
`check_interrupts()`.

**Consequência:** Se um programa Z80 estiver preso em um loop de bloco (ex: um 
`LDIR` de 65.536 iterações) e precisar ser interrompido pelo pino `INT` (mascarado), 
a interrupção só será atendida após o término da instrução de bloco. Para a **NMI**, 
isso não ocorre, pois ela usa a interrupção de hardware do Timer0.

**Comparação com o Z80 real:** O silício da Zilog testa os pinos INT/NMI **a cada 
ciclo de máquina**. O Z80-EMU já faz isso para a NMI (via Timer0), mas ainda não 
para a INT (que depende do polling).

**Comparação com emuladores existentes (ex: Oshon Z80):** 
Emuladores comerciais baseados em software (como o Oshon) rodam em um PC e 
utilizam threads ou verificação instrução-por-instrução, o que lhes permite 
simular interrupções mascaradas durante loops de bloco. Por outro lado, o Z80-EMU 
roda em um microcontrolador (PIC18F6722) em tempo real, e a INT ainda está no 
modo polling. Apesar dessa limitação, o Z80-EMU se mostrou **mais fiel ao Z80 real 
do que o Oshon em outras frentes**, corrigindo bugs comerciais presentes nas 
instruções `IND`, `OTIR`, `OUTD` e `DAA`.

**Motivo da não correção (ainda):** Os pinos de interrupção nativa do PIC18F6722 
(INT0/INT1) estão **fisicamente ocupados** pelo barramento de endereços 
(PORTB/PORTC) e controle (PORTF). Como já utilizei o Timer0 para a NMI com 
sucesso, a solução para a INT mascarada exigiria um segundo timer ou uma 
reengenharia dos pinos. Isso fica como trabalho futuro para quem desejar 
fidelidade total em `IM 0/1/2`.
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
