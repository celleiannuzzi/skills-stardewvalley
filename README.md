# 🌾 Stardew Valley AI Assistant Skills (Antigravity) 🚜

Conjunto de skills inteligentes para o **Google Antigravity (AGY)** projetadas para ler diretamente o arquivo de save local do Stardew Valley (incluindo a atualização **1.6+**), fornecendo diagnósticos táticos, rastreadores de perfeição, consultoria financeira agrícola e gestão de relacionamentos.

---

## 📦 Skills Inclusas

| Skill / Comando | Descrição |
| :--- | :--- |
| **`/stardew-helper`** | Rastreamento detalhado rumo aos **100% de Perfeição (Perfection)**: peixes pescados, receitas culinárias, itens fabricados, nozes douradas, e o status minucioso de cada pacote do Centro Comunitário (entregues vs. faltantes). |
| **`/stardew-crops`** | Raio-X exclusivo da **lavoura e plantações**: culturas maduras hoje, previsão de colheitas futuras, gastos com sementes, janela de plantio seguro antes do fim da estação e cálculo de ROI (venda pura, geleia, vinho ou desidratador 1.6). |
| **`/stardew-social`** | Gestão de **relacionamentos e amizades**: contagem de corações, limite de 2 presentes semanais, dias até o reset (domingo), aniversários próximos (8x pontos) e cruzamento de gostos com o que o jogador realmente tem guardado nos baús. |
| **`/stardew-strategy`** | Painel de **estratégia e produtividade máxima**: diagnóstico de gargalos, itens no baú prontos para doar ao Museu ou entregar no Centro Comunitário, viabilidade de construções na Robin, o que guardar para receitas e roteiro acionável para o dia, a semana e o próximo mês. |

---

## 🚀 Como Instalar no seu Antigravity

Você pode instalar essas skills tanto em um **projeto específico** quanto **globalmente** para funcionar em qualquer workspace.

### Opção 1: No seu Projeto Atual (Recomendado)
Copie a pasta `skills/` para dentro da pasta `.agents/` na raiz do seu projeto:
```text
seu-projeto/
└── .agents/
    └── skills/
        ├── stardew-helper/
        ├── stardew-crops/
        ├── stardew-social/
        └── stardew-strategy/
```

### Opção 2: Globalmente (Disponível em Qualquer Workspace)
Copie as pastas das skills para o diretório global de skills do Antigravity no seu usuário:
```text
C:\Users\<SeuUsuario>\.gemini\antigravity\skills\
```

---

## 🎮 Como Usar

Com as skills instaladas, basta abrir o chat do Antigravity e interagir naturalmente ou chamar o comando com barra:

1. Digite `/stardew-helper` ou pergunte: *"Como está meu progresso rumo ao 100% de perfeição?"*
2. Digite `/stardew-crops` ou pergunte: *"O que tenho para colher hoje e quanto posso lucrar?"*
3. Digite `/stardew-social` ou pergunte: *"Quais presentes posso dar hoje? Quem faz aniversário essa semana?"*
4. Digite `/stardew-strategy` ou pergunte: *"O que devo focar hoje e nesta semana para ser o mais produtivo possível?"*

> **Nota:** Os scripts buscam automaticamente os saves na pasta padrão do Stardew Valley (`%APPDATA%\StardewValley\Saves`). Caso você jogue em múltiplos saves, você pode especificar o nome do seu personagem nas perguntas!
