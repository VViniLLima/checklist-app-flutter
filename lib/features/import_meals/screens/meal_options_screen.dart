import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../shopping_list/models/n8n_response.dart';
import '../../shopping_list/services/n8n_list_builder_service.dart';
import '../../shopping_list/state/shopping_list_controller.dart';
import '../../shopping_list/screens/shopping_list_screen.dart';

/// Screen that displays meal options from the n8n webhook response
/// and allows the user to select which meals to include in a new shopping list.
///
/// Accepts a [payload] map (decoded JSON from the webhook) and renders
/// each meal option as a selectable card with its items listed.
class MealOptionsScreen extends StatefulWidget {
  final Map<String, dynamic> payload;

  const MealOptionsScreen({super.key, required this.payload});

  @override
  State<MealOptionsScreen> createState() => _MealOptionsScreenState();
}

class _MealOptionsScreenState extends State<MealOptionsScreen> {
  late N8nResponse _response;
  final Set<int> _selectedIndices = {};
  bool _isCreating = false;
  String? _parseError;

  @override
  void initState() {
    super.initState();
    _parseResponse();
  }

  void _parseResponse() {
    try {
      _response = N8nResponse.fromJson(widget.payload);
      if (_response.mealOptions.isEmpty) {
        _parseError = null; // Not an error, just empty
      }
    } catch (e) {
      _parseError = 'Resposta inválida do servidor';
      _response = N8nResponse(mealOptions: []);
    }
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

    final String timestamp = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(DateTime.now());
    final textController = TextEditingController(
      text: 'Lista importada - $timestamp',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nome da lista'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Como deseja chamar esta lista?',
            hintText: 'Ex: Dieta da semana, Compras...',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (value) {
            Navigator.of(dialogContext).pop();
            _performCreation(value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _performCreation(textController.text.trim());
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCreation(String? name) async {
    setState(() => _isCreating = true);

    try {
      final controller = Provider.of<ShoppingListController>(
        context,
        listen: false,
      );
      final service = N8nListBuilderService(controller);

      final selectedMeals = _selectedIndices
          .map((i) => _response.mealOptions[i])
          .toList();

      // Check if selection yields any items after dedup
      final uniqueCount = service.countUniqueItems(selectedMeals);
      if (uniqueCount == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Nenhum item encontrado nas refeições selecionadas.',
              ),
            ),
          );
        }
        setState(() => _isCreating = false);
        return;
      }

      final newList = await service.buildAndSaveList(
        selectedMeals,
        customName: name?.isEmpty ?? true ? null : name,
      );

      if (mounted && newList != null) {
        final navigator = Navigator.of(context);

        // Pop back to the main screen (first route)
        navigator.popUntil((route) => route.isFirst);

        // Push the shopping list screen to show the newly created list
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

    // Show error state if parsing failed
    if (_parseError != null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Criar lista'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: colorScheme.error.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  _parseError!,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Criar lista'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _response.mealOptions.isEmpty
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
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Selection summary
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Row(
                    children: [
                      Text(
                        'Selecione as refeições',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const Spacer(),
                      if (_selectedIndices.isNotEmpty)
                        Text(
                          '${_selectedIndices.length} selecionada${_selectedIndices.length > 1 ? 's' : ''}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Meal cards list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _response.mealOptions.length,
                    itemBuilder: (context, index) {
                      final meal = _response.mealOptions[index];
                      final isSelected = _selectedIndices.contains(index);

                      return _MealOptionCard(
                        meal: meal,
                        isSelected: isSelected,
                        onTap: () => _onToggleMeal(index),
                      );
                    },
                  ),
                ),
                // Bottom action bar
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

/// A card widget that displays a single meal option with its items.
///
/// Shows a checkbox for selection, the meal name as title,
/// and a list of items with their categories as muted subtext.
class _MealOptionCard extends StatelessWidget {
  final N8nMeal meal;
  final bool isSelected;
  final VoidCallback onTap;

  const _MealOptionCard({
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
        margin: const EdgeInsets.only(bottom: 12),
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
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: meal name + checkbox
            Row(
              children: [
                Expanded(
                  child: Text(
                    meal.mealName,
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
            const Divider(height: 20),
            // Items list
            ...meal.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
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
                          if (item.category.isNotEmpty)
                            Text(
                              item.category,
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

/// Bottom action bar with Cancel and "Criar lista" buttons.
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
