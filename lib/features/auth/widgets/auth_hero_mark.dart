import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AuthHeroMark extends StatelessWidget {
  const AuthHeroMark({super.key, required this.isSignUp});

  final bool isSignUp;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 106,
        height: 106,
        decoration: const BoxDecoration(
          color: AppColors.softPrimary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSignUp ? Icons.person_add_alt_1 : Icons.account_balance_wallet,
          color: AppColors.primary,
          size: 48,
        ),
      ),
    );
  }
}
