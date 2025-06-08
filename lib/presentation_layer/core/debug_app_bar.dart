import 'package:flutter/material.dart';

/// An AppBar that displays the current file name in debug mode
///
/// This AppBar wrapper displays the name of the Dart file that creates it
/// at the center of the AppBar when the app is running in debug mode.
/// This functionality is automatically tied to the debug banner.
class DebugAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool? centerTitle;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;
  final double elevation;
  final Color? foregroundColor;

  /// The name of the file where this widget is used
  /// This should be set to the name of the file that contains the widget
  /// e.g. 'jobs_view.dart'
  final String fileName;

  const DebugAppBar({
    super.key,
    required this.title,
    required this.fileName,
    this.actions,
    this.leading,
    this.centerTitle,
    this.backgroundColor,
    this.bottom,
    this.elevation = 4.0,
    this.foregroundColor,
  });

  /// Creates a DebugAppBar automatically using the current state's runtime type
  /// to determine the file name.
  factory DebugAppBar.forState(
    State state, {
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool? centerTitle,
    Color? backgroundColor,
    PreferredSizeWidget? bottom,
    double elevation = 4.0,
    Color? foregroundColor,
  }) {
    // Get the runtime type as a string, which includes the file name
    final String typeName = state.runtimeType.toString();

    // Try to guess the file name from the state class name
    // This works if you follow standard naming conventions
    String fileName =
        '${_camelToSnake(typeName.replaceAll('_State', ''))}.dart';

    return DebugAppBar(
      title: title,
      fileName: fileName,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      bottom: bottom,
      elevation: elevation,
      foregroundColor: foregroundColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't add debug info to the title, just use the title as is
    final String displayTitle = title;

    return AppBar(
      title: Text(
        displayTitle,
        style: const TextStyle(
          fontSize: 19, // Keep the font size
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      bottom: bottom,
      elevation: elevation,
      foregroundColor: foregroundColor,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  /// Converts camel case to snake case
  /// Example: JobsViewState -> jobs_view_state
  static String _camelToSnake(String text) {
    return text.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => match.start == 0
            ? match.group(0)!.toLowerCase()
            : '_${match.group(0)!.toLowerCase()}');
  }
}

/// Mixin that adds debug information helpers to a State class
mixin DebugInfoMixin<T extends StatefulWidget> on State<T> {
  /// Returns the current file name based on the State class name
  String get currentFileName {
    final String typeName = runtimeType.toString();
    return '${DebugAppBar._camelToSnake(typeName.replaceAll('_State', ''))}.dart';
  }

  /// Creates an AppBar with the file name in debug mode
  DebugAppBar createDebugAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool? centerTitle,
    Color? backgroundColor,
    PreferredSizeWidget? bottom,
    double elevation = 4.0,
    Color? foregroundColor,
  }) {
    return DebugAppBar(
      title: title,
      fileName: currentFileName,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      bottom: bottom,
      elevation: elevation,
      foregroundColor: foregroundColor,
    );
  }
}
