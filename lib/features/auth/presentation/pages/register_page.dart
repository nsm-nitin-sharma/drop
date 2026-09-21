import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/monochrome_button.dart';
import '../../../../core/widgets/monochrome_text_field.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _handleController = TextEditingController();

  bool _obscurePassword = true;
  Timer? _debounceTimer;
  bool _isCheckingHandle = false;
  bool? _isHandleAvailable;
  String? _handleStatusMessage;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  void _onHandleChanged(String value) {
    _debounceTimer?.cancel();
    final cleanHandle = value.trim().toLowerCase();

    if (cleanHandle.isEmpty) {
      setState(() {
        _isCheckingHandle = false;
        _isHandleAvailable = null;
        _handleStatusMessage = null;
      });
      return;
    }

    if (!AppConstants.handleRegex.hasMatch(cleanHandle)) {
      setState(() {
        _isCheckingHandle = false;
        _isHandleAvailable = false;
        _handleStatusMessage = 'Handle must be 3-20 characters (a-z, 0-9, _ only)';
      });
      return;
    }

    setState(() {
      _isCheckingHandle = true;
      _isHandleAvailable = null;
      _handleStatusMessage = 'Checking availability...';
    });

    _debounceTimer = Timer(const Duration(milliseconds: 450), () async {
      try {
        final authRepo = context.read<AuthRepository>();
        final available = await authRepo.isHandleAvailable(cleanHandle);
        if (mounted) {
          setState(() {
            _isCheckingHandle = false;
            _isHandleAvailable = available;
            _handleStatusMessage = available
                ? 'Handle @$cleanHandle is available'
                : 'Handle @$cleanHandle is already taken';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isCheckingHandle = false;
            _isHandleAvailable = false;
            _handleStatusMessage = 'Unable to verify handle availability';
          });
        }
      }
    });
  }

  void _onRegisterSubmitted() {
    if (_isHandleAvailable != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose an available handle (@username)'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthSignUpRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              handle: _handleController.text.trim(),
              displayName: _displayNameController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.errorRed,
              ),
            );
          } else if (state is Authenticated) {
            Navigator.pop(context);
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Join Drop',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Claim your unique handle and start sharing.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 32),

                      // Glass Card Form
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor, width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display Name
                            MonochromeTextField(
                              controller: _displayNameController,
                              label: 'Display Name',
                              hint: 'Nitin Sharma',
                              prefixIcon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your display name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Handle (@username) with Real-time Check
                            MonochromeTextField(
                              controller: _handleController,
                              label: 'Handle (@username)',
                              hint: 'nitin_sharma',
                              prefixText: '@',
                              onChanged: _onHandleChanged,
                              suffixIcon: _buildHandleSuffixIcon(isDark),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please choose a handle';
                                }
                                if (!AppConstants.handleRegex.hasMatch(value.trim())) {
                                  return 'Handle must be 3-20 characters (letters, numbers, _ only)';
                                }
                                if (_isHandleAvailable == false) {
                                  return 'Handle is already taken';
                                }
                                return null;
                              },
                            ),
                            if (_handleStatusMessage != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    _isHandleAvailable == true
                                        ? Icons.check_circle_outline
                                        : _isCheckingHandle
                                            ? Icons.access_time
                                            : Icons.error_outline,
                                    size: 14,
                                    color: _isHandleAvailable == true
                                        ? AppColors.successGreen
                                        : _isCheckingHandle
                                            ? textSecondary
                                            : AppColors.errorRed,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _handleStatusMessage!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: _isHandleAvailable == true
                                            ? AppColors.successGreen
                                            : _isCheckingHandle
                                                ? textSecondary
                                                : AppColors.errorRed,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),

                            // Email
                            MonochromeTextField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'name@example.com',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password
                            MonochromeTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'Minimum 6 characters',
                              obscureText: _obscurePassword,
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return 'Password must be at least 6 characters long';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            // Sign Up Button
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                return MonochromeButton(
                                  label: 'Create Account',
                                  isLoading: state is AuthLoading,
                                  onPressed: _onRegisterSubmitted,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildHandleSuffixIcon(bool isDark) {
    if (_isCheckingHandle) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? AppColors.white : AppColors.black,
            ),
          ),
        ),
      );
    }
    if (_isHandleAvailable == true) {
      return const Icon(Icons.check_circle, color: AppColors.successGreen, size: 20);
    }
    if (_isHandleAvailable == false) {
      return const Icon(Icons.cancel, color: AppColors.errorRed, size: 20);
    }
    return null;
  }
}
