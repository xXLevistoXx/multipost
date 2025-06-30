import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multipost/core/constants.dart';
import 'package:multipost/main.dart';
import 'package:multipost/presentation/pages/auth_page.dart';
import 'package:multipost/presentation/pages/auth_tg_page.dart';
import 'package:multipost/presentation/pages/main_auth_screen.dart';
import 'package:multipost/presentation/pages/reddit_auth_page.dart';
import 'package:multipost/presentation/pages/vk_auth_page.dart';
import 'package:multipost/presentation/widgets/bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multipost/presentation/blocs/auth/auth_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? vkToken;
  String? telegramPhone;
  String? telegramUsername;
  String? redditToken;
  String? login;
  bool? telegramAuth;
  bool? vkAuth;
  bool? redditAuth;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final accountId = prefs.getString('account_id');
    setState(() {
      vkToken = prefs.getString('vk_token');
      telegramPhone = prefs.getString('telegram_phone');
      telegramUsername = prefs.getString('telegram_username');
      redditToken = prefs.getString('reddit_token');
      login = prefs.getString('login') ?? 'example@email.com';
    });

    if (accountId != null) {
      final url = Uri.parse('$goBaseUrl/api/user/$accountId');
      try {
        final token = await _getToken();
        print('Requesting user data: $url, token: $token');
        final response = await http.get(
          url,
          headers: {
            'Authorization': token,
            'Content-Type': 'application/json; charset=UTF-8',
          },
        );
        print('ОТВЕТ status: ${response.statusCode}');
        print('ОТВЕТ body: ${response.body}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            telegramAuth = data['telegram_auth'] ?? false;
            vkAuth = data['vk_auth'] ?? false;
            redditAuth = data['reddit_auth'] ?? false;
          });
        } else {
          _showSnackBar('Ошибка загрузки данных пользователя: ${response.statusCode} - ${response.body}', true);
        }
      } catch (e) {
        _showSnackBar('Ошибка связи с сервером: $e', true);
      }
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw Exception('Токен не найден. Пожалуйста, войдите в аккаунт.');
    }
    return 'Bearer $token';
  }

  Future<void> _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final accountId = prefs.getString('account_id');
    if (accountId != null) {
      try {
        final token = await _getToken();
        // Выполняем запросы только для VK и Reddit
        await _updateAuth(accountId, 'reddit', false, token);
        await _updateAuth(accountId, 'vk', false, token);
      } catch (e) {
        _showSnackBar('Ошибка при выходе: $e', true);
      }
    }

    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainAuthScreen()),
      (route) => false,
    );
  }

  Future<void> _disconnect(String platform) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final accountId = prefs.getString('account_id');
    if (accountId == null) {
      _showSnackBar('Не удалось найти account_id', true);
      return;
    }

    if (platform == 'telegram') {
      // Очищаем данные Telegram в SharedPreferences
      await prefs.remove('telegram_phone');
      await prefs.remove('phone');
      await prefs.remove('telegram_username');
      setState(() {
        telegramPhone = null;
        telegramUsername = null;
        telegramAuth = false;
      });
      _showSnackBar('Telegram отключен', false);
      // Переходим на страницу авторизации Telegram
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: BlocProvider.of<AuthBloc>(context),
            child: const AuthTgPage(),
          ),
        ),
      );
      return;
    }

    // Для других платформ (VK, Reddit) выполняем запрос к бэкенду
    final url = Uri.parse('$goBaseUrl/api/auth/$platform');
    try {
      final token = await _getToken();
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': token,
        },
        body: jsonEncode({
          'user_id': accountId,
          'platform': platform,
          'auth': false,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка отключения $platform: ${response.statusCode} - ${response.body}');
      }

      if (platform == 'vk') {
        await prefs.remove('vk_token');
        setState(() {
          vkToken = null;
          vkAuth = false;
        });
      } else if (platform == 'reddit') {
        await prefs.remove('reddit_token');
        setState(() {
          redditToken = null;
          redditAuth = false;
        });
      }

      _showSnackBar('$platform отключен', false);
    } catch (e) {
      _showSnackBar('Ошибка отключения $platform: $e', true);
    }
  }

  Future<void> _updateAuth(String userId, String platform, bool auth, String token) async {
    // final url = Uri.parse('$goBaseUrl/api/auth/$platform');
    // final response = await http.put(
    //   url,
    //   headers: {
    //     'Content-Type': 'application/json; charset=UTF-8',
    //     'Authorization': token,
    //   },
    //   body: jsonEncode({
    //     'user_id': userId,
    //     'platform': platform,
    //     'auth': auth,
    //   }),
    // );

    // if (response.statusCode != 200) {
    //   throw Exception('Ошибка обновления $platform: ${response.statusCode} - ${response.body}');
    // }
  }

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

  @override
  Widget build(BuildContext context) {
    final customTheme = Theme.of(context).extension<CustomTheme>()!;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          customTheme.buildBackground(context),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/images/Marlo21.png',
                    height: 40,
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Добавьте аккаунты',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Здесь вы можете войти или выйти из своих учетных записей',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromRGBO(230, 230, 230, 1),
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      height: 1.43,
                    ),
                  ),
                  Center(
                    child: Image.asset(
                      'assets/images/judy_mascot.png',
                      width: 200,
                      height: 200,
                    ),
                  ),
                  if (login != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      login!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Ваши аккаунты',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSocialButton(
                    text: vkToken != null ? 'https://vk.com' : 'Подключить VK',
                    color: const Color(0xFF0277FF),
                    iconPath: 'assets/icons/vk_icon.svg',
                    isConnected: vkAuth ?? false,
                    onPressed: vkToken != null
                        ? () => _disconnect('vk')
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VkAuthPage(),
                              ),
                            );
                          },
                    disconnectIcon: vkToken != null,
                  ),
                  const SizedBox(height: 16),
                  _buildSocialButton(
                    text: telegramUsername != null
                        ? 'https://t.me/$telegramUsername'
                        : 'Подключить Telegram',
                    color: const Color(0xFF2395E5),
                    iconPath: 'assets/icons/telegram_icon.svg',
                    isConnected: telegramAuth ?? false,
                    onPressed: telegramUsername != null
                        ? () => _disconnect('telegram')
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlocProvider.value(
                                  value: BlocProvider.of<AuthBloc>(context),
                                  child: const AuthTgPage(),
                                ),
                              ),
                            );
                          },
                    disconnectIcon: telegramUsername != null,
                  ),
                  const SizedBox(height: 16),
                  _buildSocialButton(
                    text: redditToken != null 
                    ? 'https://reddit.com' 
                    : 'Подключить Reddit',
                    color: const Color(0xFFFF4500),
                    iconPath: 'assets/icons/reddit_icon.svg',
                    isConnected: redditAuth ?? false,
                    onPressed: redditToken != null
                        ? () => _disconnect('reddit')
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RedditAuthPage(),
                              ),
                            );
                          },
                    disconnectIcon: redditToken != null,
                  ),
                  const Spacer(),
                  Center(
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD20C34),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Выйти',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomBar(),
    );
  }

  Widget _buildSocialButton({
    required String text,
    required Color color,
    required String iconPath,
    required bool isConnected,
    required VoidCallback onPressed,
    required bool disconnectIcon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              height: 24,
              width: 24,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Montserrat',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            SvgPicture.asset(
              isConnected
                  ? 'assets/icons/connected_icon.svg'
                  : 'assets/icons/disconnected_icon.svg',
              height: 24,
              width: 24,
            ),
            if (disconnectIcon) ...[
              const SizedBox(width: 10),
              SvgPicture.asset(
                'assets/icons/logout_icon.svg',
                height: 24,
                width: 24,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ],
          ],
        ),
      ),
    );
  }
}