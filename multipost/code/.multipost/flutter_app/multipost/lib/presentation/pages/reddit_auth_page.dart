import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multipost/core/constants.dart';
import 'package:multipost/presentation/blocs/auth/auth_bloc.dart';
import 'package:multipost/presentation/blocs/auth/auth_state.dart';
import 'package:multipost/presentation/pages/auth_page.dart';
import 'package:multipost/presentation/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'dart:io' show Platform;

class RedditAuthPage extends StatefulWidget {
  const RedditAuthPage({super.key});

  @override
  State<RedditAuthPage> createState() => _RedditAuthPageState();
}

class _RedditAuthPageState extends State<RedditAuthPage> {
  WebViewController? _webViewController;
  bool _isLoading = true;

  Future<String> _getAccountId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String id = prefs.getString('account_id') ?? '';
    if (id.isEmpty) {
      throw Exception('Account ID не найден. Пожалуйста, войдите в систему.');
    }
    return id;
  }

  Future<void> _saveAuth() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('reddit_token', 'authenticated');
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
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    }
    _initializeWebView();
  }

Future<void> _initializeWebView() async {
  try {
    final accountId = await _getAccountId();
    final authURL = "$goBaseUrl/auth/reddit?accountID=$accountId";
    print("Loading Reddit auth URL: $authURL");

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("android:com.example.multipost:1.0 (by /u/Huge-Ad4304)") // Установлен User-Agent
      ..clearCache()
      ..clearLocalStorage()
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            print("Navigation request: ${request.url}");
            if (request.url.startsWith('http://localhost/auth/reddit/callback')) {
              final uri = Uri.parse(request.url);
              final error = uri.queryParameters['error'];
              if (error != null) {
                print("Error from Reddit: $error");
                _showSnackBar("Ошибка авторизации: $error", true);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                  (route) => false,
                );
                return NavigationDecision.prevent;
              }

              final code = uri.queryParameters['code'];
              final state = uri.queryParameters['state'];
              print("Received code: $code, state: $state");
              if (code == null || state == null) {
                _showSnackBar("Ошибка: отсутствует code или state", true);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                  (route) => false,
                );
                return NavigationDecision.prevent;
              }

              final expectedState = "reddit|$accountId";
              if (state != expectedState) {
                _showSnackBar("Ошибка: неверный state", true);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                  (route) => false,
                );
                return NavigationDecision.prevent;
              }

              await _saveAuth();
              _showSnackBar("Успешная авторизация в Reddit", false);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            print("Page started loading: $url");
            if (url.contains("reddit.com/login")) {
              print("User login page loaded successfully");
            }
          },
          onPageFinished: (String url) {
            print("Page finished loading: $url");
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print("WebView error: ${error.description}, code: ${error.errorCode}");
            _showSnackBar("Ошибка загрузки страницы: ${error.description}", true);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AuthPage()),
              (route) => false,
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(authURL));

    setState(() {
      _isLoading = false;
    });
  } catch (e) {
    _showSnackBar(e.toString(), true);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthPage()),
      (route) => false,
    );
    setState(() {
      _isLoading = false;
    });
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Авторизация в Reddit'),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _showSnackBar(state.message, true);
          }
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _webViewController != null
                ? WebViewWidget(controller: _webViewController!)
                : const Center(child: Text('Ошибка инициализации WebView')),
      ),
    );
  }
}