# Lista de Compras - MVP Flutter

Um aplicativo de lista de compras estilo checklist, organizado por categorias com seções colapsáveis.

## 🚀 Como Rodar

### Pré-requisitos
- Flutter SDK instalado (versão 3.0 ou superior)
- Dispositivo físico ou emulador configurado

### Instalação

1. **Instalar dependências**
```bash
flutter pub get
```

2. **Rodar o aplicativo**
```bash
flutter run
```

3. **Rodar testes**
```bash
flutter test
```

## 📋 Funcionalidades

### ✅ Implementadas no MVP

1. **Múltiplas Listas de Compras** ⭐ **NOVO**
   - Tela inicial (Home) centraliza todas as listas criadas
   - Criar novas listas com nomes personalizados
   - Navegação entre listas existentes
   - Lista padrão "Lista de compras 1" criada automaticamente
   - Migração automática de dados antigos para a primeira lista
   - Cada lista mantém suas próprias categorias e itens
   - Validação: não permite nomes vazios ou duplicados (case-insensitive)

2. **Categorias**
   - Criar categorias personalizadas (ex: "Mercearia", "Hortifruti")
   - Editar nome de categorias existentes (botao de edicao no header da categoria)
   - Mudar cor de fundo das categorias (8 opções de cores)
   - Cada categoria possui um header visual destacado (fundo colorido, texto em negrito)
   - Categorias são colapsáveis com ícone chevron animado
   - Seção "Sem categoria" sempre visível para itens não categorizados
   - "Sem categoria" é uma categoria especial: fixa no topo, não colapsável, permite mudança de cor
   - Validação: não permite nomes vazios ou duplicados (case-insensitive)
   - Reordenacao manual de categorias com drag-and-drop (pressione e segure o header)
   - "Sem categoria" permanece fixa no topo para manter itens nao categorizados previsiveis

3. **Itens de Compras**
   - Adicionar itens dentro de categorias ou sem categoria
   - Editar nome de itens existentes (botão de edição no item)
   - Checkbox para marcar/desmarcar itens
   - Visual diferenciado para itens marcados:
     - Fundo mais claro (cinza)
     - Texto tachado (line-through)
     - Checkbox verde quando marcado
   - Validação: não permite nomes vazios ou duplicados na mesma categoria (case-insensitive)
   
4. **Ordenação Inteligente**
    - **Itens não marcados aparecem primeiro** (ordenados por data de criação)
    - **Itens marcados vão para o fim** (ordenados por data de marcação)
    - Ao desmarcar, item volta para o topo
    - Ordenação é automática e persiste entre sessões
    - **Categorias completas são movidas automaticamente para o fim**
      - Quando TODAS as tarefas de uma categoria (pelo menos 1 item) estiverem marcadas, a categoria será movida automaticamente para o fim da lista de categorias
      - Categorias vazias NÃO são consideradas completas
      - A categoria especial "Sem categoria" NÃO participa desse comportamento e permanece fixa no topo
      - O usuário pode reordenar manualmente as categorias ativas; o reordenamento automático preserva a ordem manual entre categorias ativas e mantém a ordem relativa entre categorias completadas
      - Mudanças de ordem são persistidas

5. **Persistência Local**
   - Dados salvos localmente usando `shared_preferences`
   - Múltiplas listas, categorias, itens e estados são preservados ao fechar o app
   - Carregamento automático ao abrir o aplicativo
   - Migração automática de dados antigos para o novo formato
   - Cada lista tem seus próprios dados isolados

6. **Validações**
   - Não permite criar/editar categorias/itens com nome vazio
   - Não permite nomes duplicados (categorias: globalmente; itens: dentro da mesma categoria)
   - Validação case-insensitive para evitar duplicatas
   - Feedback visual com SnackBar para validações

## 🏗️ Arquitetura

### Estrutura de Pastas

```
lib/
├── main.dart                          # Ponto de entrada, configuração do Provider
└── features/
    └── shopping_list/
        ├── models/                    # Modelos de dados
        │   ├── shopping_list.dart     # Model: Lista de compras
        │   ├── category.dart          # Model: Categoria (com cor)
        │   └── shopping_item.dart     # Model: Item de compras
        │
        ├── data/                      # Camada de dados
        │   └── shopping_repository.dart  # Persistência com SharedPreferences
        │
        ├── state/                     # Gerenciamento de estado
        │   └── shopping_list_controller.dart  # ChangeNotifier com lógica de negócio
        │
        ├── widgets/                   # Componentes reutilizáveis
        │   ├── category_header.dart   # Header de categoria (com seletor de cor)
        │   ├── category_section.dart  # Seção completa (header + itens)
        │   └── shopping_item_tile.dart # Card individual de item
        │
        └── screens/                   # Telas
            ├── home_screen.dart       # Tela inicial com lista de listas
            └── shopping_list_screen.dart  # Tela de uma lista específica
```

### Camadas

#### 1. **Models** (`models/`)
- `ShoppingList`: Representa uma lista de compras com id, nome e data de criação
- `Category`: Representa uma categoria com id, nome, estado de colapso e cor (colorValue)
- `ShoppingItem`: Representa um item com id, nome, estado checked, categoryId, timestamps
- Todos possuem serialização/deserialização JSON para persistência

#### 2. **Data** (`data/`)
- `ShoppingRepository`: Interface com SharedPreferences
  - Salva/carrega listas, categorias e itens como JSON
  - Suporte a múltiplas listas (dados isolados por listId)
  - Migração automática de dados antigos para o novo formato
  - Tratamento de erros de deserialização

