import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multipost/core/constants.dart';
import 'package:multipost/main.dart';
import 'package:multipost/presentation/blocs/auth/auth_bloc.dart';
import 'package:multipost/presentation/pages/auth_tg_page.dart';
import 'package:multipost/presentation/pages/home_page.dart';
import 'package:multipost/presentation/pages/reddit_auth_page.dart';
import 'package:multipost/presentation/pages/vk_auth_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  String? vkToken;
  String? telegramPhone;
  String? redditToken;

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      vkToken = prefs.getString('vk_token');
      telegramPhone = prefs.getString('telegram_phone');
      redditToken = prefs.getString('reddit_token');
    });
  }

  @override
  Widget build(BuildContext context) {
    final customTheme = Theme.of(context).extension<CustomTheme>()!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          customTheme.buildBackground(context),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.16),
                    child: Image.asset(
                      'assets/images/Marlo21.png',
                      width: logoWidth,
                      height: logoHeight,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Text(
                      'Подключите свои аккаунты',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                        fontSize: screenWidth * 0.051,
                        height: 1.86,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Text(
                      'Публикуйте новости одновременно в нескольких соцсетях',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color.fromRGBO(230, 230, 230, 1),
                        fontFamily: 'Montserrat',
                        fontSize: screenWidth * 0.033,
                        height: 1.43,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.1),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: ElevatedButton(
                      onPressed: vkToken != null
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const VkAuthPage(),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0277FF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: buttonHorizontalPadding,
                          vertical: buttonVerticalPadding,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(buttonBorderRadius),
                        ),
                        minimumSize: Size(screenWidth * 0.92, buttonHeight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/vk_icon.svg',
                            width: iconSize,
                            height: iconSize,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vkToken != null ? 'VK подключен' : 'Войти через VK',
                            style: TextStyle(
                              color: const Color.fromRGBO(230, 230, 230, 1),
                              fontFamily: 'Montserrat',
                              fontSize: screenWidth * 0.033,
                              height: 1.57,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.021),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: ElevatedButton(
                      onPressed: telegramPhone != null
                          ? null
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2395E5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: buttonHorizontalPadding,
                          vertical: buttonVerticalPadding,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(buttonBorderRadius),
                        ),
                        minimumSize: Size(screenWidth * 0.92, buttonHeight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/telegram_icon.svg',
                            width: iconSize,
                            height: iconSize,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            telegramPhone != null ? 'Telegram подключен' : 'Войти через Telegram',
                            style: TextStyle(
                              color: const Color.fromRGBO(230, 230, 230, 1),
                              fontFamily: 'Montserrat',
                              fontSize: screenWidth * 0.033,
                              height: 1.57,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.021),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: ElevatedButton(
                      onPressed: redditToken != null
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RedditAuthPage(),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4500),
                        padding: const EdgeInsets.symmetric(
                          horizontal: buttonHorizontalPadding,
                          vertical: buttonVerticalPadding,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(buttonBorderRadius),
                        ),
                        minimumSize: Size(screenWidth * 0.92, buttonHeight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/reddit_icon.svg',
                            width: iconSize,
                            height: iconSize,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            redditToken != null ? 'Reddit подключен' : 'Войти через Reddit',
                            style: TextStyle(
                              color: const Color.fromRGBO(230, 230, 230, 1),
                              fontFamily: 'Montserrat',
                              fontSize: screenWidth * 0.033,
                              height: 1.57,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Text(
                      'Нажимая на кнопку, вы соглашаетесь с нашей Политикой конфиденциальности',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color.fromRGBO(230, 230, 230, 0.6),
                        fontFamily: 'Montserrat',
                        fontSize: screenWidth * 0.026,
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}