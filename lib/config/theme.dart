// lib/config/theme.dart
import 'package:flutter/material.dart';

enum ScreenSize { mobile, tablet, desktop }

class AppTheme {
  // Brand colors
  static const Color primaryColor = Color(0xFFFF7A2E);
  static const Color secondaryColor = Color(0xFFFF4947);
  static const Color backgroundColor = Color(0xFFFFF8F5);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color successColor = Color(0xFF38A169);
  static const Color warningColor = Color(0xFFD69E2E);

  // Neutral colors
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textMuted = Color(0xFFA0AEC0);
  static const Color dividerColor = Color(0xFFE2E8F0);

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Spacing scale
  static const double space2xs = 4;
  static const double spaceXs = 8;
  static const double spaceSm = 12;
  static const double spaceMd = 16;
  static const double spaceLg = 20;
  static const double spaceXl = 24;
  static const double space2xl = 32;
  static const double space3xl = 48;

  // Get screen size category
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return ScreenSize.mobile;
    } else if (width < tabletBreakpoint) {
      return ScreenSize.tablet;
    } else {
      return ScreenSize.desktop;
    }
  }

  // Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getScreenSize(context) == ScreenSize.mobile;
  }

  // Check if device is tablet
  static bool isTablet(BuildContext context) {
    return getScreenSize(context) == ScreenSize.tablet;
  }

  // Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return getScreenSize(context) == ScreenSize.desktop;
  }

  // Responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.all(spaceMd);
      case ScreenSize.tablet:
        return const EdgeInsets.all(spaceXl);
      case ScreenSize.desktop:
        return const EdgeInsets.all(space2xl);
    }
  }

  // Responsive horizontal padding
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.symmetric(horizontal: spaceMd);
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(horizontal: spaceXl);
      case ScreenSize.desktop:
        return const EdgeInsets.symmetric(horizontal: space2xl);
    }
  }

  // Responsive vertical padding
  static EdgeInsets getResponsiveVerticalPadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.symmetric(vertical: spaceMd);
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(vertical: spaceXl);
      case ScreenSize.desktop:
        return const EdgeInsets.symmetric(vertical: space2xl);
    }
  }

  // Responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.all(spaceXs);
      case ScreenSize.tablet:
        return const EdgeInsets.all(spaceMd);
      case ScreenSize.desktop:
        return const EdgeInsets.all(spaceXl);
    }
  }

  // Responsive card padding
  static EdgeInsets getResponsiveCardPadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.all(spaceSm);
      case ScreenSize.tablet:
        return const EdgeInsets.all(spaceMd);
      case ScreenSize.desktop:
        return const EdgeInsets.all(spaceLg);
    }
  }

  // Responsive font sizes
  static double getHeadlineFontSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 24;
      case ScreenSize.tablet:
        return 28;
      case ScreenSize.desktop:
        return 32;
    }
  }

  static double getTitleFontSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 18;
      case ScreenSize.tablet:
        return 20;
      case ScreenSize.desktop:
        return 22;
    }
  }

  static double getSubtitleFontSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 16;
      case ScreenSize.tablet:
        return 17;
      case ScreenSize.desktop:
        return 18;
    }
  }

  static double getBodyFontSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 14;
      case ScreenSize.tablet:
        return 15;
      case ScreenSize.desktop:
        return 16;
    }
  }

  static double getCaptionFontSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 12;
      case ScreenSize.tablet:
        return 13;
      case ScreenSize.desktop:
        return 14;
    }
  }

  // Responsive button sizes
  static double getButtonHeight(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 48;
      case ScreenSize.tablet:
        return 52;
      case ScreenSize.desktop:
        return 56;
    }
  }

  static EdgeInsets getButtonPadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.symmetric(
            horizontal: spaceMd, vertical: spaceSm);
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(
            horizontal: spaceLg, vertical: spaceMd);
      case ScreenSize.desktop:
        return const EdgeInsets.symmetric(
            horizontal: spaceXl, vertical: spaceMd);
    }
  }

  // Responsive icon sizes
  static double getIconSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 24;
      case ScreenSize.tablet:
        return 28;
      case ScreenSize.desktop:
        return 32;
    }
  }

  static double getSmallIconSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 16;
      case ScreenSize.tablet:
        return 18;
      case ScreenSize.desktop:
        return 20;
    }
  }

  // Responsive card elevation
  static double getCardElevation(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 2;
      case ScreenSize.tablet:
        return 4;
      case ScreenSize.desktop:
        return 6;
    }
  }

  // Responsive border radius
  static double getCardRadius(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 12;
      case ScreenSize.tablet:
        return 14;
      case ScreenSize.desktop:
        return 16;
    }
  }

  static double getButtonRadius(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 8;
      case ScreenSize.tablet:
        return 10;
      case ScreenSize.desktop:
        return 12;
    }
  }

  // Responsive container constraints
  static BoxConstraints getMaxWidthConstraint(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return const BoxConstraints(maxWidth: double.infinity);
      case ScreenSize.tablet:
        return const BoxConstraints(maxWidth: 800);
      case ScreenSize.desktop:
        return const BoxConstraints(maxWidth: 1200);
    }
  }

  // Grid configurations
  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 2;
    if (width < 600) return 2;
    if (width < 900) return 3;
    if (width < 1200) return 4;
    return 5;
  }

  static double getGridChildAspectRatio(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 0.75;
      case ScreenSize.tablet:
        return 0.8;
      case ScreenSize.desktop:
        return 0.85;
    }
  }

  static double getGridSpacing(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return spaceXs;
      case ScreenSize.tablet:
        return spaceSm;
      case ScreenSize.desktop:
        return spaceMd;
    }
  }

  // App bar configuration
  static double getAppBarHeight(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return kToolbarHeight;
      case ScreenSize.tablet:
        return kToolbarHeight + 8;
      case ScreenSize.desktop:
        return kToolbarHeight + 16;
    }
  }

  // Main theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: MaterialColor(
        primaryColor.value,
        <int, Color>{
          50: const Color(0xFFFFF8F5),
          100: const Color(0xFFFFE6D9),
          200: const Color(0xFFFFCCB3),
          300: const Color(0xFFFFB38C),
          400: const Color(0xFFFF9966),
          500: primaryColor,
          600: const Color(0xFFE6692A),
          700: const Color(0xFFCC5925),
          800: const Color(0xFFB34A21),
          900: const Color(0xFF993A1C),
        },
      ),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColor,
      dividerColor: dividerColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        background: backgroundColor,
        surface: surfaceColor,
        error: errorColor,
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceXl,
            vertical: spaceMd,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceXl,
            vertical: spaceMd,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceMd,
            vertical: spaceXs,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      // Card theme
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spaceXs,
          vertical: space2xs,
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceMd,
        ),
        hintStyle: TextStyle(
          color: textMuted,
          fontSize: 14,
        ),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: primaryColor.withOpacity(0.2),
        secondarySelectedColor: primaryColor.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceSm,
          vertical: space2xs,
        ),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.25,
        ),
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),

      // Primary icon theme
      primaryIconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),

      useMaterial3: true,
      fontFamily: 'Inter', // You can customize this
    );
  }

  // Helper method to create responsive text styles
  static TextStyle responsiveTextStyle(
    BuildContext context, {
    required double baseFontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    final screenSize = getScreenSize(context);
    double scaleFactor;

    switch (screenSize) {
      case ScreenSize.mobile:
        scaleFactor = 1.0;
        break;
      case ScreenSize.tablet:
        scaleFactor = 1.1;
        break;
      case ScreenSize.desktop:
        scaleFactor = 1.2;
        break;
    }

    return TextStyle(
      fontSize: baseFontSize * scaleFactor,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // Responsive container decoration
  static BoxDecoration responsiveCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(getCardRadius(context)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: getCardElevation(context) * 2,
          offset: Offset(0, getCardElevation(context)),
        ),
      ],
    );
  }
}
