import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  final Function(AppUser) onAuthenticated;
  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _error;
  UserRole _selectedRole = UserRole.associate;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      AppUser? user;
      if (_isLogin) {
        user = await _authService.signIn(
            _emailCtrl.text.trim(), _passwordCtrl.text);
      } else {
        user = await _authService.signUp(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          _nameCtrl.text.trim(),
          _selectedRole,
        );
      }
      if (user != null && mounted) {
        widget.onAuthenticated(user);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 3),
                  ),
                  child: const Icon(Icons.visibility,
                      color: AppColors.gold, size: 48),
                ),
                const SizedBox(height: 16),
                const Text('VISION TO LEGACY',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3)),
                const Text('Lead Tracker',
                    style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 14,
                        letterSpacing: 1)),
                const SizedBox(height: 40),
                Text(_isLogin ? 'Sign In' : 'Create Account',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                if (!_isLogin) ...[
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person, color: AppColors.textSecondary),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: AppColors.textSecondary),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: AppColors.textSecondary),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                if (!_isLogin) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    initialValue: _selectedRole,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon:
                          Icon(Icons.badge, color: AppColors.textSecondary),
                    ),
                    items: UserRole.values
                        .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.name[0].toUpperCase() + r.name.substring(1))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedRole = v);
                    },
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: AppColors.accent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.accent, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isLogin ? 'Sign In' : 'Create Account',
                            style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() {
                    _isLogin = !_isLogin;
                    _error = null;
                  }),
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign Up"
                        : 'Already have an account? Sign In',
                    style: const TextStyle(color: AppColors.gold),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    final offlineUser = AppUser(
                      name: 'Master Admin',
                      role: UserRole.master,
                      avatarColor: '#E94560',
                    );
                    widget.onAuthenticated(offlineUser);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.countyBorder),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                  ),
                  child: const Text('Continue Offline (Demo Mode)',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
