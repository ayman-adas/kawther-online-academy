import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/utils/error_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/login_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!context.mounted) return;

      if (authProvider.error != null) {
        if (!context.mounted) return;
        AppErrorHandler.showErrorToast(context, authProvider.error!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Responsive Layout using constrained box
    return ChangeNotifierProvider(
      create: (_) => LoginProvider(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Consumer2<AuthProvider, LoginProvider>(
                builder: (context, auth, loginProvider, child) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo / Brand
                        const Icon(
                          Icons.school_rounded,
                          size: 80,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.appTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.secureLearningEnv,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 48),

                        // Username (Email)
                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          ],
                          decoration: InputDecoration(
                            labelText: l10n.username,
                            prefixIcon: const Icon(Icons.person_outline),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.enterUsername;
                            }
                            // Basic email regex
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !loginProvider.isPasswordVisible,
                          keyboardType: TextInputType.visiblePassword,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: IconButton(
                              icon: Icon(
                                loginProvider.isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                loginProvider.togglePasswordVisibility();
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.enterPassword;
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: auth.isLoading
                                ? null
                                : () => _handleLogin(context),
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n.loginButton),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Registration Button (controlled by Firestore settings/registration doc)
                        StreamBuilder<DocumentSnapshot>(
                          stream: Firebase.apps.isNotEmpty
                              ? FirebaseFirestore.instance
                                  .collection('settings')
                                  .doc('registration')
                                  .snapshots()
                              : null,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return const SizedBox.shrink();
                            }

                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            final showRegister = data?['showRegisterButton'] ?? false;

                            if (!showRegister) {
                              return const SizedBox.shrink();
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: 50,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          final regFormKey = GlobalKey<FormState>();
                                          final nameController = TextEditingController();
                                          final emailController = TextEditingController();
                                          final passController = TextEditingController();
                                          bool isPassObscure = true;
                                          bool isRegistering = false;

                                          return StatefulBuilder(
                                            builder: (context, setDialogState) {
                                              return AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                title: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.school_rounded,
                                                      color: AppColors.primary,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      l10n.studentRegistrationTitle,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                content: SingleChildScrollView(
                                                  child: Form(
                                                    key: regFormKey,
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        TextFormField(
                                                          controller: nameController,
                                                          decoration: InputDecoration(
                                                            labelText: l10n.displayName,
                                                            prefixIcon: const Icon(Icons.person_outline),
                                                          ),
                                                          validator: (value) {
                                                            if (value == null || value.isEmpty) {
                                                              return l10n.required;
                                                            }
                                                            if (value.length < 3) {
                                                              return 'Name must be at least 3 characters';
                                                            }
                                                            return null;
                                                          },
                                                        ),
                                                        const SizedBox(height: 16),
                                                        TextFormField(
                                                          controller: emailController,
                                                          keyboardType: TextInputType.emailAddress,
                                                          inputFormatters: [
                                                            FilteringTextInputFormatter.deny(RegExp(r'\s')),
                                                          ],
                                                          decoration: InputDecoration(
                                                            labelText: l10n.email,
                                                            prefixIcon: const Icon(Icons.email_outlined),
                                                          ),
                                                          validator: (value) {
                                                            if (value == null || value.isEmpty) {
                                                              return l10n.required;
                                                            }
                                                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                                              return 'Please enter a valid email';
                                                            }
                                                            return null;
                                                          },
                                                        ),
                                                        const SizedBox(height: 16),
                                                        TextFormField(
                                                          controller: passController,
                                                          obscureText: isPassObscure,
                                                          keyboardType: TextInputType.visiblePassword,
                                                          decoration: InputDecoration(
                                                            labelText: l10n.password,
                                                            prefixIcon: const Icon(Icons.lock_outline),
                                                            suffixIcon: IconButton(
                                                              icon: Icon(
                                                                isPassObscure
                                                                    ? Icons.visibility_off_outlined
                                                                    : Icons.visibility_outlined,
                                                              ),
                                                              onPressed: () {
                                                                setDialogState(() {
                                                                  isPassObscure = !isPassObscure;
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                          validator: (value) {
                                                            if (value == null || value.isEmpty) {
                                                              return l10n.required;
                                                            }
                                                            if (value.length < 6) {
                                                              return 'Password must be at least 6 characters';
                                                            }
                                                            return null;
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: isRegistering
                                                        ? null
                                                        : () => Navigator.pop(context),
                                                    child: Text(l10n.cancel),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: isRegistering
                                                        ? null
                                                        : () async {
                                                            if (regFormKey.currentState!.validate()) {
                                                              setDialogState(() {
                                                                isRegistering = true;
                                                              });
                                                              try {
                                                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                                                await authProvider.registerStudent(
                                                                  emailController.text.trim(),
                                                                  passController.text.trim(),
                                                                  nameController.text.trim(),
                                                                );
                                                                if (context.mounted) {
                                                                  Navigator.pop(context);
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    SnackBar(
                                                                      content: Text(l10n.registerSuccess),
                                                                      backgroundColor: AppColors.success,
                                                                    ),
                                                                  );
                                                                }
                                                              } catch (e) {
                                                                setDialogState(() {
                                                                  isRegistering = false;
                                                                });
                                                                if (context.mounted) {
                                                                  AppErrorHandler.showErrorToast(context, e.toString());
                                                                }
                                                              }
                                                            }
                                                          },
                                                    child: isRegistering
                                                        ? const SizedBox(
                                                            height: 20,
                                                            width: 20,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color: Colors.white,
                                                            ),
                                                          )
                                                        : Text(l10n.register),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.register,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
