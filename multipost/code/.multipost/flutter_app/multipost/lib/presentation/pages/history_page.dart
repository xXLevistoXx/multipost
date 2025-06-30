import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multipost/core/constants.dart';
import 'package:multipost/main.dart';
import 'package:multipost/presentation/blocs/history/history_bloc.dart';
import 'package:multipost/presentation/blocs/history/history_event.dart';
import 'package:multipost/presentation/blocs/history/history_state.dart';
import 'package:multipost/presentation/widgets/bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String selectedFilter = 'Все'; // Фильтр по соцсетям

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('account_id');
    if (userId != null) {
      context.read<HistoryBloc>().add(FetchPostsEvent(userId));
    }
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        behavior: SnackBarBehavior.floating,
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
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        int count = 0;
        if (state is HistoryLoaded) {
          if (label == 'Все') {
            count = state.posts.length;
          } else {
            count = state.posts.where((post) => post.socials.any((social) =>
                social.getSocialName().toLowerCase() == label.toLowerCase())).length;
          }
        }
        final isSelected = selectedFilter == label;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '($count)',
                  style: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.textSecondary,
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              selectedFilter = label;
            });
          },
          selectedColor: AppColors.primaryRed,
          backgroundColor: const Color.fromARGB(51, 0, 0, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        );
      },
    );
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/Marlo21.png',
                            height: 40,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'История постов',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontSize: screenWidth * 0.051,
                      height: 1.86,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Здесь вы можете просмотреть список ранее отправленных вами постов',
                    style: TextStyle(
                      color: const Color.fromRGBO(230, 230, 230, 1),
                      fontFamily: 'Montserrat',
                      fontSize: screenWidth * 0.033,
                      height: 1.43,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Фильтр по социальным сетям
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Все'),
                        const SizedBox(width: 8),
                        _buildFilterChip('ВКонтакте'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Telegram'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Reddit'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: BlocConsumer<HistoryBloc, HistoryState>(
                      listener: (context, state) {
                        if (state is HistoryError) {
                          _showSnackBar(state.message, true);
                        } else if (state is PostDeleted) {
                          _showSnackBar('Пост успешно удалён', false);
                          _loadPosts(); // Обновляем список после удаления
                        }
                      },
                      builder: (context, state) {
                        if (state is HistoryLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryRed,
                            ),
                          );
                        } else if (state is HistoryLoaded) {
                          final filteredPosts = state.posts.where((post) {
                            if (selectedFilter == 'Все') return true;
                            return post.socials.any((social) =>
                                social.getSocialName().toLowerCase() == selectedFilter.toLowerCase());
                          }).toList();

                          if (filteredPosts.isEmpty) {
                            return Center(
                              child: Text(
                                selectedFilter == 'Все'
                                    ? 'Нет отправленных постов'
                                    : 'Нет постов для $selectedFilter',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: filteredPosts.length,
                            itemBuilder: (context, index) {
                              final post = filteredPosts[index];
                              return Card(
                                color: const Color.fromRGBO(51, 51, 51, 0.5),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: Colors.white, width: 1),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  title: Text(
                                    post.title,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontFamily: 'Montserrat',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Платформы: ${post.socials.map((social) => social.getSocialName()).toSet().join(", ")}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontFamily: 'Montserrat',
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Каналы: ${post.socials.map((social) => "${social.mainUsername} (${social.title})").join(", ")}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontFamily: 'Montserrat',
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Дата отправки: ${DateFormat('dd.MM.yyyy HH:mm').format(post.createdAt.toLocal())}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontFamily: 'Montserrat',
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: SvgPicture.asset(
                                      'assets/icons/delete_icon.svg',
                                      width: 24,
                                      height: 24,
                                      colorFilter: const ColorFilter.mode(AppColors.primaryRed, BlendMode.srcIn),
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: AppColors.dialogBackground,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            side: const BorderSide(color: AppColors.dialogBorder, width: 1),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Image.asset(
                                                'assets/images/judy_mascot.png',
                                                width: 118,
                                                height: 112,
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                width: 45,
                                                height: 3,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(17),
                                                  color: AppColors.dialogDivider,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              const Text(
                                                'Удалить пост?',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontFamily: 'Montserrat',
                                                  fontSize: 16,
                                                  height: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              const Text(
                                                'Вы уверены, что хотите удалить этот пост?',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontFamily: 'Montserrat',
                                                  fontSize: subtitleFontSize,
                                                  height: 1.43,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: dialogButtonHorizontalPadding,
                                                        vertical: dialogButtonVerticalPadding,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.dialogButtonCancel,
                                                        borderRadius: BorderRadius.circular(dialogButtonBorderRadius),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          SvgPicture.asset(
                                                            'assets/icons/dialog_icon.svg',
                                                            width: dialogIconSize,
                                                            height: dialogIconSize,
                                                            colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          const Text(
                                                            'Отмена',
                                                            style: TextStyle(
                                                              color: AppColors.white,
                                                              fontFamily: 'Montserrat',
                                                              fontSize: dialogButtonFontSize,
                                                              height: 1.43,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  TextButton(
                                                    onPressed: () {
                                                      context.read<HistoryBloc>().add(DeletePostEvent(post.id));
                                                      Navigator.pop(context);
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: dialogButtonHorizontalPadding,
                                                        vertical: dialogButtonVerticalPadding,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.dialogButtonConfirm,
                                                        borderRadius: BorderRadius.circular(dialogButtonBorderRadius),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          SvgPicture.asset(
                                                            'assets/icons/ok_icon.svg',
                                                            width: dialogIconSize,
                                                            height: dialogIconSize,
                                                            colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          const Text(
                                                            'Удалить',
                                                            style: TextStyle(
                                                              color: AppColors.white,
                                                              fontFamily: 'Montserrat',
                                                              fontSize: dialogButtonFontSize,
                                                              height: 1.43,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        }
                        return const SizedBox.shrink();
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
}