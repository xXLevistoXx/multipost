import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multipost/core/constants.dart';
import 'package:multipost/main.dart';
import 'package:multipost/presentation/blocs/auth/auth_bloc.dart';
import 'package:multipost/presentation/blocs/auth/auth_event.dart';
import 'package:multipost/presentation/blocs/auth/auth_state.dart';
import 'package:multipost/presentation/pages/auth_page.dart';
import 'package:flutter/services.dart';
import 'package:multipost/presentation/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthTgPage extends StatefulWidget {
  const AuthTgPage({super.key});

  @override
  State<AuthTgPage> createState() => _AuthTgPageState();
}

class _AuthTgPageState extends State<AuthTgPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  static const double dialogButtonBorderRadius = 8;
  static const double dialogButtonHorizontalPadding = 20;
  static const double dialogButtonVerticalPadding = 10;
  static const double dialogIconSize = 24;
  static const double dialogButtonFontSize = 14;

  @override
  void initState() {
    super.initState();
    // Сбрасываем состояние AuthBloc при входе на страницу
    context.read<AuthBloc>().add(ResetAuthStateEvent());
    // Очищаем контроллеры, чтобы поля были пустыми
    _phoneController.clear();
    _codeController.clear();
    _passwordController.clear();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String> _getLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final login = prefs.getString('login');
    if (login == null || login.isEmpty) {
      throw Exception('Логин не найден. Пожалуйста, войдите в аккаунт.');
    }
    return login;
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw Exception('Токен не найден. Пожалуйста, войдите в аккаунт.');
    }
    return 'Bearer $token';
  }

  Future<bool> _onBackPressed() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.dialogBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.dialogBorder, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/judy_mascot.png',
                  width: 118,
                  height: 112,
                ),
                const SizedBox(height: 12),
                Container(
                  width: 45,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    color: AppColors.dialogDivider,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Прервать авторизацию?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Вы уверены, что хотите прервать процесс авторизации?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Montserrat',
                    fontSize: subtitleFontSize,
                    height: 1.43,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: dialogButtonHorizontalPadding,
                          vertical: dialogButtonVerticalPadding,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dialogButtonCancel,
                          borderRadius: BorderRadius.circular(dialogButtonBorderRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/dialog_icon.svg',
                              width: dialogIconSize,
                              height: dialogIconSize,
                              colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Нет',
                              style: TextStyle(
                                color: AppColors.white,
                                fontFamily: 'Montserrat',
                                fontSize: dialogButtonFontSize,
                                height: 1.43,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const AuthPage()),
                          (route) => false,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: dialogButtonHorizontalPadding,
                          vertical: dialogButtonVerticalPadding,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dialogButtonConfirm,
                          borderRadius: BorderRadius.circular(dialogButtonBorderRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/ok_icon.svg',
                              width: dialogIconSize,
                              height: dialogIconSize,
                              colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Да',
                              style: TextStyle(
                                color: AppColors.white,
                                fontFamily: 'Montserrat',
                                fontSize: dialogButtonFontSize,
                                height: 1.43,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        behavior: SnackBarBehavior.floating,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isError ? AppColors.errorBackground : AppColors.successBackground,
                  border: Border.all(
                    color: isError ? AppColors.errorBorder : AppColors.successBorder,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      isError ? 'assets/icons/error_icon.svg' : 'assets/icons/success_icon.svg',
                      width: iconSize,
                      height: iconSize,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'Montserrat',
                          fontSize: subtitleFontSize,
                          height: 1.5,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customTheme = Theme.of(context).extension<CustomTheme>()!;
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: Stack(
          children: [
            customTheme.buildBackground(context),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: fieldHorizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/Marlo21.png',
                            height: 40,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                                onPressed: _onBackPressed,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Назад',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: BlocConsumer<AuthBloc, AuthState>(
                        listener: (context, state) async {
                          if (state is AuthError) {
                            _showSnackBar(state.message, true);
                          } else if (state is AuthVerified) {
                            _showSnackBar('Авторизация успешна', false);
                            // Обновляем TelegramAuth в бэкенде
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const HomePage()),
                              (route) => false,
                            );
                          }
                        },
                        builder: (context, state) {
                          final isCodeSent = state is AuthCodeSent || state is AuthVerified;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              Text(
                                isCodeSent ? 'Введите код и пароль' : 'Введите номер телефона',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontFamily: 'Montserrat',
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isCodeSent
                                    ? 'Введите код, отправленный вам, и пароль (если требуется)'
                                    : 'Введите ваш номер телефона для авторизации',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontFamily: 'Montserrat',
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 40),
                              TextField(
                                controller: _phoneController,
                                enabled: !isCodeSent,
                                decoration: InputDecoration(
                                  labelText: 'Номер телефона',
                                  labelStyle: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontFamily: 'Montserrat',
                                    fontSize: fieldFontSize,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: AppColors.borderDefault),
                                    borderRadius: BorderRadius.circular(buttonBorderRadius),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: AppColors.white),
                                    borderRadius: BorderRadius.circular(buttonBorderRadius),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: AppColors.borderDefault),
                                    borderRadius: BorderRadius.circular(buttonBorderRadius),
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                ),
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontFamily: 'Montserrat',
                                  fontSize: fieldFontSize,
                                ),
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                                ],
                              ),
                              if (isCodeSent) ...[
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _codeController,
                                  decoration: InputDecoration(
                                    labelText: 'Код',
                                    labelStyle: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Montserrat',
                                      fontSize: fieldFontSize,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: AppColors.borderDefault),
                                      borderRadius: BorderRadius.circular(buttonBorderRadius),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: AppColors.white),
                                      borderRadius: BorderRadius.circular(buttonBorderRadius),
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontFamily: 'Montserrat',
                                    fontSize: fieldFontSize,
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Пароль',
                                    labelStyle: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Montserrat',
                                      fontSize: fieldFontSize,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: AppColors.borderDefault),
                                      borderRadius: BorderRadius.circular(buttonBorderRadius),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: AppColors.white),
                                      borderRadius: BorderRadius.circular(buttonBorderRadius),
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontFamily: 'Montserrat',
                                    fontSize: fieldFontSize,
                                  ),
                                  obscureText: true,
                                ),
                              ],
                              const Spacer(),
                              if (state is AuthLoading)
                                const CircularProgressIndicator(
                                  color: Color(0xFFA80A2A),
                                )
                              else if (isCodeSent)
                                ElevatedButton(
                                  onPressed: () async {
                                    if (_codeController.text.isEmpty) {
                                      _showSnackBar('Код не может быть пустым', true);
                                      return;
                                    }
                                    try {
                                      final login = await _getLogin();
                                      context.read<AuthBloc>().add(VerifyCodeEvent(
                                            _phoneController.text,
                                            _codeController.text,
                                            _passwordController.text.isEmpty
                                                ? null
                                                : _passwordController.text,
                                            login: login,
                                          ));
                                    } catch (e) {
                                      _showSnackBar(e.toString(), true);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryRed,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: buttonHorizontalPadding,
                                      vertical: buttonVerticalPadding,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(buttonBorderRadius),
                                    ),
                                    minimumSize: const Size(double.infinity, buttonHeight),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Подтвердить',
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontFamily: 'Montserrat',
                                          fontSize: subtitleFontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SvgPicture.asset(
                                        'assets/icons/send_icon.svg',
                                        width: iconSize,
                                        height: iconSize,
                                        colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ElevatedButton(
                                  onPressed: () async {
                                    final phone = _phoneController.text;
                                    if (!RegExp(phoneNumberPattern).hasMatch(phone)) {
                                      _showSnackBar('Неверный формат номера телефона, начните с +7', true);
                                      return;
                                    }
                                    try {
                                      final login = await _getLogin();
                                      context.read<AuthBloc>().add(RequestCodeEvent(
                                            phone,
                                            login: login,
                                          ));
                                    } catch (e) {
                                      _showSnackBar(e.toString(), true);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryRed,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: buttonHorizontalPadding,
                                      vertical: buttonVerticalPadding,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(buttonBorderRadius),
                                    ),
                                    minimumSize: const Size(double.infinity, buttonHeight),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Отправить',
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontFamily: 'Montserrat',
                                          fontSize: subtitleFontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SvgPicture.asset(
                                        'assets/icons/send_icon.svg',
                                        width: iconSize,
                                        height: iconSize,
                                        colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                                      ),
                                    ],
                                  ),
                                ),
                              const Spacer(),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}