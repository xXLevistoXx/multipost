import 'package:flutter/material.dart';

const String baseUrl = 'https://multipostingm.ru/api/telegram'; // Для FastAPI (Telegram)
const String goBaseUrl = 'https://multipostingm.ru';            // Для Go-бэкенда (регистрация, VK, Reddit)

// Регулярное выражение для валидации номера телефона (международный формат, например, +79991234567)
const String phoneNumberPattern = r'^\+[1-9]\d{1,14}$';

// Размеры
const double logoWidth = 150; // Уменьшено для адаптивности
const double logoHeight = 32;
const double illustrationWidth = 300;
const double buttonHeight = 48;
const double buttonHorizontalPadding = 20;
const double buttonVerticalPadding = 14;
const double buttonBorderRadius = 40;
const double iconSize = 24;
const double fieldHorizontalPadding = 20; // 20/428 ≈ 0.047
const double buttonOuterPadding = 16; // 16/428 ≈ 0.037
const double titleHorizontalPadding = 32; // 32/428 ≈ 0.075
const double appBarHorizontalPadding = 15; // 15/428 ≈ 0.035
const double appBarTitleFontSize = 16; // 16/428 ≈ 0.037
const double titleFontSize = 22; // 22/428 ≈ 0.051
const double subtitleFontSize = 14; // 14/428 ≈ 0.033
const double fieldFontSize = 14; // 14/428 ≈ 0.033
const double spacingAfterTitle = 100; // Уменьшено для адаптивности
const double spacingAfterPhoneField = 70;
const double spacingAfterCodeField = 60;
const double spacingBeforeButtonWithCode = 90;
const double spacingBeforeButtonWithoutCode = 40;
const double dialogButtonBorderRadius = 8;
const double dialogButtonHorizontalPadding = 20;
const double dialogButtonVerticalPadding = 10;
const double dialogIconSize = 24;
const double dialogButtonFontSize = 14;
const double dialogBorderRadius = 20;
const double dialogDividerWidth = 45;
const double dialogDividerHeight = 3;
const double dialogDividerBorderRadius = 17;
const double dialogImageWidth = 118;
const double dialogImageHeight = 112;
const double dialogContentVerticalPadding = 16;
const double dialogSpacing = 12;
const double snackbarBottomMargin = 80;
const double snackbarHorizontalMargin = 16;
const double snackbarPaddingHorizontal = 12;
const double snackbarPaddingVertical = 8;
const double snackbarBorderRadius = 20;
const double snackbarBorderWidth = 1;
const double cardVerticalMargin = 8;
const double cardHorizontalPadding = 16;
const double cardVerticalPadding = 8;
const double cardBorderRadius = 14;
const double chipSpacing = 8;
const double chipBorderRadius = 14;
const double chipFontSize = 14;
const double authButtonHeight = 50;
const double authButtonIconSize = 24;
const double authButtonSpacing = 10;
const double authButtonBorderRadius = 30;
const double homeCardWidth = 160;
const double homeCardHeight = 210;
const double homeCardBorderWidth = 1;
const double homeCardBorderRadius = 16;
const double homeCardIconWidth = 100;
const double homeCardIconHeight = 90;
const double homeCardLabelPaddingHorizontal = 5;
const double homeCardLabelPaddingVertical = 5;
const double homeCardLabelBorderRadius = 40;
const double homeCardLabelFontSize = 16;
const double homeCardSpacing = 36;
const double mainAuthTextFieldFontSize = 16;
const double mainAuthButtonVerticalPadding = 15;
const double mainAuthButtonHorizontalPadding = 40;
const double mainAuthButtonHeight = 56;
const double profileImageWidth = 200;
const double profileImageHeight = 200;
const double profileButtonVerticalPadding = 15;
const double profileButtonHorizontalPadding = 40;
const double profileButtonFontSize = 16;
const double createPostPhotoButtonVerticalPadding = 10;
const double createPostPhotoButtonHorizontalPadding = 20;
const double createPostPhotoIconSize = 20;
const double createPostImageSize = 100;
const double createPostButtonVerticalPadding = 15;
const double createPostButtonHorizontalPadding = 40;
const double templateTitleFontSize = 22; // 22/428 ≈ 0.051
const double templateButtonVerticalPadding = 15;
const double templateButtonHorizontalPadding = 40;
const double templateListTitleFontSize = 16;
const double templateFieldBorderRadius = 14;
const double welcomeTitleFontSize = 34; // 34/428 ≈ 0.08
const double welcomeSubtitleFontSize = 14; // 14/428 ≈ 0.033
const double welcomeTopPadding = 120; // screenHeight * 0.15
const double welcomeSpacing = 24; // screenHeight * 0.03
const double bottomBarVerticalPadding = 20;
const double bottomBarBorderRadius = 14;
const double bottomBarBorderWidth = 1;
const double datePickerDialogBorderRadius = 10;
const double datePickerWidth = 300;
const double datePickerMonthFontSize = 18;
const double datePickerDayLabelFontSize = 12;
const double datePickerDayFontSize = 16;
const double datePickerTimeLabelFontSize = 16;
const double datePickerTimeFontSize = 20;
const double datePickerButtonVerticalPadding = 10;
const double datePickerButtonHorizontalPadding = 20;
const double datePickerButtonBorderRadius = 10;
const double datePickerButtonFontSize = 16;
const double datePickerSpacing = 10;
const double datePickerMargin = 2;
const double datePickerWheelWidth = 60;
const double datePickerWheelHeight = 100;
const double datePickerWheelItemExtent = 40;
const double datePickerAmPmVerticalPadding = 5;
const double datePickerAmPmHorizontalPadding = 10;
const double datePickerAmPmFontSize = 16;

