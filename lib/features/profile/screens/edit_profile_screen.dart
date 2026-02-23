import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/state/auth_controller.dart';
import '../../splash/screens/splash_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Text controllers for form fields
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _idadeController = TextEditingController();
  final _localizacaoController = TextEditingController();
  final _senhaController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final auth = context.read<AuthController>();
    final user = auth.user;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );
      });
      return;
    }

    // Pre-fill controllers
    _nomeController.text = auth.userName ?? '';
    _emailController.text = auth.userEmail ?? '';

    // Load local data
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _idadeController.text = prefs.getString('profile_age_${user.id}') ?? '';
        _localizacaoController.text =
            prefs.getString('profile_location_${user.id}') ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _idadeController.dispose();
    _localizacaoController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthController>();
    final user = auth.user;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final name = _nomeController.text.trim();
      final sanitizedEmail = _emailController.text.trim().toLowerCase();
      final password = _senhaController.text.trim();
      final age = _idadeController.text.trim();
      final location = _localizacaoController.text.trim();

      final currentEmail = auth.userEmail?.trim().toLowerCase();

      // 1. Update Supabase
      await auth.updateProfile(
        name: name != auth.userName ? name : null,
        email: sanitizedEmail != currentEmail ? sanitizedEmail : null,
        password: password.isNotEmpty ? password : null,
      );

      // 2. Save locally
      final prefs = await SharedPreferences.getInstance();
      if (age.isNotEmpty) {
        await prefs.setString('profile_age_${user.id}', age);
      } else {
        await prefs.remove('profile_age_${user.id}');
      }

      if (location.isNotEmpty) {
        await prefs.setString('profile_location_${user.id}', location);
      } else {
        await prefs.remove('profile_location_${user.id}');
      }

      if (mounted) {
        String successMessage = 'Perfil atualizado com sucesso!';
        if (sanitizedEmail != currentEmail) {
          successMessage =
              'Perfil atualizado! Verifique seu novo email para confirmar a alteração.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
        Navigator.of(context).pop(true);
      }
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage = e.message;
        if (e.message.contains('email_address_invalid')) {
          errorMessage = 'Por favor, informe um email válido.';
        } else if (e.message.contains('email_exists')) {
          errorMessage = 'Este email já está em uso.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar perfil: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  void _handleCameraButtonTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seleção de foto em breve 📷'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Picture Section
                  _buildProfilePictureSection(colorScheme, textTheme),
                  const SizedBox(height: 32),

                  // Informações Pessoais Section
                  _SectionHeader(label: 'Informações Pessoais'),
                  const SizedBox(height: 16),
                  _buildPersonalInfoSection(colorScheme, textTheme),
                  const SizedBox(height: 32),

                  // Segurança Section
                  _SectionHeader(label: 'Segurança'),
                  const SizedBox(height: 16),
                  _buildSecuritySection(colorScheme, textTheme),
                  const SizedBox(height: 32),

                  // Action Buttons
                  _buildActionButtons(colorScheme),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      children: [
        // Avatar with camera button overlay
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Main avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: const AssetImage(
                'assets/Images/ProfilePicture.png',
              ),
            ),
            // Camera button overlay
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _handleCameraButtonTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.background, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Helper text
        Text(
          'Clique no ícone para alterar a foto',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nome completo
        Text("Nome completo", style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        _LabeledTextField(
          controller: _nomeController,
          label: 'Nome completo',
          icon: Icons.person_outline,
          colorScheme: colorScheme,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'O nome é obrigatório';
            }
            if (value.trim().length < 4) {
              return 'O nome deve ter pelo menos 4 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Email
        Text("Email", style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        _LabeledTextField(
          readOnly: true,
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          colorScheme: colorScheme,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'O email é obrigatório';
            }
            final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value.trim())) {
              return 'Informe um email válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Idade and Localização in a row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Idade", style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  _LabeledTextField(
                    controller: _idadeController,
                    label: 'Idade',
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    colorScheme: colorScheme,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final age = int.tryParse(value);
                        if (age == null || age < 0) {
                          return 'Idade inválida';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Localização",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  _LabeledTextField(
                    controller: _localizacaoController,
                    label: 'Localização',
                    icon: Icons.location_on_outlined,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecuritySection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Password field with visibility toggle
        Text("Alterar senha", style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _senhaController,
            obscureText: _obscurePassword,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (value.length < 6) {
                  return 'A senha deve ter pelo menos 6 caracteres';
                }
                if (!value.contains(RegExp(r'[A-Z]'))) {
                  return 'A senha deve conter pelo menos uma letra maiúscula';
                }
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Nova senha (opcional)',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(Icons.lock_outline, color: colorScheme.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Helper text
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            'Deixe em branco para manter a senha atual',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Column(
      children: [
        // Primary button - Salvar Alterações
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Salvar Alterações',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary button - Cancelar
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _handleCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// Section Header Widget with vertical accent bar
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Vertical accent bar
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        // Section title
        Text(
          label,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onBackground,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

// Labeled TextField Widget
class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.colorScheme,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final ColorScheme colorScheme;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        readOnly: readOnly,
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(icon, color: colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
