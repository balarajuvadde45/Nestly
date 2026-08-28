import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class Responsive {
  Responsive._();

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppConstants.mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= AppConstants.mobileBreakpoint &&
        w < AppConstants.tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppConstants.tabletBreakpoint;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppConstants.mobileBreakpoint;

  static double contentPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= AppConstants.tabletBreakpoint) return 32;
    if (w >= AppConstants.mobileBreakpoint) return 24;
    if (w < 360) return 12;
    return 16;
  }

  static int gridColumns(
    BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= AppConstants.tabletBreakpoint) return desktop;
    if (w >= AppConstants.mobileBreakpoint) return tablet;
    if (w < 340) return 1;
    return mobile;
  }

  /// Product grid aspect — slightly taller cards on narrow phones.
  static double productAspect(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 360) return 0.58;
    if (w < AppConstants.mobileBreakpoint) return 0.62;
    if (w < AppConstants.tabletBreakpoint) return 0.68;
    return 0.72;
  }

  static double pageMaxWidth(BuildContext context) {
    if (isDesktop(context)) return AppConstants.maxContentWidth;
    if (isTablet(context)) return 900;
    return double.infinity;
  }

  static Widget constrained({
    required Widget child,
    double maxWidth = AppConstants.maxContentWidth,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  /// Auth / forms: comfortable readable column on all screens.
  static Widget formShell({
    required Widget child,
    double maxWidth = 440,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hPad = contentPadding(context);
        return Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: hPad,
              vertical: isMobile(context) ? 12 : 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                minHeight: constraints.maxHeight -
                    MediaQuery.paddingOf(context).vertical -
                    48,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
