import 'dart:io';

import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/user_provider.dart';
import 'package:cordis/routes/app_routes.dart';
import 'package:cordis/screens/user/register_screen.dart';
import 'package:cordis/screens/user/share_code_screen.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/common/labeled_text_field.dart';
import 'package:flutter/material.dart';
import 'package:cordis/providers/my_auth_provider.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleObscure() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Consumer<MyAuthProvider>(
        builder: (context, authProvider, child) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              spacing: 24,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40),
                Image.asset(
                  'assets/logos/app_icon_rounded.png',
                  width: 150,
                  height: 150,
                ),
                Text(
                  AppLocalizations.of(context)!.logInTitlePrefix +
                      AppLocalizations.of(context)!.appName,
                  style: textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),

                // EMAIL
                LabeledTextField(
                  controller: _emailController,
                  label: AppLocalizations.of(context)!.email,
                  prefixIcon: Icon(Icons.email, color: colorScheme.shadow),
                ),

                // PASSWORD
                LabeledTextField(
                  label: AppLocalizations.of(context)!.password,
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: Icon(Icons.lock, color: colorScheme.shadow),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: colorScheme.shadow,
                    ),
                    onPressed: _toggleObscure,
                  ),
                ),
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 0,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // TODO:auth - ResetPassword
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.amberAccent,
                              content: Text(
                                'Funcionalidade em desenvolvimento,',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          );
                          // Navigator.of(context).push(
                          //   MaterialPageRoute(
                          //     builder: (context) {
                          //       return PasswordResetScreen(
                          //         loginEmail: _emailController.text,
                          //       );
                          //     },
                          //   ),
                          // );
                        },
                        child: Text(
                          AppLocalizations.of(context)!.forgotPassword,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(AppLocalizations.of(context)!.forgotPasswordSuffix),
                    ],
                  ),
                ),
                if (authProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(),
                  ),
                if (authProvider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      authProvider.error!,
                      style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    FilledTextButton(
                      text: AppLocalizations.of(context)!.login,
                      isDark: true,
                      isDisabled: authProvider.isLoading,
                      onPressed: () => _emailSignIn(),
                    ),
                    FilledTextButton(
                      text: AppLocalizations.of(context)!.enterShareCode,
                      onPressed: () async {
                        await authProvider.signInAnonymously();
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ShareCodeScreen(
                                onBack: (context) {
                                  authProvider.signOut();
                                  Navigator.of(context).pop();
                                },
                                onSuccess: (context) {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    AppRoutes.main,
                                    (route) => false,
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),

                // Sign Up Link
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.accountCreationPrefix,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.accountCreationSuffix,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                // Google Sign-In Button - remove on iOS
                if (!Platform.isIOS)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.g_mobiledata, size: 24),
                      label: Text(
                        'Entrar com Google',
                        style: textTheme.labelLarge,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondaryContainer,
                        foregroundColor: colorScheme.onSecondaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _googleSignIn,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _emailSignIn() async {
    final authProvider = context.read<MyAuthProvider>();
    final userProvider = context.read<UserProvider>();

    await authProvider.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (authProvider.isAuthenticated) {
      // Load users after successful login
      await userProvider.loadUsers();
      await userProvider.ensureUserExists(authProvider.id!);

      authProvider.setUserData(
        userProvider.getUserByFirebaseId(authProvider.id!)!,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.main);
      }
    }
  }

  void _googleSignIn() async {
    final authProvider = context.read<MyAuthProvider>();
    final userProvider = context.read<UserProvider>();

    await authProvider.signInWithGoogle();
    if (authProvider.isAuthenticated) {
      // Load users after successful login
      await userProvider.loadUsers();
      await userProvider.ensureUserExists(authProvider.id!);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.main);
      }
      authProvider.setUserData(
        userProvider.getUserByFirebaseId(authProvider.id!)!,
      );
    }
  }
}
