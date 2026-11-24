---
name: stardew-strategy
description: >-
  Análise estratégica geral do Stardew Valley com foco em produtividade máxima, conclusão ultrarrápida do Centro Comunitário e planejamento inteligente. Gera roteiros acionáveis do que fazer no dia de hoje, na semana atual e projeções para o mês seguinte. Nos anos avançados (Ano 2+), otimiza rotas de tarefas diárias sugerindo paradas para presentear moradores pelo caminho sem desperdício de tempo. Use sempre que o usuário pedir direcionamento, dicas do dia/semana/mês, produtividade ou usar '/stardew-strategy'.
---

# Stardew Valley Strategy & Productivity Command

Esta skill analisa o estado holístico do save local do jogador no Stardew Valley e traça um roteiro tático de alta produtividade.

## Como Executar a Análise

Execute o script PowerShell auxiliar:

```powershell
powershell -ExecutionPolicy Bypass -File "skills/stardew-strategy/scripts/analyze_strategy.ps1" -TargetSave "<NomeDoPersonagemOuSave>"
```

*(Se `-TargetSave` for omitido, o script usa automaticamente o save mais recente).*

---

## Pilares Estratégicos Analisados

1. **Eliminação Imediata de Gargalos**:
   - Capacidade da mochila (Mochila Básica de 12 espaços vs 24 vs 36).
   - Profundidade da mina (alcançar andar 80+ para Minério de Ouro e automação com Aspersores de Qualidade).
   - Capital para o Cofre do Centro Comunitário (desbloqueio do ônibus para o Deserto de Calico).

2. **Varredura de Itens Prontos nos Baús**:
   - **Centro Comunitário:** Detecta itens estocados em baús ou no inventário que já podem ser entregues hoje para adiantar ou completar pacotes.
   - **Museu do Gunther:** Compara artefatos e minerais guardados com as peças já doadas, avisando caso você tenha itens nunca doados guardados no baú.
   - **Viabilidade de Construções (Robin):** Informa se o jogador já possui a madeira, pedra, argila, barras e ouro necessários para construir Silo, Galinheiro, Celeiro ou reformas da casa.
   - **O Que Guardar das Colheitas:** Avisa quantas unidades de cada colheita devem ser salvas no baú para receitas culinárias da Perfeição, missões do quadro ou presentes amados antes de vender o excedente.

3. **Roteiro Escalonado em 3 Frentes**:
   - **Hoje:** Ações imediatas de maior retorno (colheitas urgentes, entregas prontas, compras prioritárias).
   - **Na Semana:** Festivais, aniversários, colheitas previstas e preparação do terreno.
   - **Próximo Mês:** Planejamento de sementes, reformas da fazenda e grandes metas sazonais.

4. **Otimização de Trajetos & Presentes (Ano 2+)**:
   - Casar as tarefas do dia (ida ao ferreiro, carpinteira, mina ou praia) com os moradores que cruzam o mesmo trajeto geográfico para entregar presentes sem desvios desnecessários de rota.
