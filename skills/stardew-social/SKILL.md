---
name: stardew-social
description: >-
  Analisa os relacionamentos, amizades, paqueras/namoro com solteiros e casamento no Stardew Valley. Informa os corações atuais de cada morador, se o usuário já deu presente hoje, quantos presentes faltam para o limite semanal de 2 por morador e quando a semana reseta (domingo), além dos aniversários próximos (que dão 8x pontos). No final, pergunta para qual personagem o jogador quer opções de presentes e cruza os gostos do personagem diretamente com os itens que o jogador possui nos baús e inventário. Use sempre que o usuário perguntar sobre moradores, amizade, presentes, aniversários, namoro ou usar '/stardew-social'.
---

# Stardew Valley Social, Gifts & Romance Tracker

Esta skill monitora os dados de relacionamento, amizades e romance do save local do jogador no Stardew Valley.

## Como Executar a Análise

1. **Visão Geral de Amizades, Limites Semanais e Aniversários Próximos**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "skills/stardew-social/scripts/analyze_social.ps1" -TargetSave "<NomeDoPersonagemOuSave>"
   ```

2. **Consultar Presentes Disponíveis nos Baús para um Personagem Específico**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "skills/stardew-social/scripts/analyze_social.ps1" -TargetSave "<NomeDoPersonagemOuSave>" -CheckNPC "NomeDoNPC"
   ```

*(Se `-TargetSave` for omitido, o script usa automaticamente o save mais recente).*

---

## Regras e Comportamento da Skill

### 1. Limite Semanal de Presentes
- No Stardew Valley, cada aldeão aceita no máximo **2 presentes por semana** (com contagem reiniciando todo Domingo) e no máximo **1 presente por dia**.
- Há uma exceção: no dia do aniversário do personagem, um presente extra sempre pode ser entregue, mesmo que o limite semanal já tenha sido atingido.

### 2. Aniversariantes Próximos
- Sempre destaque os aniversários dos próximos 7 a 15 dias no calendário do jogo.
- **Importância:** Presentes de aniversário concedem um multiplicador de **8x pontos** (+640 pontos para itens Amados, o que equivale a quase 3 corações instantaneamente).

### 3. Cruzamento em Tempo Real com Baús e Inventário
- A skill varre tanto o inventário do jogador quanto todos os baús espalhados pelas localizações do mapa.
- Ao final de qualquer relatório social, o assistente deve **perguntar ativamente** se o jogador deseja consultar sugestões de presentes para algum morador específico.
- Ao informar um morador, a skill exibe exatamente quais itens da lista de **Presentes Amados (Loved)** e **Presentes Gostados (Liked)** o jogador já possui guardados em estoque.
