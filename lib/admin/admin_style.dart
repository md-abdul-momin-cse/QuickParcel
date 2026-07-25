import 'package:flutter/material.dart';

class AdminStyle {
  static const Color primary = Color(0xFF0B7285);
  static const Color appBarColor = Color(0xFF075E6F);
  static const Color primaryDark = Color(0xFF064E5B);
  static const Color accent = Color(0xFF14B8A6);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF162326);
  static const Color lightText = Color(0xFF102A32);
  static const Color darkText = Color(0xFFEAF7FA);
  static const Color lightTextSecondary = Color(0xFF657780);
  static const Color darkTextSecondary = Color(0xFFA9BDC3);
  static const Color lightBorder = Color(0xFFD5E8EC);
  static const Color darkBorder = Color(0xFF2E464D);

  static bool isDark(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor.computeLuminance() < 0.3;
  }

  static Color surface(BuildContext context) {
    return isDark(context) ? darkSurface : lightSurface;
  }

  static Color textPrimary(BuildContext context) {
    return isDark(context) ? darkText : lightText;
  }

  static Color textSecondary(BuildContext context) {
    return isDark(context) ? darkTextSecondary : lightTextSecondary;
  }

  static Color border(BuildContext context) {
    return isDark(context) ? darkBorder : lightBorder;
  }

  static LinearGradient headerGradient(BuildContext context) {
    final dark = isDark(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark
          ? const [Color(0xFF12343B), Color(0xFF0B7285)]
          : const [primaryDark, primary, accent],
    );
  }

  static BoxDecoration cardDecoration(BuildContext context) {
    final dark = isDark(context);
    return BoxDecoration(
      color: surface(context),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: primary.withOpacity(dark ? 0.58 : 0.42),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: primary.withOpacity(dark ? 0.11 : 0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;

  const AdminAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.bottom,
    this.actions,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    82 + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 82,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: AdminStyle.appBarColor,
          boxShadow: [
            BoxShadow(
              color: AdminStyle.primary.withOpacity(0.26),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
      ),
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.26)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.76),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}

class AdminBodySurface extends StatelessWidget {
  final Widget child;

  const AdminBodySurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      width: double.infinity,
      color: AdminStyle.appBarColor,
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AdminStyle.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AdminStyle.primary, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(
                color: AdminStyle.textPrimary(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AdminStyle.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AdminSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AdminStyle.textPrimary(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AdminStyle.textSecondary(context),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
