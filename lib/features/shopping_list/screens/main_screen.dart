import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/shopping_list_controller.dart';
import 'shopping_list_screen.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PlaceholderScreen(title: 'Search', icon: Icons.search_rounded),
    const Center(
      child: Text('Add Item Proxy'),
    ), // Proxy for center button if needed
    const HistoryScreen(),
    const PlaceholderScreen(
      title: 'Profile',
      icon: Icons.person_outline_rounded,
    ),
  ];

  void _onTabTapped(int index) {
    if (index == 2) return; // Center button handled separately or ignored here
    setState(() {
      _currentIndex = index;
    });
  }

  void _showCreateListDialog(BuildContext context) {
    final controller = context.read<ShoppingListController>();
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nova Lista de Compras'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome da lista',
            hintText: 'Ex: Compras do mês, Feira...',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _createList(context, controller, value.trim());
              Navigator.of(dialogContext).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('O nome da lista não pode estar vazio'),
                  ),
                );
                return;
              }

              // Check for duplicates
              final isDuplicate = controller.shoppingLists.any(
                (list) => list.name.toLowerCase() == name.toLowerCase(),
              );

              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Já existe uma lista com este nome'),
                  ),
                );
                return;
              }

              _createList(context, controller, name);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _createList(
    BuildContext context,
    ShoppingListController controller,
    String name,
  ) async {
    await controller.addShoppingList(name);

    // Get the newly created list
    final newList = controller.shoppingLists.last;

    // Set it as active and navigate to it
    await controller.setActiveList(newList.id);

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ShoppingListScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        onCenterTap: () => _showCreateListDialog(context),
      ),
      extendBody:
          true, // Allows the body to go behind the transparent/floating nav bar
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderScreen({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.transparent),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '$title Screen',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
