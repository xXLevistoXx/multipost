import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multipost/injection_container.dart' as di;
import 'package:multipost/presentation/blocs/auth/auth_bloc.dart';
import 'package:multipost/presentation/blocs/history/history_bloc.dart';
import 'package:multipost/presentation/pages/welcome_page.dart';
import 'package:multipost/presentation/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _checkIfAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final accountId = prefs.getString('account_id');
    return accountId != null && accountId.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di.sl<AuthBloc>()),
        BlocProvider(create: (context) => di.sl<HistoryBloc>()),
      ],
      child: MaterialApp(
        title: 'Multipost',
        theme: ThemeData(
          primarySwatch: Colors.red,
          scaffoldBackgroundColor: Colors.transparent,
          extensions: [
            CustomTheme(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 13, 13, 13),
                  Color.fromARGB(255, 13, 13, 13),
                ],
              ),
            ),
          ],
        ),
        home: FutureBuilder<bool>(
          future: _checkIfAuthenticated(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            // if (snapshot.hasData && snapshot.data == true) {
            //   return const HomePage();
            // }
            return const WelcomePage();
          },
        ),
      ),
    );
  }
}

class CustomTheme extends ThemeExtension<CustomTheme> {
  final LinearGradient gradient;

  const CustomTheme({required this.gradient});

  @override
  CustomTheme copyWith({LinearGradient? gradient}) {
    return CustomTheme(gradient: gradient ?? this.gradient);
  }

  @override
  CustomTheme lerp(ThemeExtension<CustomTheme>? other, double t) {
    if (other is! CustomTheme) {
      return this;
    }
    return CustomTheme(gradient: gradient);
  }

  Widget buildBackground(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -screenHeight * 0.1,
            left: screenWidth * 0.23,
            child: Container(
              width: screenWidth * 1.13,
              height: screenHeight * 0.6,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: const BorderRadius.all(Radius.elliptical(485, 571)),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(210, 12, 52, 0.5),
                    blurRadius: 150,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.6,
            left: -screenWidth * 0.25,
            child: Container(
              width: screenWidth * 1.06,
              height: screenHeight * 0.48,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: const BorderRadius.all(Radius.elliptical(444, 455)),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(210, 12, 52, 0.6),
                    blurRadius: 150,
                    spreadRadius: 10,
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