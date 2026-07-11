import 'package:flutter/material.dart';

import '../../backend/config/app_constants.dart';

/// Bộ màu và widget dùng chung cho khu vực admin SmartDeal Shop.
class AdminTheme {
  AdminTheme._();

  static const Color accent = Color(0xFF24C7E8);
  static const Color accentDark = Color(0xFF1AA8C4);
  static const Color surface = Color(0xFFF4F6F9);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE7EAF0);
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF667085);
  static const Color sidebarBg = Color(0xFFF8FAFC);
  static const EdgeInsets pagePadding =
      EdgeInsets.fromLTRB(28, 24, 28, 40);

  static String formatCurrency(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  }

  static BoxDecoration cardDecoration = BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static InputDecoration inputDecoration({
    String? hint,
    String? label,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: card,
      hintStyle: const TextStyle(fontSize: 13, color: textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
    );
  }
}

class AdminOrderStatusBadge extends StatelessWidget {
  const AdminOrderStatusBadge({super.key, required this.status});

  final String status;

  static ({String label, Color color}) resolve(String status) {
    switch (status) {
      case AppConstants.orderDelivered:
        return (label: 'Đã giao', color: const Color(0xFF12B76A));
      case AppConstants.orderShipping:
        return (label: 'Đang giao', color: const Color(0xFF2E90FA));
      case AppConstants.orderCancelled:
        return (label: 'Đã hủy', color: const Color(0xFFF04438));
      case AppConstants.orderConfirmed:
        return (label: 'Đã xác nhận', color: const Color(0xFF7A5AF8));
      default:
        return (label: 'Chờ xử lý', color: const Color(0xFFF79009));
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolve(status);
    return AdminStatusBadge(label: resolved.label, color: resolved.color);
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: AdminTheme.cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AdminTheme.textSecondary),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(color: AdminTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}

class AdminSecondaryButton extends StatelessWidget {
  const AdminSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.open_in_new, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AdminTheme.textPrimary,
        side: const BorderSide(color: AdminTheme.border),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: AdminTheme.inputDecoration(
        hint: hint,
        prefixIcon: const Icon(Icons.search, size: 20, color: AdminTheme.textSecondary),
      ).copyWith(
        isDense: true,
        suffixIcon: onClear == null
            ? null
            : IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: onClear,
              ),
      ),
    );
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AdminTheme.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AdminTheme.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AdminTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...[
                const SizedBox(width: 12),
                Wrap(spacing: 10, runSpacing: 8, children: actions!),
              ],
            ],
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

class AdminPrimaryButton extends StatelessWidget {
  const AdminPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.add, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AdminTheme.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.trend,
    this.trendUp = true,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? trend;
  final bool trendUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AdminTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AdminTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AdminTheme.accent, size: 20),
              ),
              const Spacer(),
              if (trend != null)
                Text(
                  trend!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: trendUp
                        ? const Color(0xFF12B76A)
                        : const Color(0xFFF04438),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AdminTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AdminTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.background,
  });

  final String label;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AdminTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1, color: AdminTheme.border),
          child,
        ],
      ),
    );
  }
}

class AdminDataTableWrap extends StatelessWidget {
  const AdminDataTableWrap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AdminTheme.cardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.sizeOf(context).width - 320,
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dataTableTheme: const DataTableThemeData(
                  headingRowColor: WidgetStatePropertyAll(Color(0xFFF9FAFB)),
                  headingTextStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.textSecondary,
                  ),
                  dataTextStyle: TextStyle(
                    fontSize: 13,
                    color: AdminTheme.textPrimary,
                  ),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
