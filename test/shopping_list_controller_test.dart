import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist_app/features/shopping_list/data/shopping_repository.dart';
import 'package:checklist_app/features/shopping_list/state/shopping_list_controller.dart';

void main() {
  late ShoppingListController controller;
  late ShoppingRepository repository;

  setUp(() async {
    // Configura SharedPreferences mock
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = ShoppingRepository(prefs);
    controller = ShoppingListController(repository);
    await controller.initialize();
  });

  group('Gerenciamento de Categorias', () {
    test('Deve adicionar categoria', () async {
      await controller.addCategory('Mercearia');

      expect(controller.categories.length, 1);
      expect(controller.categories.first.name, 'Mercearia');
    });

    test('Deve colapsar/expandir categoria', () async {
      await controller.addCategory('Hortifruti');
      final categoryId = controller.categories.first.id;

      expect(controller.isCategoryCollapsed(categoryId), false);

      await controller.toggleCategoryCollapse(categoryId);
      expect(controller.isCategoryCollapsed(categoryId), true);

      await controller.toggleCategoryCollapse(categoryId);
      expect(controller.isCategoryCollapsed(categoryId), false);
    });
  });

  group('Gerenciamento de Itens', () {
    test('Deve adicionar item', () async {
      await controller.addItem('Arroz', null);

      expect(controller.allItems.length, 1);
      expect(controller.allItems.first.name, 'Arroz');
      expect(controller.allItems.first.isChecked, false);
    });

    test('Deve marcar item como checked', () async {
      await controller.addItem('Feijão', null);
      final itemId = controller.allItems.first.id;

      await controller.toggleItemCheck(itemId);

      final item = controller.allItems.firstWhere((i) => i.id == itemId);
      expect(item.isChecked, true);
      expect(item.checkedAt, isNotNull);
    });

    test('Deve desmarcar item', () async {
      await controller.addItem('Macarrão', null);
      final itemId = controller.allItems.first.id;

      // Marca
      await controller.toggleItemCheck(itemId);
      expect(controller.allItems.first.isChecked, true);

      // Desmarca
      await controller.toggleItemCheck(itemId);
      final item = controller.allItems.firstWhere((i) => i.id == itemId);
      expect(item.isChecked, false);
      expect(item.checkedAt, isNull);
    });
  });

  group('Ordenação de Itens', () {
    test('Itens não marcados aparecem primeiro', () async {
      // Adiciona 3 itens
      await controller.addItem('Item 1', null);
      await Future.delayed(const Duration(milliseconds: 10));
      await controller.addItem('Item 2', null);
      await Future.delayed(const Duration(milliseconds: 10));
      await controller.addItem('Item 3', null);

      // Marca o primeiro item
      final firstItemId = controller.allItems.first.id;
      await controller.toggleItemCheck(firstItemId);

      // Obtém lista ordenada
      final items = controller.getItemsByCategory(null);

      // Item marcado deve estar no fim
      expect(items.length, 3);
      expect(items[0].name, 'Item 2'); // não marcado
      expect(items[1].name, 'Item 3'); // não marcado
      expect(items[2].name, 'Item 1'); // marcado (movido para o fim)
      expect(items[2].isChecked, true);
    });

    test('Múltiplos itens marcados mantêm ordem de marcação', () async {
      // Adiciona 4 itens
      await controller.addItem('A', null);
      await Future.delayed(const Duration(milliseconds: 10));
      await controller.addItem('B', null);
      await Future.delayed(const Duration(milliseconds: 10));
      await controller.addItem('C', null);
      await Future.delayed(const Duration(milliseconds: 10));
      await controller.addItem('D', null);

      final allItems = controller.allItems;
      
      // Marca B, depois D, depois A
      await controller.toggleItemCheck(allItems[1].id); // B
      await Future.delayed(const Duration(milliseconds: 10));
      await controller.toggleItemCheck(allItems[3].id); // D
      await Future.delayed(const Duration(milliseconds: 10));
      await controller.toggleItemCheck(allItems[0].id); // A

      // Obtém lista ordenada
      final items = controller.getItemsByCategory(null);

      // Ordem esperada: [C (não marcado), B (marcado 1º), D (marcado 2º), A (marcado 3º)]
      expect(items.length, 4);
      expect(items[0].name, 'C'); // único não marcado
      expect(items[0].isChecked, false);
      expect(items[1].name, 'B'); // marcado primeiro
      expect(items[2].name, 'D'); // marcado segundo
      expect(items[3].name, 'A'); // marcado terceiro
    });

    test('Desmarcar item move de volta para o topo', () async {
      await controller.addItem('Item 1', null);
      await Future.delayed(const Duration(milliseconds: 10));
      await controller.addItem('Item 2', null);

      final firstItemId = controller.allItems[0].id;
      
      // Marca item 1
      await controller.toggleItemCheck(firstItemId);
      var items = controller.getItemsByCategory(null);
      expect(items[0].name, 'Item 2'); // não marcado no topo
      expect(items[1].name, 'Item 1'); // marcado no fim

      // Desmarca item 1
      await controller.toggleItemCheck(firstItemId);
      items = controller.getItemsByCategory(null);
      
      // Ambos não marcados agora, ordem de criação
      expect(items[0].name, 'Item 1');
      expect(items[1].name, 'Item 2');
      expect(items[0].isChecked, false);
    });
  });

  group('Persistência', () {
    test('Deve persistir e carregar categorias', () async {
      await controller.addCategory('Bebidas');
      
      // Cria novo controller com mesmo repositório
      final newController = ShoppingListController(repository);
      await newController.initialize();

      expect(newController.categories.length, 1);
      expect(newController.categories.first.name, 'Bebidas');
    });

    test('Deve persistir e carregar itens', () async {
      await controller.addItem('Café', null);
      await controller.addItem('Leite', null);

      // Cria novo controller com mesmo repositório
      final newController = ShoppingListController(repository);
      await newController.initialize();

      expect(newController.allItems.length, 2);
      expect(newController.allItems.any((i) => i.name == 'Café'), true);
      expect(newController.allItems.any((i) => i.name == 'Leite'), true);
    });

    test('Deve persistir estado de checked', () async {
      await controller.addItem('Teste', null);
      final itemId = controller.allItems.first.id;
      await controller.toggleItemCheck(itemId);

      // Cria novo controller
      final newController = ShoppingListController(repository);
      await newController.initialize();

      final item = newController.allItems.first;
      expect(item.isChecked, true);
      expect(item.checkedAt, isNotNull);
    });
  });
}
