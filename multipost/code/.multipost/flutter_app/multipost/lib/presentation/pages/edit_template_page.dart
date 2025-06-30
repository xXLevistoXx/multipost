import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multipost/core/constants.dart';
import 'package:multipost/main.dart';

class EditTemplatePage extends StatefulWidget {
  final Map<String, String> template;
  final Future<void> Function(Map<String, String>) onSave;
  final Future<void> Function() onDelete;

  const EditTemplatePage({
    super.key,
    required this.template,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<EditTemplatePage> createState() => _EditTemplatePageState();
}

class _EditTemplatePageState extends State<EditTemplatePage> {
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template['name']);
    _titleController = TextEditingController(text: widget.template['title']);
    _descriptionController = TextEditingController(text: widget.template['description']);
  }

  Future<void> _updateTemplate() async {
    if (_nameController.text.isEmpty || _titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showSnackBar('Пожалуйста, заполните все поля', true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedTemplate = {
        'id': widget.template['id']!,
        'name': _nameController.text,
        'title': _titleController.text,
        'description': _descriptionController.text,
      };
      await widget.onSave(updatedTemplate);
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Ошибка обновления шаблона: $e', true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTemplate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onDelete();
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Ошибка удаления шаблона: $e', true);
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                            'Редактировать шаблон',
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
                            'Измените данные шаблона',
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
                              hintText: 'Название шаблона',
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
                              hintText: 'Заголовок шаблона',
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
                              hintText: 'Текст шаблона',
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
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _updateTemplate,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryRed,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 15,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
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
                                              'Сохранить',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white,
                                                fontFamily: 'Montserrat',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _deleteTemplate,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.errorBackground,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 15,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              'assets/icons/delete_icon.svg',
                                              width: 20,
                                              height: 20,
                                              colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Удалить',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white,
                                                fontFamily: 'Montserrat',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
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
    );
  }
}