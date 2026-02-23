import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_controller.dart';
import '../../auth/state/auth_controller.dart';
import '../../splash/screens/splash_screen.dart';
import '../../profile/screens/edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final authController = context.read<AuthController>();

    // Auth Guard: Redirect to Splash if not authenticated
    if (!authController.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      child: Icon(Icons.person_outline, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Consumer<AuthController>(
                      builder: (context, auth, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              auth.userName ?? 'usuário',
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              auth.userEmail ?? '',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                        if (changed == true) {
                          // The UI should refresh automatically via Consumer<AuthController>,
                          // but we could explicitly trigger a refresh if needed.
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.25),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Editar perfil'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(label: 'Conta'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  // _SettingsTile(
                  //   icon: Icons.person_outline,
                  //   label: 'Perfil',
                  //   onTap: () {},
                  // ),
                  _SettingsTile(
                    icon: Icons.credit_card_outlined,
                    label: 'Pagamento',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_none_outlined,
                    label: 'Notificações',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: 'Preferências'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  Consumer<ThemeController>(
                    builder: (context, themeController, _) {
                      final isDark =
                          themeController.themeMode == ThemeMode.dark;
                      return _SettingsTile(
                        icon: Icons.nightlight_round,
                        label: 'Tema',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isDark ? 'Escuro' : 'Claro',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
                        onTap: themeController.toggleTheme,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: 'Suporte'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.help_outline,
                    label: 'Central de ajuda',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    label: 'Sobre o app',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.shield_outlined,
                    label: 'Privacidade',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.exit_to_app_outlined,
                    label: 'Sair da conta',
                    iconColor: Colors.orangeAccent,
                    textColor: Colors.orangeAccent,
                    onTap: () async {
                      try {
                        await authController.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const SplashScreen(),
                            ),
                            (route) => false,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sessão encerrada com sucesso'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao sair: ${e.toString()}'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: children
            .map(
              (child) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: child,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.textColor,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor:
            iconColor?.withOpacity(0.1) ?? colorScheme.primaryContainer,
        child: Icon(icon, color: iconColor ?? colorScheme.onPrimaryContainer),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: textColor != null ? FontWeight.w600 : null,
        ),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right,
            size: 20,
            color: textColor ?? colorScheme.onSurfaceVariant,
          ),
      onTap: onTap,
    );
  }
}
