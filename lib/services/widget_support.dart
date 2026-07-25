import 'package:flutter/material.dart';
import 'package:quick_parcel/services/app_theme.dart';

bool _isDarkMode() {
  return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
      Brightness.dark;
}

Color _primaryColor() {
  return _isDarkMode() ? AppTheme.darkPrimary : AppTheme.lightPrimary;
}

Color _surfaceColor() {
  return _isDarkMode() ? AppTheme.darkSurface : AppTheme.lightSurface;
}

Color _surfaceAltColor() {
  return _isDarkMode() ? AppTheme.darkSurfaceAlt : AppTheme.lightSurfaceAlt;
}

Color _textPrimaryColor() {
  return _isDarkMode() ? AppTheme.darkText : AppTheme.lightText;
}

Color _textSecondaryColor() {
  return _isDarkMode()
      ? AppTheme.darkTextSecondary
      : AppTheme.lightTextSecondary;
}

Color _borderColor() {
  return _isDarkMode() ? AppTheme.darkBorder : AppTheme.lightBorder;
}

Color _shadowColor() {
  return _isDarkMode()
      ? Colors.black.withOpacity(0.4)
      : Colors.black.withOpacity(0.1);
}

Color _shadowSoftColor() {
  return _isDarkMode()
      ? Colors.black.withOpacity(0.2)
      : Colors.black.withOpacity(0.02);
}

Color _inputFillColor() {
  return _isDarkMode() ? AppTheme.darkInput : AppTheme.lightInput;
}

class AppWidget {
  static Color get surfaceColor => _surfaceColor();
  static Color get surfaceAltColor => _surfaceAltColor();
  static Color get primaryColor => _primaryColor();
  static Color get textPrimaryColor => _textPrimaryColor();
  static Color get textSecondaryColor => _textSecondaryColor();
  static Color get borderColor => _borderColor();
  static Color get shadowColor => _shadowColor();
  static Color get inputFillColor => _inputFillColor();

