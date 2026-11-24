---
name: stardew-helper
description: >-
  Analisa saves do Stardew Valley (incluindo atualização 1.6+), rastreando progresso rumo ao 100% de perfeição (Perfection Tracker), trazendo contagens exatas de faltantes (ex: 16/75 peixes, faltam 59), status minucioso de cada pacote do Centro Comunitário (o que foi entregue e o que falta), receitas de culinária e fabricação com alertas sazonais para não perder itens antes do fim do mês. Use sempre que o usuário pedir análise do save, status de perfeição ou ao digitar '/stardew-helper'.
---

# Stardew Valley Save, Perfection & Community Center Helper (1.6+)

Esta skill inspeciona diretamente o save local do jogo Stardew Valley, lendo o XML oficial e extraindo métricas precisas sobre a jornada rumo à Perfeição (100% Perfection).

## Como Executar a Análise

Execute o script PowerShell auxiliar passando o nome ou prefixo do save desejado (se omitido, o script seleciona automaticamente o save modificado mais recentemente):

```powershell
powershell -ExecutionPolicy Bypass -File "skills/stardew-helper/scripts/analyze_save.ps1" -TargetSave "<NomeDoPersonagemOuSave>"
```

> **Local padrão dos saves:** `%APPDATA%\StardewValley\Saves`

---

## Diretrizes de Resposta para o Assistente

Ao analisar os dados do jogo, mantenha a apresentação organizada seguindo estas regras:

### 1. Contagens no Formato `Atual / Total (Faltam X)`
Apresente dados quantitativos sempre com a meta e o que falta:
- **Peixes Capturados:** `X / 75 (Faltam Y)`
- **Pratos Cozinhados:** `X / 80 (Faltam Y)`
- **Receitas Fabricadas (Crafting):** `X / 149 (Faltam Y)`
- **Amizades no Máximo (8+ corações):** `X / 34 (Faltam Y)`
- **Nozes Douradas (Ilha Gengibre):** `X / 130 (Faltam Y)`
- **Habilidades:** Nível `X / 10 (Faltam Y)` para Agricultura, Mineração, Coleta, Pesca e Combate.
- **Obeliscos da Torre do Mago:** `X / 4 (Faltam Y)` + Status do Relógio Dourado (10M).

### 2. Detalhamento do Centro Comunitário
Apresente o estado de forma visual e transparente:
- Indique os pacotes **COMPLETOS**.
- Para pacotes **EM PROGRESSO**, liste claramente:
  - `[X]` Itens já entregues no pacote.
  - `[ ]` Itens que ainda faltam entregar.
- Destaque pacotes que ainda **não foram iniciados**, alertando sobre a urgência dos que possuem itens exclusivos da estação vigente.

### 3. Alertas Sazonais Críticos
- Aponte peixes, colheitas e itens de coleta que **deixarão de estar disponíveis** ao final da estação atual (dia 28).
- Sinalize itens que devem ser guardados no baú para receitas culinárias futuras antes da mudança de estação.
