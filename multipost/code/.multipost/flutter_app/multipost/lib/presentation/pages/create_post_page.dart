import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:multipost/core/constants.dart';
import 'package:multipost/data/datasources/remote_datasource.dart';
import 'package:multipost/data/models/channel_model.dart';
import 'package:multipost/main.dart';
import 'package:multipost/presentation/blocs/auth/auth_bloc.dart';
import 'package:multipost/presentation/blocs/auth/auth_event.dart';
import 'package:multipost/presentation/blocs/auth/auth_state.dart';
import 'package:multipost/presentation/widgets/bottom_bar.dart';
import 'package:multipost/presentation/widgets/custom_date_time_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreatePostPage extends StatefulWidget {
  final String phone;
  final List<ChannelModel> selectedChannels;

  const CreatePostPage({
    super.key,
    required this.phone,
    required this.selectedChannels,
  });

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<File> _images = [];
  List<Map<String, String>> templates = [];
  DateTime? _scheduleDate;
  bool _isSubmitting = false;
  int _attemptsLeft = 5;
  List<String> bannedWords = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _loadBannedWords();
    _checkBanStatus();
  }

  Future<void> _loadTemplates() async {
    try {
      final fetchedTemplates = await RemoteDataSource().getTemplates();
      if (mounted) {
        setState(() {
          templates = fetchedTemplates;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Ошибка загрузки шаблонов: $e', true);
      }
    }
  }

  Future<void> _loadBannedWords() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$goBaseUrl/api/banned_words'),
        headers: {'Authorization': token},
      );
      if (response.statusCode == 200) {
        setState(() {
          bannedWords = List<String>.from(jsonDecode(response.body));
        });
      }
    } catch (e) {
      _showSnackBar('Ошибка загрузки запрещенных слов: $e', true);
    }
  }

  Future<void> _checkBanStatus() async {
    try {
      final token = await _getToken();
      final userId = await _getUserId();
      final response = await http.get(
        Uri.parse('$goBaseUrl/api/users/$userId'),
        headers: {'Authorization': token},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['is_banned'] == true) {
          _showSnackBar('Вы заблокированы и не можете публиковать посты', true);
          setState(() => _isSubmitting = true);
        }
      }
    } catch (e) {
      _showSnackBar('Ошибка проверки статуса: $e', true);
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null && mounted) {
      setState(() {
        _images.addAll(pickedFiles.map((file) => File(file.path)).toList());
      });
    }
  }

  void _removeImage(int index) {
    if (mounted) {
      setState(() {
        _images.removeAt(index);
      });
    }
  }

  void _applyTemplate(Map<String, String> template) {
    if (mounted) {
      setState(() {
        _titleController.text = template['title']!;
        _descriptionController.text = template['description']!;
      });
    }
  }

  void _pickScheduleDate() {
    showDialog(
      context: context,
      builder: (context) => CustomDateTimePicker(
        initialDate: _scheduleDate ?? DateTime.now(),
        minDate: DateTime.now(),
        maxDate: DateTime.now().add(const Duration(days: 365)),
        onConfirm: (date) {
          if (mounted) {
            setState(() {
              _scheduleDate = date;
            });
          }
        },
      ),
    );
  }

  bool _containsBannedWord(String text) {
    return bannedWords.any((word) => text.toLowerCase().contains(word.toLowerCase()));
  }

