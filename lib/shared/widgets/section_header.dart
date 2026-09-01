import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Small uppercase-style group label placed above a card group.
///
/// Deliberately quiet: the cards carry the content, this only names them.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
