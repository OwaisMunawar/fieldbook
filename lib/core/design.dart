import 'package:flutter/material.dart';

abstract final class Palette {
  static const ink = Color(0xFF183D3B);
  static const muted = Color(0xFF647571);
  static const paper = Color(0xFFF5F4EE);
  static const accent = Color(0xFFB84B2C);
  static const line = Color(0xFFE0E5DD);
  static const mint = Color(0xFFEAF1E9);
}

ThemeData notebookTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Palette.ink,
    surface: Palette.paper,
    primary: Palette.ink,
    secondary: Palette.accent,
  ),
  scaffoldBackgroundColor: Palette.paper,
  appBarTheme: const AppBarTheme(
    backgroundColor: Palette.paper,
    foregroundColor: Palette.ink,
    centerTitle: false,
  ),
  textTheme: const TextTheme(
    displaySmall: TextStyle(
      fontSize: 36,
      height: 1.12,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.3,
      color: Palette.ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      color: Palette.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: Palette.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Palette.ink,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: Palette.ink),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: Palette.ink),
    bodySmall: TextStyle(fontSize: 12, height: 1.4, color: Palette.muted),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 50),
      side: const BorderSide(color: Palette.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Palette.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Palette.line),
    ),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: Palette.mint,
  ),
);

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Palette.line),
    ),
    child: child,
  );
}

class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.active = false});
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: active ? Palette.mint : Palette.paper,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: active ? Palette.ink : Palette.muted,
      ),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.trailing});
  final String title;
  final String? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: MediaQuery.textScalerOf(context).scale(1) > 1.3
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (trailing != null)
                Text(trailing!, style: Theme.of(context).textTheme.bodySmall),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (trailing != null)
                Flexible(
                  child: Text(
                    trailing!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
  );
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Palette.accent, size: 28),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(message),
      ],
    ),
  );
}

class FailureBanner extends StatelessWidget {
  const FailureBanner({
    super.key,
    required this.message,
    required this.dismiss,
  });
  final String message;
  final VoidCallback dismiss;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFE9DB),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(child: Semantics(liveRegion: true, child: Text(message))),
          IconButton(
            onPressed: dismiss,
            icon: const Icon(Icons.close),
            tooltip: 'Dismiss error',
          ),
        ],
      ),
    ),
  );
}
