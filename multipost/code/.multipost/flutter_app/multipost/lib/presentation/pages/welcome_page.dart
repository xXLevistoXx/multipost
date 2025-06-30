import 'package:flutter/material.dart';
import 'package:multipost/core/constants.dart';
import 'package:multipost/main.dart';
import 'package:multipost/presentation/pages/main_auth_screen.dart'; // Импортируем MainAuthScreen

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final customTheme = Theme.of(context).extension<CustomTheme>()!;
    
    // Получаем размеры экрана для адаптивности
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Фон с градиентом и эллипсами из темы
          customTheme.buildBackground(context),
          // Основной контент
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Логотип MARLO.
                  Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.15),
                    child: Image.asset(
                      'assets/images/Marlo21.png',
                      width: logoWidth,
                      height: logoHeight,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  // Заголовок "Multipost"
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Text(
                      'Multipost',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                        fontSize: screenWidth * 0.08,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Подзаголовок
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Text(
                      'Управляйте всеми соцсетями в одном месте',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color.fromRGBO(230, 230, 230, 1),
                        fontFamily: 'Montserrat',
                        fontSize: screenWidth * 0.033,
                        height: 1.43,
                      ),
                    ),
                  ),
                  const Spacer(), // Растягиваем пространство до иллюстрации и кнопки
                  // Иллюстрация
                  Image.asset(
                    'assets/images/welcome_illustration.png',
                    width: illustrationWidth,
                    fit: BoxFit.fitWidth,
                  ),
                  // Кнопка "Войти в социальные сети"
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MainAuthScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(210, 12, 52, 1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: buttonHorizontalPadding,
                        vertical: buttonVerticalPadding,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(buttonBorderRadius),
                      ),
                      minimumSize: Size(screenWidth * 0.9, buttonHeight),
                    ),
                    child: Text(
                      'Войти в социальные сети',
                      style: TextStyle(
                        color: const Color.fromRGBO(230, 230, 230, 1),
                        fontFamily: 'Montserrat',
                        fontSize: screenWidth * 0.033,
                        height: 1.57,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03), // Отступ снизу для SafeArea
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}