// Цвета
class AppColors {
  static const primaryRed = Color(0xFFA80929);
  static const gradientStart = Color(0xFF2B0A1A);
  static const gradientEnd = Color(0xFFB71C1C);
  static const white = Colors.white;
  static const textPrimary = Color.fromRGBO(230, 230, 230, 1);
  static const textSecondary = Color.fromRGBO(153, 153, 153, 1);
  static const textDisabled = Color.fromRGBO(79, 79, 79, 1);
  static const borderDefault = Color.fromRGBO(179, 179, 179, 1);
  static const borderDisabled = Color.fromRGBO(79, 79, 79, 1);
  static const dialogBackground = Color.fromRGBO(25, 25, 25, 1);
  static const dialogBorder = Color.fromRGBO(39, 39, 42, 1);
  static const dialogDivider = Color.fromRGBO(153, 153, 153, 1);
  static const dialogButtonCancel = Color.fromRGBO(51, 51, 51, 1);
  static const dialogButtonConfirm = Color.fromRGBO(210, 12, 52, 1);
  static const errorBackground = Color.fromRGBO(210, 12, 52, 0.3);
  static const errorBorder = Color.fromRGBO(210, 12, 52, 1);
  static const successBackground = Color.fromRGBO(148, 219, 136, 0.3);
  static const successBorder = Color.fromRGBO(148, 219, 136, 1);
  static const vkButton = Color(0xFF0277FF);
  static const telegramButton = Color(0xFF2395E5);
  static const redditButton = Color(0xFFFF4500);
  static const transparentBlack = Color.fromARGB(51, 0, 0, 0);
  static const checkboxActive = Color(0xFF00C853);
  static const logoutButton = Color(0xFFD20C34);
  static const cardBackground = Color.fromARGB(51, 0, 0, 0);
  static const homeCardBackground = Color.fromRGBO(51, 51, 51, 0.5);
  static const homeCardLabelBackground = Color.fromRGBO(168, 9, 41, 1);
  static const mainAuthErrorBackground = Color(0xFFF44336);
  static const mainAuthErrorBorder = Color(0xFFD32F2F);
  static const mainAuthSuccessBackground = Color(0xFF4CAF50);
  static const mainAuthSuccessBorder = Color(0xFF388E3C);
  static const bottomBarBackground = Color.fromRGBO(25, 25, 25, 0.95);
  static const bottomBarBorder = Color.fromRGBO(51, 51, 51, 1);
  static const datePickerBackground = Color(0xFF1E1E1E);
  static const datePickerArrow = Colors.red;
  static const datePickerDayLabel = Colors.white70;
  static const datePickerDaySelected = Colors.red;
  static const datePickerAmPmSelected = Color.fromRGBO(66, 66, 66, 1);
}