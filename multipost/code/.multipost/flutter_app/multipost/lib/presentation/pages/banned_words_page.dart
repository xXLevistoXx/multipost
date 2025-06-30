import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:multipost/core/constants.dart';
import 'package:multipost/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BannedWordsPage extends StatefulWidget {
  const BannedWordsPage({super.key});

  @override
  State<BannedWordsPage> createState() => _BannedWordsPageState();
}

class _BannedWordsPageState extends State<BannedWordsPage> {
  final _wordController = TextEditingController();
  List<String> bannedWords = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBannedWords();
  }

  Future<void> _loadBannedWords() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      print('Sending request to: $goBaseUrl/api/admin/forbidden-words with token: $token');
      final response = await http.get(
        Uri.parse('$goBaseUrl/api/admin/forbidden-words'),
        headers: {'Authorization': token},
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Decoded data: $data, Type: ${data.runtimeType}');
        setState(() {
          if (data is List) {
            bannedWords = List<String>.from(data);
          } else if (data is Map && data['forbidden_words'] != null) {
            bannedWords = (data['forbidden_words'] as List<dynamic>)
                .map((item) => item['word'] as String)
                .toList();
          } else {
            throw Exception('Неправильный формат ответа: $data');
          }
        });
      } else {
        throw Exception('Не удалось загрузить запрещенные слова: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showSnackBar(e.toString(), true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addBannedWord() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      _showSnackBar('Введите слово', true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      print('Sending POST to: $goBaseUrl/api/admin/forbidden-words with word: $word');
      final response = await http.post(
        Uri.parse('$goBaseUrl/api/admin/forbidden-words'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: jsonEncode({'word': word}),
      );
      print('Response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        _wordController.clear();
        _loadBannedWords();
        _showSnackBar('Слово успешно добавлено', false);
      } else {
        throw Exception('Не удалось добавить запрещенное слово: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showSnackBar(e.toString(), true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeBannedWord(String word) async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final encodedWord = Uri.encodeComponent(word); // Кодируем слово для URL
      print('Sending DELETE to: $goBaseUrl/api/admin/forbidden-words/$encodedWord with token: $token');
      final response = await http.delete(
        Uri.parse('$goBaseUrl/api/admin/forbidden-words/$encodedWord'),
        headers: {'Authorization': token},
      ).timeout(const Duration(seconds: 10));
      print('Response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['status'] == 'success') {
          _loadBannedWords();
          _showSnackBar('Слово успешно удалено', false);
        } else {
          throw Exception('Удаление не выполнено: ${responseBody['error'] ?? 'Неизвестная ошибка'}');
        }
      } else {
        throw Exception('Не удалось удалить запрещенное слово: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showSnackBar(e.toString(), true);
    } finally {
      setState(() => _isLoading = false);
    }
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
        padding: const EdgeInsets.only(bottom: 80),
      ),
    );
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw Exception('Токен не найден');
    }
    return token;
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset('assets/images/Marlo21.png', height: 40),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Text('Назад', style: TextStyle(color: AppColors.white)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.white),
                        onPressed: _loadBannedWords,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text('Запрещенные слова', style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.051)),
                  const SizedBox(height: 4),
                  const Text('Управление списком запрещенных слов', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _wordController,
                          decoration: InputDecoration(
                            labelText: 'Добавить слово',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.cardBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.white, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.white, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.white, width: 2),
                            ),
                          ),
                          style: const TextStyle(color: AppColors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _addBannedWord,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: AppColors.white, width: 1),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                        child: const Text('Добавить'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                      : Expanded(
                          child: ListView.builder(
                            itemCount: bannedWords.length,
                            itemBuilder: (context, index) {
                              final word = bannedWords[index];
                              return Card(
                                color: AppColors.cardBackground,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  title: Text(
                                    word,
                                    style: const TextStyle(color: AppColors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeBannedWord(word),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ),
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
    );
  }
}