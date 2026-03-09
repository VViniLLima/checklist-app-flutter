import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/state/auth_controller.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../../splash/screens/splash_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final authController = context.watch<AuthController>();
    final isAuthenticated = authController.isAuthenticated;

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
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Consumer<AuthController>(
                          builder: (context, auth, child) {
                            final avatarUrl = auth.userAvatarUrl;
                            return CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              backgroundImage: avatarUrl != null
                                  ? NetworkImage(avatarUrl)
                                  : const AssetImage(
                                      'assets/Images/ProfilePicture.png',
                                    ),
                            );
                          },
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                    Opacity(
                      opacity: isAuthenticated ? 1.0 : 0.4,
                      child: ElevatedButton(
                        onPressed: isAuthenticated
                            ? () async {
                                final changed = await Navigator.of(context)
                                    .push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const EditProfileScreen(),
                                      ),
                                    );
                                if (changed == true) {
                                  // The UI should refresh automatically via Consumer<AuthController>,
                                  // but we could explicitly trigger a refresh if needed.
                                }
                              }
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Faça login para acessar esta opção',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Editar perfil'),
                      ),
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
                    enabled: isAuthenticated,
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
                  if (isAuthenticated)
                    _SettingsTile(
                      icon: Icons.exit_to_app_outlined,
                      label: 'Sair da conta',
                      iconColor: Colors.orangeAccent,
                      textColor: Colors.orangeAccent,
                      onTap: () async {
                        try {
                          await authController.signOut();
                          if (context.mounted) {
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
                    )
                  else
                    _SettingsTile(
                      icon: Icons.login_outlined,
                      label: 'Fazer login',
                      iconColor: colorScheme.primary,
                      textColor: colorScheme.primary,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SplashScreen(),
                          ),
                        );
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
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final tile = ListTile(
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
            enabled ? Icons.chevron_right : Icons.lock_outline,
            size: 20,
            color: textColor ?? colorScheme.onSurfaceVariant,
          ),
      onTap: enabled
          ? onTap
          : () {
              // Show message when disabled option is tapped
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Faça login para acessar esta opção'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
    );

    if (!enabled) {
      return Opacity(opacity: 0.4, child: tile);
    }

    return tile;
  }
}