#### 3. **State** (`state/`)
- `ShoppingListController`: ChangeNotifier que gerencia todo o estado
  - Gerenciamento de múltiplas listas de compras
  - Lista ativa (activeListId) determina qual lista está sendo visualizada
  - CRUD de listas, categorias e itens
  - Lógica de ordenação (itens não marcados primeiro)
  - Colapso/expansão de categorias
  - Mudança de cor de categorias
  - Persistência automática após mudanças
  - **Regra principal**: Ao marcar item, define `checkedAt` e reordena via `_sortItems()`
  - **Categoria especial**: "Sem categoria" (id: 'sem-categoria') é criada automaticamente em cada lista

#### 4. **Widgets** (`widgets/`)
- `CategoryHeader`: Header visual com chevron animado e botão de adicionar
- `ShoppingItemTile`: Card de item com checkbox, texto e botão deletar
- `CategorySection`: Agrupa header + lista de itens com animação de colapso

#### 5. **Screens** (`screens/`)
- `HomeScreen`: Tela inicial que exibe todas as listas
  - Lista todas as listas de compras criadas
  - Destaca a lista ativa
  - Dialog para criar nova lista
  - Navegação para ShoppingListScreen ao selecionar uma lista
- `ShoppingListScreen`: Tela de uma lista específica
  - Exibe todas as seções (Sem categoria + categorias criadas)
  - Dialogs para adicionar categoria/item
  - Confirmação antes de deletar

## 🎨 Decisões de Design

### Gerenciamento de Estado
**Escolha: Provider + ChangeNotifier**

- **Prós**: 
  - Simples, nativo do Flutter (não requer libs complexas)
  - Ideal para MVP com escopo bem definido
  - Boa separação entre UI e lógica
  - Fácil de testar

- **Alternativas consideradas**:
  - Bloc: Mais verboso para esse escopo
  - Riverpod: Overhead desnecessário para MVP
  - ValueNotifier: Menos estruturado

### Persistência
**Escolha: SharedPreferences com JSON**

- **Prós**:
  - Setup rápido e simples
  - Suficiente para MVP (dados não complexos)
  - Serialização JSON é leve
  
- **Alternativas consideradas**:
  - Hive: Mais performático, mas adiciona complexidade
  - SQLite: Overkill para dados simples

### Ordenação
**Implementação: Lógica no Controller**

A ordenação acontece em `getItemsByCategory()`:
1. Separa itens em `checked` e `unchecked`
2. Ordena unchecked por `createdAt`
3. Ordena checked por `checkedAt`
4. Retorna `[...unchecked, ...checked]`

**Importante**: A ordenação é calculada dinamicamente (não altera a lista original), garantindo consistência.

### IDs
**Escolha: Timestamp como String**

```dart
id: DateTime.now().millisecondsSinceEpoch.toString()
```

- Simples e suficiente para MVP
- Evita colisões em uso normal
- Produção poderia usar UUID

## 🧪 Testes

### Cobertura de Testes

Arquivo: `test/shopping_list_controller_test.dart`

#### Grupos de Testes:

1. **Gerenciamento de Categorias**
   - Adicionar categoria
   - Colapsar/expandir categoria

2. **Gerenciamento de Itens**
   - Adicionar item
   - Marcar/desmarcar item
   - Validar timestamps

3. **Ordenação de Itens** ⭐ (Mais importante)
   - Itens não marcados aparecem primeiro
   - Múltiplos itens marcados mantêm ordem de marcação
   - Desmarcar move item de volta para o topo

4. **Persistência**
   - Categorias persistem entre sessões
   - Itens persistem entre sessões
   - Estado de checked persiste

### Executar Testes

```bash
flutter test
```

## 🔮 Próximos Passos (Fora do MVP)

Funcionalidades que poderiam ser adicionadas:

1. ~~**Editar nome de categoria/item**~~ ✅ **Implementado**
2. ~~**Reordenar categorias manualmente**~~ ✅ **Implementado** (drag and drop)
3. ~~**Múltiplas listas**~~ ✅ **Implementado** (Home screen com múltiplas listas)
4. ~~**Personalização de cores**~~ ✅ **Implementado** (8 cores para categorias)
5. **Editar/excluir listas de compras**
6. **Busca/filtro de itens**
7. **Temas claro/escuro**
8. **Compartilhar lista** (export para texto/PDF)
9. **Sincronização na nuvem** (Firebase)
10. **Quantidade de itens** (ex: "Arroz - 2kg")

## 📦 Dependências

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1          # Gerenciamento de estado
  shared_preferences: ^2.2.2 # Persistência local
```

## 👨‍💻 Desenvolvimento

### Adicionar Nova Feature

1. Criar modelos em `models/` (se necessário)
2. Adicionar método no `ShoppingListController`
3. Persistir via `ShoppingRepository`
4. Criar/atualizar widget em `widgets/`
5. Adicionar testes em `test/`

### Boas Práticas Seguidas

- ✅ Widgets stateless quando possível
- ✅ Uso de `const` para otimização
- ✅ Nomes descritivos para classes, métodos e variáveis
- ✅ Comentários explicando lógica não-trivial
- ✅ Separação clara de responsabilidades
- ✅ Modelos imutáveis com `copyWith`
- ✅ Tratamento de erros em operações assíncronas

## 📝 Licença

Projeto educacional - MVP para demonstração de conceitos Flutter.

---

**Desenvolvido com Flutter 💙**
