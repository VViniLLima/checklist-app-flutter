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

1. **Categorias**
   - Criar categorias personalizadas (ex: "Mercearia", "Hortifruti")
   - Cada categoria possui um header visual destacado (fundo azul, texto em negrito)
   - Categorias são colapsáveis com ícone chevron animado
   - Seção "Sem categoria" sempre visível para itens não categorizados

2. **Itens de Compras**
   - Adicionar itens dentro de categorias ou sem categoria
   - Checkbox para marcar/desmarcar itens
   - Visual diferenciado para itens marcados:
     - Fundo mais claro (cinza)
     - Texto tachado (line-through)
     - Checkbox verde quando marcado
   
3. **Ordenação Inteligente**
   - **Itens não marcados aparecem primeiro** (ordenados por data de criação)
   - **Itens marcados vão para o fim** (ordenados por data de marcação)
   - Ao desmarcar, item volta para o topo
   - Ordenação é automática e persiste entre sessões

4. **Persistência Local**
   - Dados salvos localmente usando `shared_preferences`
   - Categorias, itens e estados são preservados ao fechar o app
   - Carregamento automático ao abrir o aplicativo

5. **Validações**
   - Não permite criar categorias/itens com nome vazio
   - Feedback visual com SnackBar para validações

## 🏗️ Arquitetura

### Estrutura de Pastas

```
lib/
├── main.dart                          # Ponto de entrada, configuração do Provider
└── features/
    └── shopping_list/
        ├── models/                    # Modelos de dados
        │   ├── category.dart          # Model: Categoria
        │   └── shopping_item.dart     # Model: Item de compras
        │
        ├── data/                      # Camada de dados
        │   └── shopping_repository.dart  # Persistência com SharedPreferences
        │
        ├── state/                     # Gerenciamento de estado
        │   └── shopping_list_controller.dart  # ChangeNotifier com lógica de negócio
        │
        ├── widgets/                   # Componentes reutilizáveis
        │   ├── category_header.dart   # Header de categoria
        │   ├── category_section.dart  # Seção completa (header + itens)
        │   └── shopping_item_tile.dart # Card individual de item
        │
        └── screens/                   # Telas
            └── shopping_list_screen.dart  # Tela principal
```

### Camadas

#### 1. **Models** (`models/`)
- `Category`: Representa uma categoria com id, nome e estado de colapso
- `ShoppingItem`: Representa um item com id, nome, estado checked, categoryId, timestamps
- Ambos possuem serialização/deserialização JSON para persistência

#### 2. **Data** (`data/`)
- `ShoppingRepository`: Interface com SharedPreferences
  - Salva/carrega categorias e itens como JSON
  - Tratamento de erros de deserialização

#### 3. **State** (`state/`)
- `ShoppingListController`: ChangeNotifier que gerencia todo o estado
  - CRUD de categorias e itens
  - Lógica de ordenação (itens não marcados primeiro)
  - Colapso/expansão de categorias
  - Persistência automática após mudanças
  - **Regra principal**: Ao marcar item, define `checkedAt` e reordena via `_sortItems()`

#### 4. **Widgets** (`widgets/`)
- `CategoryHeader`: Header visual com chevron animado e botão de adicionar
- `ShoppingItemTile`: Card de item com checkbox, texto e botão deletar
- `CategorySection`: Agrupa header + lista de itens com animação de colapso

#### 5. **Screens** (`screens/`)
- `ShoppingListScreen`: Tela principal que consome o controller via Provider
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

1. **Editar nome de categoria/item**
2. **Reordenar categorias manualmente** (drag and drop)
3. **Busca/filtro de itens**
4. **Temas claro/escuro**
5. **Compartilhar lista** (export para texto/PDF)
6. **Múltiplas listas** (ex: "Supermercado", "Farmácia")
7. **Sincronização na nuvem** (Firebase)
8. **Quantidade de itens** (ex: "Arroz - 2kg")

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
