import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/screens/user/share_code_screen.dart';
import 'package:cordis/widgets/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:cordis/providers/my_auth_provider.dart';
import 'package:cordis/providers/user_provider.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late final MyAuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    // Listen for authentication changes after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider = context.read<MyAuthProvider>();
      _authProvider.addListener(_authListener);
    });
  }

  void _authListener() {
    if (_authProvider.isAuthenticated && context.mounted) {
      _authProvider.removeListener(_authListener); // Prevent multiple calls
      context.read<UserProvider>().ensureUsersExist([_authProvider.id!]);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authProvider.removeListener(_authListener);
    super.dispose();
  }

  void _toggleObscure() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe o e-mail';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'E-mail inválido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a senha';
    }
    if (value.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                Column(
                  spacing: 8,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofocus: true,
                      maxLines: 1,
                      decoration: InputDecoration(
                        label: Text(AppLocalizations.of(context)!.email),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        prefixIcon: Icon(
                          Icons.email,
                          color: colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      validator: _validateEmail,
                    ),
                  ],
                ),
                Column(
                  spacing: 8,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.password,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      maxLines: 1,
                      decoration: InputDecoration(
                        label: Text(AppLocalizations.of(context)!.password),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        prefixIcon: Icon(
                          Icons.lock,
                          color: colorScheme.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: colorScheme.primary,
                          ),
                          onPressed: _toggleObscure,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      validator: _validatePassword,
                    ),
                    Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 0,
                        children: [
                          GestureDetector(
                            onTap: () {
                              // TODO: ResetPassword
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
                          Text(
                            AppLocalizations.of(context)!.forgotPasswordSuffix,
                          ),
                        ],
                      ),
                    ),
                  ],
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
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          authProvider.signInWithEmail(
                            _emailController.text,
                            _passwordController.text,
                          );
                        }
                      },
                    ),
                    FilledTextButton(
                      text: AppLocalizations.of(context)!.enterShareCode,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ShareCodeScreen(),
                          ),
                        );
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
                      onTap: () => Navigator.of(context).pushNamed('/signup'),
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
                // Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: Text(
                      'Entrar com Google',
                      style: theme.textTheme.labelLarge!.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.onSecondaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    onPressed: authProvider.isLoading
                        ? null
                        : () => authProvider.signInWithGoogle(),
                  ),
                ),
                // SizedBox(
                //   width: double.infinity,
                //   child: ElevatedButton.icon(
                //     icon: const Icon(Icons.person_outline),
                //     label: Text(
                //       'Entrar Anonimamente',
                //       style: theme.textTheme.labelLarge!.copyWith(
                //         color: colorScheme.onPrimary,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: colorScheme.primary,
                //       foregroundColor: colorScheme.onPrimary,
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(16),
                //       ),
                //       elevation: 2,
                //     ),
                //     onPressed: authProvider.isLoading
                //         ? null
                //         : () => authProvider.signInAnonymously(),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
