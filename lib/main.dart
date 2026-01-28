import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/shopping_list/data/shopping_repository.dart';
import 'features/shopping_list/state/shopping_list_controller.dart';
import 'features/shopping_list/state/search_controller.dart' as search;
import 'features/splash/screens/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
//import 'package:google_fonts/google_fonts.dart';

// Global scaffold messenger key to centralize SnackBar presentation
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o repositório
  final repository = await ShoppingRepository.create();
  // Inicializa formatação de data para pt_BR

  await initializeDateFormatting('pt_BR', null);

  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  final ShoppingRepository repository;

  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final controller = ShoppingListController(repository);
            controller.initialize(); // Carrega dados salvos
            return controller;
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProxyProvider<
          ShoppingListController,
          search.SearchController
        >(
          create: (context) => search.SearchController(
            context.read<ShoppingListController>(),
            repository.prefs,
          ),
          update: (context, shopping, search) => search!,
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp(
            title: 'Lista de Compras',
            scaffoldMessengerKey: scaffoldMessengerKey,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.themeMode,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return AnimatedTheme(
                data: themeController.themeMode == ThemeMode.dark
                    ? AppTheme.dark
                    : AppTheme.light,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: child!,
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