  static TextStyle GreenTextfeildStyle(double textsize) {
    return TextStyle(
      color: _primaryColor(),
      fontSize: textsize,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle BoldGreenTextfeildStyle(double textsize) {
    return TextStyle(
      color: _primaryColor(),
      fontSize: textsize,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle WhiteHeadlineTextStyle(double textsize) {
    return TextStyle(
      color: Colors.white,
      fontSize: textsize,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle boldTextFieldStyle(double textsize) {
    return TextStyle(
      color: _textPrimaryColor(),
      fontSize: textsize,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle LightTextFieldStyle(double textsize) {
    return TextStyle(
      color: _textSecondaryColor(),
      fontSize: textsize,
      fontWeight: FontWeight.w400,
    );
  }

  static Widget primaryActionButton({
    required BuildContext context,
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
    Color? color,
    IconData icon = Icons.arrow_forward_rounded,
    double? width,
  }) {
    final theme = Theme.of(context);
    final primary = color ?? theme.primaryColor;
    final isDisabled = onPressed == null || loading;
    final effectivePrimary = isDisabled
        ? primary.withOpacity(0.55)
        : primary;

    return Center(
      child: Container(
        width: width ?? MediaQuery.of(context).size.width / 1.55,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              effectivePrimary.withOpacity(0.94),
              effectivePrimary,
              effectivePrimary.withOpacity(0.78),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: effectivePrimary.withOpacity(
                theme.brightness == Brightness.dark ? 0.34 : 0.28,
              ),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: Icon(icon, color: Colors.white, size: 17),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // trust indicators
  static Widget buildTrustBadge(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isDarkMode()
                ? AppTheme.darkSurface.withOpacity(0.6)
                : Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: _isDarkMode() ? AppTheme.darkText : Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  static Widget buildPremiumOfferItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required List<Color> gradient,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor(), width: 2),
        boxShadow: [
          BoxShadow(
            color: _shadowColor(),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: AppTheme.darkText, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: gradient[0],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textPrimaryColor(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: _textSecondaryColor()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //SendPackageTextfield
  static Widget SendPackageTextfield({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: _inputFillColor(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isDarkMode()
              ? Colors.white.withOpacity(0.14)
              : const Color(0xFF172F35).withOpacity(0.72),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode()
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 15,
          color: _textPrimaryColor(),
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.transparent,
          hintStyle: TextStyle(
            color: _textSecondaryColor(),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            icon,
            color: _primaryColor().withOpacity(_isDarkMode() ? 0.8 : 0.65),
            size: 22,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 17,
          ),
        ),
      ),
    );
  }

  static Widget FormTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    String? label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onSubmitted,
  }) {
    final field = Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: _inputFillColor(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isDarkMode()
              ? Colors.white.withOpacity(0.14)
              : const Color(0xFF172F35).withOpacity(0.72),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode()
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onSubmitted: onSubmitted,
        style: TextStyle(
          fontSize: 15,
          color: _textPrimaryColor(),
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.transparent,
          hintStyle: TextStyle(
            color: _textSecondaryColor(),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            icon,
            color: _primaryColor().withOpacity(_isDarkMode() ? 0.8 : 0.65),
            size: 22,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 17,
          ),
        ),
      ),
    );

    if (label == null || label.trim().isEmpty) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _primaryColor(),
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  static Widget HomePagebuildMenuCard({
    required String imagePath,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceAltColor(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _primaryColor().withOpacity(0.22),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 64, height: 64, fit: BoxFit.contain),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                color: _primaryColor(),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  Profile Page Widgets

class ProfilePageWidgets {
  static Color get _primary => _primaryColor();

  // Default Avatar Widget
  static Widget defaultAvatar() => Container(
    color: _surfaceAltColor(),
    child: Icon(Icons.person_rounded, size: 52, color: _primary),
  );

  // Stat Chip Widget
  static Widget statChip({required IconData icon, required String label}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _isDarkMode()
              ? AppTheme.darkSurface.withOpacity(0.6)
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isDarkMode()
                ? AppTheme.darkBorder
                : Colors.white.withOpacity(0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _isDarkMode() ? AppTheme.darkText : Colors.white,
              size: 13,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: _isDarkMode() ? AppTheme.darkText : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );

  // Section Title Widget
  static Widget sectionTitle(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primary, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _textPrimaryColor(),
            letterSpacing: 0.3,
          ),
        ),
      ],
    ),
  );

  // Card Widget
  static Widget card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _surfaceColor(),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: _shadowColor(),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: _shadowSoftColor(),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );

  // Info Display Tile
  static Widget infoDisplayTile({
    required String label,
    required String value,
    required IconData icon,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    decoration: BoxDecoration(
      color: _surfaceAltColor(),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: _borderColor(), width: 1.2),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: _textSecondaryColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: _textPrimaryColor(),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // Readonly Field Widget
  static Widget readonlyField({
    required String value,
    required String label,
    required IconData icon,
    bool isVerified = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    decoration: BoxDecoration(
      color: _surfaceAltColor(),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: _borderColor(), width: 1.2),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: _textSecondaryColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: _textPrimaryColor(),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        if (isVerified) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50),
                  size: 13,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Verified',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  // Settings Tile Widget
  static Widget settingsTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: _textPrimaryColor(),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _textSecondaryColor(),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _surfaceAltColor(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              color: _textSecondaryColor(),
              size: 13,
            ),
          ),
        ],
      ),
    ),
  );

  // Divider Widget
  static Widget divider() =>
      Divider(color: _borderColor(), height: 1, thickness: 1);

  // Password Field Widget
  static Widget pwField({
    required TextEditingController ctrl,
    required String label,
    required bool show,
    required VoidCallback toggle,
  }) => TextField(
    controller: ctrl,
    obscureText: !show,
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: _textPrimaryColor(),
    ),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: _textSecondaryColor(),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: _inputFillColor(),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _primary, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _primary.withOpacity(0.15)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: IconButton(
        icon: Icon(
          show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: _primary,
          size: 20,
        ),
        onPressed: toggle,
      ),
    ),
  );

  // Notification Tile Widget
  static Widget notifTile({
    required BuildContext ctx,
    required StateSetter setLocal,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textPrimaryColor(),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: _textSecondaryColor()),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: _primary,
        ),
      ],
    ),
  );

  // Privacy Section Widget
  static Widget privacySection(String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _textPrimaryColor(),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: TextStyle(
            fontSize: 13,
            height: 1.65,
            color: _textSecondaryColor(),
          ),
        ),
      ],
    ),
  );

  // FAQ Tile Widget
  static Widget faqTile(
    BuildContext context, {
    required String question,
    required String answer,
  }) => Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _surfaceAltColor(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor()),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        iconColor: _primary,
        collapsedIconColor: _textSecondaryColor(),
        title: Text(
          question,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _textPrimaryColor(),
          ),
        ),
        children: [
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: _textSecondaryColor(),
            ),
          ),
        ],
      ),
    ),
  );

  // Contact Tile Widget
  static Widget contactTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: _surfaceAltColor(),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _borderColor()),
    ),
    child: Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textSecondaryColor(),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textPrimaryColor(),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  // Edit Field Widget
  static Widget editField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) => TextField(
    controller: ctrl,
    keyboardType: keyboardType,
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: _textPrimaryColor(),
      letterSpacing: 0.1,
    ),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: _textSecondaryColor(),
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
      prefixIcon: Icon(icon, color: _primary, size: 20),
      filled: true,
      fillColor: _inputFillColor(),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _primary, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _primary.withOpacity(0.15)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}

// My Packages Page Widgets

class MyPackagesWidgets {
  static Color get _primary => _primaryColor();

