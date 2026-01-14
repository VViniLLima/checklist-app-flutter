import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/shopping_list/data/shopping_repository.dart';
import 'features/shopping_list/state/shopping_list_controller.dart';
import 'features/shopping_list/screens/shopping_list_screen.dart';
//import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o repositório
  final repository = await ShoppingRepository.create();
  
  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  final ShoppingRepository repository;

  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = ShoppingListController(repository);
        controller.initialize(); // Carrega dados salvos
        return controller;
      },
      child: MaterialApp(
        title: 'Lista de Compras',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          scaffoldBackgroundColor: Color(0xfff8f3ed),
          fontFamily: 'BwHelderW1',
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const ShoppingListScreen(),
      ),
    );
  }
}
