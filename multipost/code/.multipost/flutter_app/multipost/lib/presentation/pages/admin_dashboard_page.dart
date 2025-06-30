import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:multipost/core/constants.dart';
import 'package:multipost/main.dart';
import 'package:multipost/presentation/pages/banned_words_page.dart';
import 'package:multipost/presentation/pages/welcome_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<Map<String, dynamic>> users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$goBaseUrl/api/admin/users'),
        headers: {'Authorization': token},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        setState(() {
          users = List<Map<String, dynamic>>.from(jsonDecode(response.body)['users']);
        });
      } else {
        throw Exception('Не удалось загрузить пользователей: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showSnackBar(e.toString(), true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRole(String userId, String newRole) async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$goBaseUrl/api/admin/users/$userId/role'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: jsonEncode({'role': newRole}),
      );
      if (response.statusCode == 200) {
        await _loadUsers();
        _showSnackBar('Роль успешно изменена', false);
      } else {
        throw Exception('Не удалось обновить роль: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showSnackBar(e.toString(), true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBan(String userId, bool isBanned) async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final newBanState = !isBanned;
      final response = await http.put(
        Uri.parse('$goBaseUrl/api/admin/users/$userId/ban'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: jsonEncode({'ban': newBanState}),
      );
      if (response.statusCode == 200) {
        setState(() {
          final userIndex = users.indexWhere((user) => user['id'] == userId);
          if (userIndex != -1) {
            users[userIndex]['is_banned'] = newBanState;
          }
        });
        await _loadUsers();
        _showSnackBar('Пользователь ${newBanState ? "заблокирован" : "разблокирован"} успешно', false);
      } else {
        throw Exception('Не удалось забанить: ${response.statusCode} - ${response.body}');
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
    return 'Bearer $token';
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
                      Image.asset('assets/images/Marlo21.png', height: 40),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh, color: AppColors.white),
                            onPressed: _loadUsers,
                            tooltip: 'Обновить',
                          ),
                          IconButton(
                            icon: SvgPicture.asset(
                              'assets/icons/logout_icon.svg',
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                            ),
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const WelcomePage()),
                                (Route<dynamic> route) => false,
                              );
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Выйти',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text('Панель Администратора', style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.051)),
                  const SizedBox(height: 4),
                  const Text('Управляйте своими пользователями системы', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 0, bottom: 8),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const BannedWordsPage()),
                          );
                        },
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
                        child: const Text('Управление запрещеными словами'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                      : Expanded(
                          child: ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return Card(
                                color: AppColors.cardBackground,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ListTile(
                                  title: Text(
                                    user['login'],
                                    style: const TextStyle(color: AppColors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'Роль: ${user['role']}',
                                    style: const TextStyle(color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: SizedBox(
                                    width: screenWidth * 0.35,
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      value: user['role'],
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                        filled: true,
                                        fillColor: AppColors.cardBackground,
                                      ),
                                      dropdownColor: AppColors.cardBackground,
                                      style: const TextStyle(color: AppColors.white, fontSize: 12),
                                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.white),
                                      items: const [
                                        DropdownMenuItem<String>(
                                          value: 'Admin',
                                          child: Text('Администратор', style: TextStyle(color: AppColors.white)),
                                        ),
                                        DropdownMenuItem<String>(
                                          value: 'User',
                                          child: Text('Пользователь', style: TextStyle(color: AppColors.white)),
                                        ),
                                      ],
                                      onChanged: (String? newRole) {
                                        if (newRole != null) _updateRole(user['id'], newRole);
                                      },
                                    ),
                                  ),
                                  leading: IconButton(
                                    icon: Icon(
                                      user['is_banned'] ?? false ? Icons.lock_outline : Icons.lock_open,
                                      color: user['is_banned'] ?? false ? Colors.red : Colors.green,
                                    ),
                                    onPressed: () => _toggleBan(user['id'], user['is_banned'] ?? false),
                                    splashRadius: 20,
                                    padding: const EdgeInsets.all(8),
                                    constraints: const BoxConstraints(),
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