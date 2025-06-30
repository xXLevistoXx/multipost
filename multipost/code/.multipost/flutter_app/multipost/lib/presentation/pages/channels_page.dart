import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multipost/core/constants.dart';
import 'package:multipost/data/models/channel_model.dart';
import 'package:multipost/main.dart';
import 'package:multipost/presentation/blocs/auth/auth_bloc.dart';
import 'package:multipost/presentation/blocs/auth/auth_event.dart';
import 'package:multipost/presentation/blocs/auth/auth_state.dart';
import 'package:multipost/presentation/pages/create_post_page.dart';
import 'package:multipost/presentation/widgets/bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChannelsPage extends StatefulWidget {
  final String phone;

  const ChannelsPage({super.key, required this.phone});

  @override
  State<ChannelsPage> createState() => _ChannelsPageState();
}

class _ChannelsPageState extends State<ChannelsPage> {
  List<ChannelModel> selectedChannels = [];
  String selectedFilter = 'Все';
  List<ChannelModel> allChannels = []; // Храним все каналы для фильтра "Все"

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('account_id');
    if (userId != null) {
      context.read<AuthBloc>().add(GetChannelsEvent(widget.phone));
    }
  }

  void _refreshChannels() {
    context.read<AuthBloc>().add(GetChannelsEvent(widget.phone));
    setState(() {
      selectedChannels.clear();
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

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.white : AppColors.textSecondary,
          fontFamily: 'Montserrat',
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) async {
        setState(() {
          selectedFilter = label;
        });
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('account_id');
        if (userId != null && label != 'Все') {
          String platform;
          switch (label) {
            case 'Telegram':
              platform = 'telegram';
              break;
            case 'ВКонтакте':
              platform = 'vk';
              break;
            case 'Reddit':
              platform = 'reddit';
              break;
            default:
              platform = '';
          }
          if (platform.isNotEmpty) {
            context.read<AuthBloc>().add(GetChannelsByPlatformEvent(userId, platform));
          }
        }
      },
      selectedColor: AppColors.primaryRed,
      backgroundColor: const Color.fromARGB(51, 0, 0, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
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
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _refreshChannels,
                        tooltip: 'Обновить каналы',
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Выберите свои каналы',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontSize: screenWidth * 0.051,
                      height: 1.86,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Вы можете выбрать несколько каналов, чтобы запостить новую публикацию сразу в несколько соцсетей',
                    style: TextStyle(
                      color: const Color.fromRGBO(230, 230, 230, 1),
                      fontFamily: 'Montserrat',
                      fontSize: screenWidth * 0.033,
                      height: 1.43,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                    child: BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is AuthError) {
                          _showSnackBar(state.message, true);
                        } else if (state is AuthChannelsLoaded && selectedFilter == 'Все') {
                          allChannels = state.channels; // Сохраняем все каналы
                        }
                      },
                      builder: (context, state) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (state is AuthLoading)
                              const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryRed,
                                ),
                              )
                            else if (state is AuthChannelsLoaded)
                              Expanded(
                                child: ListView.builder(
                                  itemCount: (selectedFilter == 'Все' ? allChannels : state.channels).length,
                                  itemBuilder: (context, index) {
                                    final channel = (selectedFilter == 'Все' ? allChannels : state.channels)[index];
                                    final isSelected = selectedChannels.contains(channel);
                                    return CheckboxListTile(
                                      title: Text(
                                        channel.title,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      subtitle: Text(
                                        channel.mainUsername,
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedChannels.add(channel);
                                          } else {
                                            selectedChannels.remove(channel);
                                          }
                                        });
                                      },
                                      checkColor: Colors.white,
                                      activeColor: const Color(0xFF00C853),
                                    );
                                  },
                                ),
                              ),
                          ],
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
      floatingActionButton: selectedChannels.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatePostPage(
                      phone: widget.phone,
                      selectedChannels: selectedChannels,
                    ),
                  ),
                );
              },
              backgroundColor: AppColors.primaryRed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/next_icon.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            )
          : null,
      bottomNavigationBar: const BottomBar(),
    );
  }
}