  // Status Badge
  static Widget statusBadge({
    required String status,
    required Color statusColor,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: statusColor.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: statusColor.withOpacity(0.4)),
    ),
    child: Text(
      status,
      style: TextStyle(
        color: statusColor,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    ),
  );

  // Route Row Widget
  static Widget routeRow({required String pickup, required String dropoff}) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // dot column
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              Container(width: 2, height: 28, color: _borderColor()),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pickup.isNotEmpty ? pickup : 'Pickup location',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textPrimaryColor(),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  dropoff.isNotEmpty ? dropoff : 'Dropoff location',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  // Detail Chip Widget
  static Widget detailChip({required IconData icon, required String label}) =>
      label.isEmpty
      ? const SizedBox.shrink()
      : Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _inputFillColor(),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _primary.withOpacity(0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: _primary.withOpacity(0.7)),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _textSecondaryColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

  // Empty State Widget
  static Widget emptyState({required IconData icon, required String message}) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: _primary.withOpacity(0.5)),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: _textSecondaryColor(),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );

  // Package Image with Primary Color Overlay
  static Widget packageImage(String imageUrl) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: ColorFiltered(
      colorFilter: ColorFilter.mode(
        _primary.withOpacity(0.25),
        BlendMode.overlay,
      ),
      child: Image.network(
        imageUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                color: _primary.withOpacity(0.5),
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'Image not available',
                style: TextStyle(
                  color: _primary.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _surfaceAltColor(),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: CircularProgressIndicator(color: _primary)),
          );
        },
      ),
    ),
  );
}

// Manage Parcels Widgets

class SendPackageWidgets {
  static Color get _primary => _primaryColor();

  // Bottom Navigation Bar
  static Widget buildBottomNavBar({
    required int selectedIndex,
    required Function(int) onTap,
  }) => Container(
    decoration: BoxDecoration(
      color: _surfaceColor(),
      boxShadow: [
        BoxShadow(
          color: _shadowColor(),
          blurRadius: 20,
          offset: const Offset(0, -5),
        ),
      ],
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(25),
        topRight: Radius.circular(25),
      ),
    ),
    child: ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(25),
        topRight: Radius.circular(25),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: _surfaceColor(),
        selectedItemColor: _primary,
        unselectedItemColor: _textSecondaryColor(),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 40),
            activeIcon: Icon(Icons.home, size: 40),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'images/send_package.png',
              height: 34,
              width: 34,
              color: _textSecondaryColor(),
            ),
            activeIcon: Image.asset(
              'images/send_package.png',
              height: 34,
              width: 34,
              color: _primary,
            ),
            label: 'Send',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'images/live_traking.png',
              height: 34,
              width: 34,
              color: _textSecondaryColor(),
            ),
            activeIcon: Image.asset(
              'images/live_traking.png',
              height: 34,
              width: 34,
              color: _primary,
            ),
            label: 'Tracking',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'images/my_package.png',
              height: 34,
              width: 34,
              color: _textSecondaryColor(),
            ),
            activeIcon: Image.asset(
              'images/my_package.png',
              height: 34,
              width: 34,
              color: _primary,
            ),
            label: 'Packages',
          ),
        ],
      ),
    ),
  );

  // Delivery Type Card
  static Widget buildDeliveryTypeCard({
    required String imagePath,
    required String title,
    required VoidCallback onTap,
  }) {
    final headerGradient = _isDarkMode()
        ? [AppTheme.darkSurface, AppTheme.darkSurface.withOpacity(0.85)]
        : [const Color(0xFFE8F5F7), const Color(0xFFD0EAEF)];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceColor(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primary.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                height: 100,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: headerGradient,
                  ),
                ),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        title.contains('Send')
                            ? Icons.upload_outlined
                            : Icons.download_outlined,
                        size: 36,
                        color: _primary,
                      ),
                    );
                  },
                ),
              ),
            ),
            // Title with arrow
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: _primary, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Popular Ways Section
  static Widget buildPopularWaysSection({
    required String title,
    required List<Map<String, dynamic>> items,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _surfaceAltColor(),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _primary.withOpacity(0.2), width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _primary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: items.map((item) {
            return buildPopularItem(
              icon: item['icon'] as IconData,
              label: item['label'] as String,
            );
          }).toList(),
        ),
      ],
    ),
  );

  // Popular Item
  static Widget buildPopularItem({
    required IconData icon,
    required String label,
  }) => SizedBox(
    width: 130,
    child: Row(
      children: [
        Icon(icon, color: _primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: _textSecondaryColor(), fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  // Section Header with Icon and Title
  static Widget buildSectionHeader({
    required String title,
    required IconData icon,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    child: Row(
      children: [
        Icon(icon, color: _primary, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: _primary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  // Search Bar
  static Widget buildSearchBar({required VoidCallback onTap}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _surfaceColor(),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _primary.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: _primary, size: 24),
            const SizedBox(width: 12),
            Text(
              'Deliver to?',
              style: TextStyle(
                color: _textSecondaryColor(),
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
