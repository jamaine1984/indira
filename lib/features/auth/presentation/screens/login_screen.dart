import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/services/auth_service.dart';
import 'package:indira_love/features/auth/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        context.go('/discover');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Temporarily disabled due to AppCheckCore dependency conflict
  // Future<void> _signInWithGoogle() async {
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     await ref.read(authProvider.notifier).signInWithGoogle();
  //
  //     if (mounted) {
  //       context.go('/discover');
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(e.toString()),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.romanticGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  IconButton(
                    onPressed: () => context.go('/welcome'),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Sign in to continue your journey',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppTheme.textCharcoal, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.95),
                      labelStyle: TextStyle(color: AppTheme.secondaryPlum.withOpacity(0.8)),
                      prefixIcon: const Icon(
                        Icons.email,
                        color: AppTheme.secondaryPlum,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppTheme.textCharcoal, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.95),
                      labelStyle: TextStyle(color: AppTheme.secondaryPlum.withOpacity(0.8)),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: AppTheme.secondaryPlum,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: AppTheme.secondaryPlum,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Sign In',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Google Sign In - Temporarily disabled due to AppCheckCore dependency conflict
                  // SizedBox(
                  //   width: double.infinity,
                  //   height: 56,
                  //   child: OutlinedButton(
                  //     onPressed: _isLoading ? null : _signInWithGoogle,
                  //     style: OutlinedButton.styleFrom(
                  //       side: const BorderSide(color: Colors.white, width: 2),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(28),
                  //       ),
                  //     ),
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         Image.asset(
                  //           'assets/icons/google.png',
                  //           height: 24,
                  //           width: 24,
                  //           errorBuilder: (context, error, stackTrace) =>
                  //               const Icon(Icons.g_mobiledata, color: Colors.white),
                  //         ),
                  //         const SizedBox(width: 12),
                  //         const Text(
                  //           'Continue with Google',
                  //           style: TextStyle(
                  //             color: Colors.white,
                  //             fontSize: 16,
                  //             fontWeight: FontWeight.w600,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),

                  const SizedBox(height: 32),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                      TextButton(
                        onPressed: () => context.go('/signup'),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await AuthService().resetPassword(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
