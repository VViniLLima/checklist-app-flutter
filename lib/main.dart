import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/shopping_list/data/shopping_repository.dart';
import 'features/shopping_list/data/sync_queue_repository.dart';
import 'features/shopping_list/state/shopping_list_controller.dart';
import 'features/shopping_list/state/search_controller.dart' as search;
import 'features/shopping_list/services/supabase_list_service.dart';
import 'features/splash/screens/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/services/user_identity_service.dart';
import 'core/services/sync_service.dart';
//import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/data/auth_repository.dart';
import 'features/auth/state/auth_controller.dart';

// Global scaffold messenger key to centralize SnackBar presentation
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Inicializa o repositório
  final repository = await ShoppingRepository.create();
  // Inicializa o repositório de sincronização
  final syncQueueRepository = await SyncQueueRepository.create();
  // Inicializa formatação de data para pt_BR

  await initializeDateFormatting('pt_BR', null);

  runApp(
    MyApp(repository: repository, syncQueueRepository: syncQueueRepository),
  );
}

class MyApp extends StatelessWidget {
  final ShoppingRepository repository;
  final SyncQueueRepository syncQueueRepository;

  const MyApp({
    super.key,
    required this.repository,
    required this.syncQueueRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthRepository()),
        ChangeNotifierProvider(
          create: (context) => AuthController(context.read<AuthRepository>()),
        ),
        // Plain (non-notifying) service — just holds the Supabase client handle
        Provider(create: (_) => SupabaseListService()),
        // Sync queue repository for offline-to-online sync
        Provider(create: (_) => syncQueueRepository),
        // Sync service for offline-to-online sync
        ChangeNotifierProvider(
          create: (context) => SyncService(
            queueRepo: context.read<SyncQueueRepository>(),
            supabaseService: context.read<SupabaseListService>(),
          ),
        ),
        ChangeNotifierProxyProvider<AuthController, UserIdentityService>(
          create: (context) => UserIdentityService(),
          update: (context, auth, userIdentity) {
            // Update user identity when auth state changes
            final userId = auth.user?.id;
            userIdentity?.updateAuthenticatedUserId(userId);
            return userIdentity!;
          },
        ),
        ChangeNotifierProxyProvider3<
          UserIdentityService,
          AuthController,
          SyncService,
          ShoppingListController
        >(
          create: (context) {
            final userIdentityService = context.read<UserIdentityService>();
            final authController = context.read<AuthController>();
            final supabaseListService = context.read<SupabaseListService>();
            final syncService = context.read<SyncService>();
            final controller = ShoppingListController(
              repository,
              userIdentityService,
            );

            // Wire Supabase context for initial auth state
            controller.setSupabaseContext(
              supabaseListService,
              authController.user?.id,
            );

            // Wire sync service
            controller.setSyncService(syncService);

            // Initialize sync service
            syncService.initialize();

            // Initialize user identity service first
            userIdentityService.initialize(authController);

            // Then initialize shopping list controller
            controller.initialize(); // Carrega dados salvos
            return controller;
          },
          update: (context, userIdentity, auth, syncService, shopping) {
            // Keep Supabase context in sync on every auth/identity change
            shopping?.setSupabaseContext(
              context.read<SupabaseListService>(),
              auth.user?.id,
            );
            // Keep sync service in sync
            shopping?.setSyncService(syncService);
            // Reload shopping lists when user identity changes (login/logout)
            shopping?.reloadForOwner();
            return shopping!;
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
