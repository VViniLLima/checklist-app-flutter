import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/n8n_response.dart';
import '../services/n8n_list_builder_service.dart';
import '../state/shopping_list_controller.dart';
import 'shopping_list_screen.dart';

class CreateListFromN8nScreen extends StatefulWidget {
  final Map<String, dynamic> responseJson;

  const CreateListFromN8nScreen({super.key, required this.responseJson});

  @override
  State<CreateListFromN8nScreen> createState() =>
      _CreateListFromN8nScreenState();
}

class _CreateListFromN8nScreenState extends State<CreateListFromN8nScreen> {
  late N8nResponse _n8nResponse;
  final Set<int> _selectedIndices = {};
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _n8nResponse = N8nResponse.fromJson(widget.responseJson);
  }

  void _onToggleMeal(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  Future<void> _onCreateList() async {
    if (_selectedIndices.isEmpty || _isCreating) return;

    setState(() => _isCreating = true);

    try {
      final controller = Provider.of<ShoppingListController>(
        context,
        listen: false,
      );
      final service = N8nListBuilderService(controller);

      final selectedMeals = _selectedIndices
          .map((i) => _n8nResponse.refeicoes[i])
          .toList();

      final newList = await service.buildAndSaveList(selectedMeals);

      if (mounted && newList != null) {
        // Navigate to the list detail screen
        final navigator = Navigator.of(context);

        // Pop back to the main screen (which is the first route)
        navigator.popUntil((route) => route.isFirst);

        // Push the shopping list screen to show the newly created (and already active) list
        navigator.push(
          MaterialPageRoute(builder: (context) => const ShoppingListScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lista "${newList.name}" criada com sucesso!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao criar lista: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Selecionar refeições'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onBackground,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _n8nResponse.refeicoes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma refeição encontrada',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _n8nResponse.refeicoes.length,
                    itemBuilder: (context, index) {
                      final meal = _n8nResponse.refeicoes[index];
                      final isSelected = _selectedIndices.contains(index);

                      return _MealCard(
                        meal: meal,
                        isSelected: isSelected,
                        onTap: () => _onToggleMeal(index),
                      );
                    },
                  ),
                ),
                _BottomActionBar(
                  onAction: _onCreateList,
                  onCancel: () => Navigator.of(context).pop(),
                  isEnabled: _selectedIndices.isNotEmpty && !_isCreating,
                  isLoading: _isCreating,
                ),
              ],
            ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final N8nMeal meal;
  final bool isSelected;
  final VoidCallback onTap;

  const _MealCard({
    required this.meal,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.05)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.1),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    meal.nome,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  activeColor: colorScheme.primary,
                ),
              ],
            ),
            const Divider(height: 24),
            ...meal.itens.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: colorScheme.primary.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.item,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            item.categoria,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final VoidCallback onAction;
  final VoidCallback onCancel;
  final bool isEnabled;
  final bool isLoading;

  const _BottomActionBar({
    required this.onAction,
    required this.onCancel,
    required this.isEnabled,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: isLoading ? null : onCancel,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isEnabled ? onAction : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Criar lista',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
