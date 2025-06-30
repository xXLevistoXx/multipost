import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:multipost/core/constants.dart';
import 'package:multipost/main.dart';
import 'package:multipost/presentation/pages/auth_page.dart';
import 'package:multipost/presentation/pages/admin_dashboard_page.dart';

class MainAuthScreen extends StatefulWidget {
  const MainAuthScreen({super.key});

  @override
  State<MainAuthScreen> createState() => _MainAuthScreenState();
}

class _MainAuthScreenState extends State<MainAuthScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isError ? const Color(0xFFF44336) : const Color(0xFF4CAF50),
                  border: Border.all(
                    color: isError ? const Color(0xFFD32F2F) : const Color(0xFF388E3C),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isError ? Icons.error : Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                          fontSize: 14,
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

  Future<void> _registerOrLogin() async {
    setState(() {
      _isLoading = true;
    });

    final login = _loginController.text.trim();
    final password = _passwordController.text.trim();

    if (login.isEmpty || password.isEmpty) {
      _showSnackBar('Введите логин и пароль', true);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final url = _isLogin
          ? Uri.parse('$goBaseUrl/login')
          : Uri.parse('$goBaseUrl/register');
      print('Sending request to: $url');
      print('Request body: ${jsonEncode({'login': login, 'password': password})}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'login': login,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accountId = data['user']?['id']?.toString() ?? '';
        final token = data['token']?.toString() ?? '';
        final role = data['user']?['role']?.toString() ?? 'User'; // По умолчанию "User"
        print('АККАУНТ accountId: $accountId'); // Отладка
        if (accountId.isEmpty) {
          throw Exception('Account ID не получен');
        }
        if (token.isEmpty) {
          throw Exception('Токен не получен');
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('account_id', accountId);
        await prefs.setString('login', login);
        await prefs.setString('role', role);
        final cleanToken = token.startsWith('Bearer ') ? token.substring(7) : token;
        print('Saving token to SharedPreferences: $cleanToken');
        await prefs.setString('token', cleanToken);
        final savedAccountId = prefs.getString('account_id');
        final savedToken = prefs.getString('token');
        print('Saved account_id: $savedAccountId');
        print('Saved token: $savedToken');
        _showSnackBar(
            _isLogin ? 'Успешный вход' : 'Успешная регистрация', false);

        if (role == 'Admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AuthPage()),
          );
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Ошибка авторизации: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar(e.toString(), true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customTheme = Theme.of(context).extension<CustomTheme>()!;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          customTheme.buildBackground(context),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Image.asset(
                    'assets/images/Marlo21.png',
                    height: 40,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _isLogin ? 'Вход' : 'Зарегистрируйте аккаунт',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontSize: screenWidth * 0.051,
                      height: 1.86,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Введите логин и пароль вашего пользователя',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _loginController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Логин',
                      labelStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: Color.fromARGB(51, 0, 0, 0),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Пароль',
                      labelStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: Color.fromARGB(51, 0, 0, 0),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryRed,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _registerOrLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            minimumSize: const Size(double.infinity, 56),
                          ),
                          child: Text(
                            _isLogin ? 'Войти' : 'Зарегистрироваться',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Montserrat',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                      child: Text(
                        _isLogin
                            ? 'Нет аккаунта? Зарегистрируйтесь!'
                            : 'Уже есть аккаунт? Войдите!',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}