import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 1200;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  static double getResponsiveWidth(BuildContext context, {required double mobileWidth, double? tabletWidth, double? desktopWidth}) {
    if (isDesktop(context)) {
      return desktopWidth ?? mobileWidth;
    } else if (isTablet(context)) {
      return tabletWidth ?? mobileWidth;
    } else {
      return mobileWidth;
    }
  }

  static int getGridColumns(BuildContext context) {
    if (isDesktop(context)) {
      return 3;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 1;
    }
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.all(32);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(16);
    }
  }

  static double getResponsiveTextSize(BuildContext context, {required double mobileSize, double? tabletSize, double? desktopSize}) {
    if (isDesktop(context)) {
      return desktopSize ?? mobileSize;
    } else if (isTablet(context)) {
      return tabletSize ?? mobileSize;
    } else {
      return mobileSize;
    }
  }
}
