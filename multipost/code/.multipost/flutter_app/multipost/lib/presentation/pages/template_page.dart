import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multipost/core/constants.dart';
import 'package:multipost/data/datasources/remote_datasource.dart';
import 'package:multipost/main.dart';
import 'package:multipost/presentation/pages/edit_template_page.dart';
import 'package:multipost/presentation/widgets/bottom_bar.dart';

class TemplatePage extends StatefulWidget {
  const TemplatePage({super.key});

  @override
  State<TemplatePage> createState() => _TemplatePageState();
}

class _TemplatePageState extends State<TemplatePage> {
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<Map<String, String>> templates = [];
  final RemoteDataSource _remoteDataSource = RemoteDataSource();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fetchedTemplates = await _remoteDataSource.getTemplates();
      setState(() {
        templates = fetchedTemplates;
      });
    } catch (e) {
      _showSnackBar('Ошибка загрузки шаблонов: $e', true);
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveTemplate() async {
    if (_nameController.text.isEmpty || _titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showSnackBar('Пожалуйста, заполните все поля', true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _remoteDataSource.createTemplate(
        name: _nameController.text,
        title: _titleController.text,
        description: _descriptionController.text,
      );
      await _loadTemplates();
      setState(() {
        _nameController.clear();
        _titleController.clear();
        _descriptionController.clear();
      });
      _showSnackBar('Шаблон сохранен', false);
    } catch (e) {
      _showSnackBar('Ошибка сохранения шаблона: $e', true);
    }

    setState(() {
      _isLoading = false;
    });
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

  @override
  void dispose() {
    _nameController.dispose();
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
                        Image.asset(
                          'assets/images/Marlo21.png',
                          height: 40,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: AppColors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Назад',
                              style: TextStyle(
                                color: AppColors.white,
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          Text(
                            'Создайте новый шаблон',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Montserrat',
                              fontSize: screenWidth * 0.051,
                              height: 1.86,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Для удобства создайте шаблон, который поможет вам экономить время',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Введите название шаблона',
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary,
                                fontFamily: 'Montserrat',
                                fontSize: fieldFontSize,
                              ),
                              filled: true,
                              fillColor: Color.fromARGB(51, 0, 0, 0),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.transparent),
                                borderRadius: BorderRadius.all(Radius.circular(14)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.transparent),
                                borderRadius: BorderRadius.all(Radius.circular(14)),
                              ),
                            ),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontFamily: 'Montserrat',
                              fontSize: fieldFontSize,
                            ),
                            maxLength: 50,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              hintText: 'Введите заголовок шаблона',
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary,
                                fontFamily: 'Montserrat',
                                fontSize: fieldFontSize,
                              ),
                              filled: true,
                              fillColor: Color.fromARGB(51, 0, 0, 0),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.transparent),
                                borderRadius: BorderRadius.all(Radius.circular(14)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.transparent),
                                borderRadius: BorderRadius.all(Radius.circular(14)),
                              ),
                            ),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontFamily: 'Montserrat',
                              fontSize: fieldFontSize,
                            ),
                            maxLength: 100,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              hintText: 'Введите текст шаблона',
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary,
                                fontFamily: 'Montserrat',
                                fontSize: fieldFontSize,
                              ),
                              filled: true,
                              fillColor: Color.fromARGB(51, 0, 0, 0),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.transparent),
                                borderRadius: BorderRadius.all(Radius.circular(14)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.transparent),
                                borderRadius: BorderRadius.all(Radius.circular(14)),
                              ),
                            ),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontFamily: 'Montserrat',
                              fontSize: fieldFontSize,
                            ),
                            maxLines: 5,
                            maxLength: 500,
                          ),
                          const SizedBox(height: 20),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                              : ElevatedButton(
                                  onPressed: _saveTemplate,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryRed,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    minimumSize: const Size(double.infinity, buttonHeight),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/check_circle_icon.svg',
                                        width: 20,
                                        height: 20,
                                        colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Сохранить шаблон',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          const SizedBox(height: 30),
                          const Text(
                            'Сохраненные шаблоны',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                              : templates.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Нет сохранённых шаблонов',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: templates.length,
                                      itemBuilder: (context, index) {
                                        final template = templates[index];
                                        return ListTile(
                                          title: Text(
                                            template['name']!,
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.edit, color: AppColors.white),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => EditTemplatePage(
                                                    template: template,
                                                    onSave: (updatedTemplate) async {
                                                      try {
                                                        await _remoteDataSource.updateTemplate(
                                                          templateId: template['id']!,
                                                          name: updatedTemplate['name']!,
                                                          title: updatedTemplate['title']!,
                                                          description: updatedTemplate['description']!,
                                                        );
                                                        await _loadTemplates();
                                                        _showSnackBar('Шаблон обновлен', false);
                                                      } catch (e) {
                                                        _showSnackBar('Ошибка обновления шаблона: $e', true);
                                                      }
                                                    },
                                                    onDelete: () async {
                                                      try {
                                                        await _remoteDataSource.deleteTemplate(
                                                          templateId: template['id']!,
                                                        );
                                                        await _loadTemplates();
                                                        _showSnackBar('Шаблон удален', false);
                                                      } catch (e) {
                                                        _showSnackBar('Ошибка удаления шаблона: $e', true);
                                                      }
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                          const SizedBox(height: 20),
                        ],
                      ),
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
}