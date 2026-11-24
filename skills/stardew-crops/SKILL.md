---
name: stardew-crops
description: >-
  Analisa especificamente a lavoura e plantações ativas do Stardew Valley (sem poluir com dados de perfeição). Informa plantas prontas para colheita hoje, previsão de colheitas futuras, gastos com sementes, projeções de lucro em venda pura (sem estrela), geleia/conserva, vinho/suco e desidratador (1.6), analisa quantas máquinas o jogador possui atualmente no save (Jarras, Barris, Desidratadores) e dá o melhor conselho de custo-benefício (vender puro para ter caixa ou guardar para processar), além de calcular exatamente o que ainda dá tempo de plantar antes do final da estação. Use sempre que o usuário perguntar sobre colheitas, lavouras, plantações, lucro de crops ou usar '/stardew-crops'.
---

# Stardew Valley Crops, Harvest & ROI Advisor (1.6+)

Esta skill é focada exclusivamente na rotina agrícola do save do jogador no Stardew Valley. Ela examina todas as plantações no mapa da fazenda, contabiliza as máquinas de artesanato disponíveis e projeta o retorno financeiro ideal.

## Como Executar a Análise

Execute o script PowerShell auxiliar:

```powershell
powershell -ExecutionPolicy Bypass -File "skills/stardew-crops/scripts/analyze_crops.ps1" -TargetSave "<NomeDoPersonagemOuSave>"
```

*(Se `-TargetSave` não for informado, o save mais recente em `%APPDATA%\StardewValley\Saves` será utilizado automaticamente).*

---

## O Que Esta Skill Calcula e Reporta

1. **Colheitas Prontas Hoje**:
   - Quantas unidades e quais culturas estão maduras exatamente no dia atual do save.
2. **Plantações em Crescimento**:
   - Quantidade de dias restantes até a colheita.
   - Data prevista no calendário do jogo.
   - Checagem de segurança se a planta amadurece antes do dia 28 da estação atual.
3. **Parque Industrial (Máquinas)**:
   - Contabiliza quantas Jarras de Conserva, Barris e Desidratadores (1.6) o jogador possui (instaladas na fazenda, nos baús ou no inventário).
4. **Análise Financeira & Custo-Benefício**:
   - Custo estimado investido em sementes.
   - Retorno bruto em **Venda Pura** (valor base sem estrelas).
   - Retorno com **Jarras de Conserva** (`Preço Base × 2 + 50`).
   - Retorno com **Barris** (Vinho = `Preço Base × 3` | Suco = `Preço Base × 2.25`).
   - Retorno com **Desidratador 1.6** (5 frutas geram 1 pacote seco vendido por `7.5 × Base + 25`).
   - **Recomendação Estratégica Realista:** Avalia se vale a pena vender tudo puro para gerar capital de giro imediato ou se há capacidade instalada de máquinas para guardar e processar.
5. **Janela de Plantio Sazonal**:
   - Lista exata das sementes da estação que ainda dá tempo de plantar hoje sem risco de perder as plantas na virada de mês.
