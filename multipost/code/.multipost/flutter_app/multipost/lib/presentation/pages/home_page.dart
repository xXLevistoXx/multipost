import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multipost/main.dart';
import 'package:multipost/presentation/pages/auth_page.dart';
import 'package:multipost/presentation/pages/channels_page.dart';
import 'package:multipost/presentation/pages/template_page.dart';
import 'package:multipost/presentation/widgets/bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<String?> _loadPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('phone');
  }

  @override
  Widget build(BuildContext context) {
    final customTheme = Theme.of(context).extension<CustomTheme>()!;

    return Scaffold(
      body: FutureBuilder<String?>(
        future: _loadPhone().timeout(const Duration(seconds: 5), onTimeout: () {
          // Если загрузка затянулась, возвращаем null
          return null;
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text(
                  'Ошибка загрузки данных: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          final phone = snapshot.data;

          // Если phone отсутствует, показываем сообщение или перенаправляем
          if (phone == null) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Номер телефона не найден. Пожалуйста, подключите Telegram.',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Перенаправляем на страницу авторизации
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const AuthPage()),
                        );
                      },
                      child: const Text('Вернуться к авторизации'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Если phone загружен, показываем основной экран
          return Stack(
            children: [
              customTheme.buildBackground(context),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Image.asset(
                                  'assets/images/Marlo21.png',
                                  height: 40,
                                ),
                              ],
                            ),
                            const SizedBox(height: 71),
                            const Text(
                              'Выберите действие',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color.fromRGBO(255, 255, 255, 1),
                                fontFamily: 'Montserrat',
                                fontSize: 22,
                                fontWeight: FontWeight.normal,
                                height: 1.86,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Создайте шаблон или опубликуйте пост в соцсетях',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color.fromRGBO(230, 230, 230, 1),
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                height: 1.43,
                              ),
                            ),
                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildCard(
                                  context: context,
                                  svgPath: 'assets/icons/vector_template.svg',
                                  label: 'Создать шаблон',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const TemplatePage(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 20),
                                _buildCard(
                                  context: context,
                                  svgPath: 'assets/icons/vector_post.svg',
                                  label: 'Создать пост',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChannelsPage(phone: phone),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const BottomBar(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String svgPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 210,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(51, 51, 51, 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              svgPath,
              width: 100,
              height: 90,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            const SizedBox(height: 36),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: const Color.fromRGBO(168, 9, 41, 1),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}