void _showSnackBar(String message, bool isError) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.black.withOpacity(0.8), // 10% прозрачности фона
      elevation: 0,
      content: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: isError ? AppColors.errorBackground : AppColors.successBackground, // 100% непрозрачный контейнер
                border: Border.all(
                  color: isError ? AppColors.errorBorder : AppColors.successBorder,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    isError ? 'assets/icons/error_icon.svg' : 'assets/icons/success_icon.svg',
                    width: iconSize * 1.2,
                    height: iconSize * 1.2,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.w400 ,
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
      duration: const Duration(seconds: 7),
      padding: const EdgeInsets.only(bottom: 0),
    ),
  );
}

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: fieldHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
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
                  ),
                  Expanded(
                    child: BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) async {
                        if (state is AuthPostCreated) {
                          if (!mounted) return;
                          _showSnackBar(
                            _scheduleDate != null
                                ? 'Пост успешно запланирован'
                                : 'Пост успешно опубликован',
                            false,
                          );
                          await Future.delayed(const Duration(seconds: 3));
                          if (mounted) Navigator.pop(context);
                        } else if (state is AuthError) {
                          if (!mounted) return;
                          final message = state.message.contains('no valid social IDs provided')
                              ? 'Выбранные каналы недоступны. Проверьте их наличие.'
                              : state.message;
                          _showSnackBar(message, true);
                          setState(() => _isSubmitting = false);
                        }
                      },
                      builder: (context, state) {
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 40),
                              Text('Создать пост', style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.051)),
                              const SizedBox(height: 4),
                              const Text('Напишите обо всем, чем хотите бы поделиться с вашей аудиторией', style: TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(height: 20),
                              if (templates.isNotEmpty) ...[
                                const Text('Выберите шаблон:', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: templates.asMap().entries.map((entry) {
                                    final template = entry.value;
                                    return ActionChip(
                                      label: Text(template['name']!, style: const TextStyle(color: Colors.white)),
                                      backgroundColor: AppColors.primaryRed,
                                      onPressed: () => _applyTemplate(template),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),
                              ],
                              TextField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Заголовок',
                                  labelStyle: TextStyle(color: AppColors.textSecondary),
                                  filled: true,
                                  fillColor: Color.fromARGB(51, 0, 0, 0),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                                ),
                                style: const TextStyle(color: AppColors.white),
                                maxLength: 100,
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Описание',
                                  labelStyle: TextStyle(color: AppColors.textSecondary),
                                  filled: true,
                                  fillColor: Color.fromARGB(51, 0, 0, 0),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                                ),
                                style: const TextStyle(color: AppColors.white),
                                maxLines: 5,
                                maxLength: 500,
                              ),
                              if (_containsBannedWord(_titleController.text) || _containsBannedWord(_descriptionController.text))
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    'В тексте обнаружено запрещенное слово. Осталось попыток: $_attemptsLeft. При 0 вы будете помечены как подозрительный.',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    onPressed: _pickImages,
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.cardBackground),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SvgPicture.asset('assets/icons/photo_icon.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn)),
                                        const SizedBox(width: 8),
                                        const Text('Фото', style: TextStyle(fontSize: 16, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: _pickScheduleDate,
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SvgPicture.asset('assets/icons/calendar_icon.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn)),
                                        const SizedBox(width: 8),
                                        const Text('Выбрать дату', style: TextStyle(fontSize: 16, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (_images.isNotEmpty) ...[
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: _images.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final image = entry.value;
                                    return Stack(
                                      children: [
                                        Image.file(image, height: 100, width: 100, fit: BoxFit.cover),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => _removeImage(index)),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 10),
                              ],
                              if (_scheduleDate != null) ...[
                                Row(
                                  children: [
                                    Expanded(child: Text('Запланировано на: ${_scheduleDate!.toString()} (местное время)', style: const TextStyle(color: Colors.white))),
                                    TextButton(
                                      onPressed: () => setState(() => _scheduleDate = null),
                                      child: const Text('Сбросить', style: TextStyle(color: AppColors.primaryRed)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                              ],
                              const SizedBox(height: 20),
                              if (state is AuthLoading)
                                const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                              else
                                ElevatedButton(
                                  onPressed: _isSubmitting || (bannedWords.isNotEmpty && _containsBannedWord(_titleController.text + _descriptionController.text))
                                      ? null
                                      : () async {
                                          if (_titleController.text.isEmpty || _descriptionController.text.isEmpty || widget.phone.isEmpty || widget.selectedChannels.isEmpty) {
                                            _showSnackBar('Пожалуйста, заполните все поля и выберите хотя бы один канал', true);
                                            return;
                                          }
                                          if (_scheduleDate != null && _scheduleDate!.isBefore(DateTime.now())) {
                                            _showSnackBar('Дата планирования должна быть в будущем', true);
                                            return;
                                          }
                                          if (_containsBannedWord(_titleController.text + _descriptionController.text)) {
                                            setState(() {
                                              _attemptsLeft--;
                                              if (_attemptsLeft <= 0) {
                                                _notifyAdmin();
                                              }
                                            });
                                            _showSnackBar('Запрещенное слово обнаружено. Осталось попыток: $_attemptsLeft', true);
                                            return;
                                          }
                                          setState(() => _isSubmitting = true);
                                          final adjustedScheduleDate = _scheduleDate?.add(const Duration(hours: -3));
                                          context.read<AuthBloc>().add(
                                                CreatePostEvent(
                                                  phone: widget.phone,
                                                  selectedChannels: widget.selectedChannels,
                                                  title: _titleController.text,
                                                  description: _descriptionController.text,
                                                  images: _images.isNotEmpty ? _images : null,
                                                  scheduleDate: adjustedScheduleDate?.toUtc(),
                                                ),
                                              );
                                        },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset('assets/icons/check_circle_icon.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn)),
                                      const SizedBox(width: 8),
                                      const Text('Опубликовать', style: TextStyle(fontSize: 18, color: Colors.white)),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 20),
                            ],
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
      bottomNavigationBar: const BottomBar(),
    );
  }

  Future<void> _notifyAdmin() async {
    final token = await _getToken();
    final userId = await _getUserId();
    await http.post(
      Uri.parse('$goBaseUrl/api/users/$userId/suspicious'),
      headers: {'Authorization': token},
    );
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return 'Bearer $token';
  }

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('account_id') ?? '';
  }
}