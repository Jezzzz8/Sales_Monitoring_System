import 'package:flutter/material.dart';

class Responsive {
  // Screen size detection with orientation consideration
  static bool isMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;
    
    // Adjust thresholds based on orientation
    if (orientation == Orientation.landscape) {
      return width < 900; // More lenient in landscape
    }
    return width < 768;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;
    
    if (orientation == Orientation.landscape) {
      return width >= 900 && width < 1200;
    }
    return width >= 768 && width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;
    
    if (orientation == Orientation.landscape) {
      return width >= 1200;
    }
    return width >= 1024;
  }

  // Orientation detection
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Screen dimensions with orientation awareness
  static double width(BuildContext context) => 
      MediaQuery.of(context).size.width;

  static double height(BuildContext context) => 
      MediaQuery.of(context).size.height;

  static double availableHeight(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final height = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    
    if (orientation == Orientation.landscape) {
      return height - padding.top - padding.bottom;
    }
    return height - padding.top - padding.bottom;
  }

  // Layout configuration with orientation adjustments
  static int getGridCount(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    
    if (isMobile(context)) {
      return orientation == Orientation.landscape ? 3 : 2;
    }
    if (isTablet(context)) {
      return orientation == Orientation.landscape ? 4 : 3;
    }
    return orientation == Orientation.landscape ? 5 : 4;
  }

  static double getCardAspectRatio(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    
    if (isMobile(context)) {
      return orientation == Orientation.landscape ? 1.5 : 1.2;
    }
    if (isTablet(context)) {
      return orientation == Orientation.landscape ? 1.3 : 1.1;
    }
    return orientation == Orientation.landscape ? 1.1 : 1.0;
  }

  static double getCardHeight(BuildContext context, {double multiplier = 1.0}) {
    final orientation = MediaQuery.of(context).orientation;
    
    if (isMobile(context)) {
      return (orientation == Orientation.landscape ? 120 : 150) * multiplier;
    }
    if (isTablet(context)) {
      return (orientation == Orientation.landscape ? 150 : 180) * multiplier;
    }
    return (orientation == Orientation.landscape ? 180 : 200) * multiplier;
  }

  // Spacing and padding with orientation adjustments
  static double getPaddingSize(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    
    if (isMobile(context)) {
      return orientation == Orientation.landscape ? 10.0 : 12.0;
    }
    if (isTablet(context)) {
      return orientation == Orientation.landscape ? 14.0 : 16.0;
    }
    return orientation == Orientation.landscape ? 18.0 : 20.0;
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    final padding = getPaddingSize(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final orientation = MediaQuery.of(context).orientation;
    
    if (orientation == Orientation.landscape) {
      return EdgeInsets.fromLTRB(padding, padding + topPadding, padding, padding * 0.5);
    }
    return EdgeInsets.fromLTRB(padding, padding + topPadding, padding, padding);
  }

  static EdgeInsets getCardPadding(BuildContext context) {
    final padding = getPaddingSize(context);
    final orientation = MediaQuery.of(context).orientation;
    
    if (orientation == Orientation.landscape) {
      return EdgeInsets.symmetric(
        horizontal: padding * 0.6,
        vertical: padding * 0.4,
      );
    }
    return EdgeInsets.all(padding * 0.8);
  }

  // Typography with orientation adjustments
  static double getFontSize(BuildContext context, {double mobile = 12, double tablet = 14, double desktop = 16}) {
    final orientation = MediaQuery.of(context).orientation;
    
    if (isMobile(context)) {
      return orientation == Orientation.landscape ? mobile * 0.9 : mobile;
    }
    if (isTablet(context)) {
      return orientation == Orientation.landscape ? tablet * 0.95 : tablet;
    }
    return orientation == Orientation.landscape ? desktop * 0.95 : desktop;
  }

  static double getTitleFontSize(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    
    if (isMobile(context)) {
      return orientation == Orientation.landscape ? 16 : 18;
    }
    if (isTablet(context)) {
      return orientation == Orientation.landscape ? 18 : 20;
    }
    return orientation == Orientation.landscape ? 22 : 24;
  }

  // Layout helpers for orientation
  static double getMaxContentHeight(BuildContext context, {double subtract = 0}) {
    final available = availableHeight(context);
    final orientation = MediaQuery.of(context).orientation;
    
    if (orientation == Orientation.landscape) {
      return available - subtract * 0.8;
    }
    return available - subtract;
  }

  // DataTable configuration with orientation
  static double getDataTableRowHeight(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    
    if (isMobile(context)) {
      return orientation == Orientation.landscape ? 35 : 40;
    }
    if (isTablet(context)) {
      return orientation == Orientation.landscape ? 42 : 48;
    }
    return orientation == Orientation.landscape ? 50 : 56;
  }

  // Orientation-aware form field sizing
  static double getFormFieldHeight(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    
    if (isMobile(context)) {
      return orientation == Orientation.landscape ? 42 : 48;
    }
    if (isTablet(context)) {
      return orientation == Orientation.landscape ? 46 : 52;
    }
    return orientation == Orientation.landscape ? 50 : 56;
  }

  // Button sizing with orientation
  static double getButtonHeight(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    
    if (isMobile(context)) {
      return orientation == Orientation.landscape ? 40 : 44;
    }
    if (isTablet(context)) {
      return orientation == Orientation.landscape ? 44 : 48;
    }
    return orientation == Orientation.landscape ? 48 : 52;
  }

  // Grid layout with orientation
  static SliverGridDelegate getGridDelegate(BuildContext context, {int? crossAxisCount}) {
    final count = crossAxisCount ?? getGridCount(context);
    final orientation = MediaQuery.of(context).orientation;
    final spacing = getPaddingSize(context);
    
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: count,
      crossAxisSpacing: spacing,
      mainAxisSpacing: orientation == Orientation.landscape ? spacing * 0.8 : spacing,
      childAspectRatio: getCardAspectRatio(context),
    );
  }

  // Orientation-specific layout builders
  static Widget getOrientationAwareLayout(BuildContext context, {
    required Widget portraitChild,
    required Widget landscapeChild,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isLandscape(context)) {
          return landscapeChild;
        }
        return portraitChild;
      },
    );
  }

  // Orientation-based column/row switching
  static Widget getOrientationFlexLayout(BuildContext context, {
    required List<Widget> children,
    bool reverse = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isLandscape(context)) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: reverse ? children.reversed.toList() : children,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: reverse ? children.reversed.toList() : children,
        );
      },
    );
  }

  // Responsive constraints with orientation
  static BoxConstraints getConstraints(BuildContext context, {double? maxWidth}) {
    final width = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;
    
    double effectiveMaxWidth;
    if (maxWidth != null) {
      effectiveMaxWidth = maxWidth;
    } else if (orientation == Orientation.landscape) {
      effectiveMaxWidth = width * 0.95;
    } else {
      effectiveMaxWidth = width * 0.9;
    }
    
    return BoxConstraints(
      maxWidth: effectiveMaxWidth,
      minWidth: width * 0.1,
    );
  }

  // Floating tab/window detection with orientation
  static bool isFloatingWindow(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    
    if (orientation == Orientation.landscape) {
      return size.width < 700 && size.height < 500;
    }
    return size.width < 600 && size.height < 600;
  }

  // Text scaling factor helper with orientation
  static double getTextScaleFactor(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaleFactor;
    final orientation = MediaQuery.of(context).orientation;
    
    if (isMobile(context)) {
      return orientation == Orientation.landscape 
          ? textScale.clamp(0.9, 1.1)
          : textScale.clamp(1.0, 1.2);
    }
    return orientation == Orientation.landscape
        ? textScale.clamp(0.9, 1.2)
        : textScale.clamp(1.0, 1.3);
  }
  
  // Orientation-aware spacing helpers
  static SizedBox getSpacing(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final spacing = getPaddingSize(context);
    
    if (orientation == Orientation.landscape) {
      return SizedBox(height: spacing * 0.8);
    }
    return SizedBox(height: spacing);
  }
  
  static SizedBox getHorizontalSpacing(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final spacing = getPaddingSize(context);
    
    if (orientation == Orientation.landscape) {
      return SizedBox(width: spacing * 1.2);
    }
    return SizedBox(width: spacing);
  }
  
  static SizedBox getSmallSpacing(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final spacing = getPaddingSize(context);
    
    if (orientation == Orientation.landscape) {
      return SizedBox(height: spacing * 0.4);
    }
    return SizedBox(height: spacing * 0.5);
  }
  
  static SizedBox getLargeSpacing(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final spacing = getPaddingSize(context);
    
    if (orientation == Orientation.landscape) {
      return SizedBox(height: spacing * 1.2);
    }
    return SizedBox(height: spacing * 1.5);
  }

  // Get appropriate font weight based on orientation
  static FontWeight getFontWeight(BuildContext context, {FontWeight normal = FontWeight.normal}) {
    if (isLandscape(context)) {
      return normal;
    }
    return normal;
  }

  // Get appropriate icon size based on orientation
  static double getIconSize(BuildContext context, {double multiplier = 1.0}) {
    final orientation = MediaQuery.of(context).orientation;
    double baseSize;
    
    if (isMobile(context)) {
      baseSize = orientation == Orientation.landscape ? 18 : 20;
    } else if (isTablet(context)) {
      baseSize = orientation == Orientation.landscape ? 22 : 24;
    } else {
      baseSize = orientation == Orientation.landscape ? 26 : 28;
    }
    
    return baseSize * multiplier;
  }

  static double getBodyFontSize(BuildContext context) {
    if (isMobile(context)) return 12;
    if (isTablet(context)) return 14;
    return 16;
  }

  static double getSubtitleFontSize(BuildContext context) {
    if (isMobile(context)) return 14;
    if (isTablet(context)) return 16;
    return 18;
  }
}