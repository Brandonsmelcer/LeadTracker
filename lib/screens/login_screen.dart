import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/vl_logo.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _inviteCodeCtrl = TextEditingController();
  bool _loading = false;
  bool _isSignUp = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _inviteCodeCtrl.dispose();
    super.dispose();
  }

  String _formatError(Object e) {
    final message = e.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthService>();
      final app = context.read<AppProvider>();

      if (_isSignUp) {
        final inviteCode = _inviteCodeCtrl.text.trim();
        if (inviteCode.isEmpty) {
          throw Exception(AuthService.invalidInviteMessage);
        }
        await auth.signUpWithInviteCode(
          name: _nameCtrl.text,
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          inviteCode: inviteCode,
          app: app,
        );
      } else {
        await auth.signInWithEmail(
          _emailCtrl.text,
          _passwordCtrl.text,
          app,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() => _error = _formatError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _error = null;
    });
  }

  Future<void> _debugLogin(UserRole role) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthService>();
      final app = context.read<AppProvider>();
      await auth.debugSignInAs(role, app);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() => _error = _formatError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const VlBrandingRow(logoHeight: 48),
                  const SizedBox(height: 32),
                  Text(
                    _isSignUp ? 'Create Account' : 'Sign In',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isSignUp) ...[
                    TextField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      helperText: _isSignUp
                          ? 'At least 6 characters'
                          : null,
                      helperStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _loading ? null : _submit(),
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _inviteCodeCtrl,
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Invite Code',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.accent),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loading ? null : _toggleMode,
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Sign In'
                          : 'Need an account? Sign Up',
                      style: const TextStyle(color: AppColors.gold),
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 32),
                    const Divider(color: AppColors.countyBorder),
                    const SizedBox(height: 16),
                    const Text(
                      'DEBUG QUICK LOGIN',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Creates test accounts on first tap if Firebase is configured.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _debugButton('Login as Admin', UserRole.admin),
                        _debugButton('Login as Manager', UserRole.manager),
                        _debugButton('Login as Associate', UserRole.associate),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _debugButton(String label, UserRole role) {
    return TextButton(
      onPressed: _loading ? null : () => _debugLogin(role),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
