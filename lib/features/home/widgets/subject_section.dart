import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SubjectSection extends StatelessWidget {
  const SubjectSection({super.key});

  @override
  Widget build(BuildContext context) {
    const subjects = ['Toán', 'Tiếng Anh', 'Lý', 'Hóa', 'CNTT'];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: subjects
          .map(
            (subject) => InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: subject == 'Tiếng Anh' ? 104 : 72,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.softBorder),
                ),
                child: Text(
                  subject,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
