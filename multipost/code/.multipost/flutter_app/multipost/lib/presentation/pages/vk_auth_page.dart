import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class VkAuthPage extends StatefulWidget {
  const VkAuthPage({super.key});

  @override
  State<VkAuthPage> createState() => _VkAuthPageState();
}

class _VkAuthPageState extends State<VkAuthPage> {
  WebViewController? _webViewController;
  late final String _codeVerifier;
  late final String _state;
  late String? _userId;
  bool _isLoading = true;

  static const String clientId = '53526931';
  static const String redirectUri = 'https://multipostingm.ru/auth/vk/callback';
  static const String backendUrl = 'https://multipostingm.ru/auth/vk/exchange';

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('account_id');
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: пользователь не авторизован')),
      );
      Navigator.pop(context);
      return;
    }

    _codeVerifier = _generateCodeVerifier();
    _state = _generateRandomString(32);

    final codeChallenge = _generateCodeChallenge(_codeVerifier);
    print('Generated authUrl with state: $_state, codeChallenge: $codeChallenge');

    final authUrl = Uri.https('id.vk.com', '/authorize', {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': 'groups,email,phone',
      'state': _state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'accountID': _userId!,
    }).toString();
    print('Loading authUrl: $authUrl');

    setState(() {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onNavigationRequest: _handleNavigationRequest,
          onPageStarted: (url) => print('Page started loading: $url'),
          onPageFinished: (url) => print('Page finished loading: $url'),
          onWebResourceError: (error) => print('WebView error: ${error.description}'),
        ))
        ..loadRequest(Uri.parse(authUrl));
      _isLoading = false;
    });
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    print('Navigation request: ${request.url}');
    final url = Uri.parse(request.url);
    if (url.toString().startsWith(redirectUri)) {
      final code = url.queryParameters['code'];
      final deviceId = url.queryParameters['device_id'] ?? uuid.v4();
      final state = url.queryParameters['state'];

      print('Redirect received: code=$code, deviceId=$deviceId, state=$state');
      if (state != _state) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: несоответствие state')),
        );
        return NavigationDecision.prevent;
      }

      if (code != null && deviceId != null) {
        exchangeCode(code: code, deviceId: deviceId, codeVerifier: _codeVerifier);
      } else {
        print('Missing code or deviceId in redirect URL');
      }
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  Future<void> exchangeCode({
    required String code,
    required String deviceId,
    required String codeVerifier,
  }) async {
    final url = Uri.parse(backendUrl);
    final payload = {
      'code': code,
      'device_id': deviceId,
      'code_verifier': codeVerifier,
      'accountID': _userId,
    };

    try {
      print('Sending exchange request to $url with payload: $payload');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('Exchange response: status=${response.statusCode}, body=${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final links = List<Map<String, dynamic>>.from(data['links'] ?? []);
        if (links.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Успешная авторизация VK, группы получены')),
          );
          Navigator.pop(context, links);
        } else {
          throw Exception('No groups found');
        }
      } else {
        throw Exception('Failed to exchange code: ${response.body}');
      }
    } catch (e) {
      print('Exchange error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(64, (i) => random.nextInt(256));
    return base64UrlEncode(values).replaceAll('=', '');
  }

  String _generateCodeChallenge(String codeVerifier) {
    final bytes = ascii.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  String _generateRandomString(int length) {
    const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход через VK ID')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _webViewController != null
              ? WebViewWidget(controller: _webViewController!)
              : const Center(child: Text('Ошибка инициализации WebView')),
    );
  }
}


var uuid = const Uuid();