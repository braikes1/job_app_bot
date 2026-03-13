import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await ref.read(authProvider.notifier).register(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          _nameCtrl.text.trim(),
        );
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider).valueOrNull;

    if (authState?.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authState!.error!), backgroundColor: AppTheme.error),
        );
      });
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                IconButton(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),

                const SizedBox(height: 24),

                Text('Create Account', style: theme.textTheme.displayMedium)
                    .animate().fadeIn().slideY(begin: 0.2),

                const SizedBox(height: 8),

                Text(
                  'Start applying smarter today',
                  style: theme.textTheme.bodyMedium,
                ).animate(delay: 100.ms).fadeIn(),

                const SizedBox(height: 32),

                AppTextField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  hint: 'Jane Smith',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Required',
                ).animate(delay: 150.ms).fadeIn().slideX(begin: -0.1),

                const SizedBox(height: 16),

                AppTextField(
                  controller: _emailCtrl,
                  label: 'Email Address',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.1),

                const SizedBox(height: 16),

                AppTextField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  hint: 'Min 6 characters',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 characters',
                ).animate(delay: 250.ms).fadeIn().slideX(begin: -0.1),

                const SizedBox(height: 16),

                AppTextField(
                  controller: _confirmCtrl,
                  label: 'Confirm Password',
                  hint: '••••••••',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) => v == _passwordCtrl.text ? null : 'Passwords do not match',
                ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.1),

                const SizedBox(height: 32),

                AppButton(
                  label: 'Create Account',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.2),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ', style: theme.textTheme.bodySmall),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
