import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final UserModel user;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    // Nuevo diseño: Regalos, Home (Shell), Perfil
    List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(
        icon: Image.asset(
          'assets/images/icons/giftn.png',
          width: 22,
          height: 22,
        ),
        activeIcon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Image.asset(
              'assets/images/icons/gift.png',
              width: 22,
              height: 22,
            ),
          ),
        ),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: Container(
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            'assets/images/icons/shell.png',
            width: 28,
            height: 28,
          ),
        ),
        activeIcon: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Image.asset(
            'assets/images/icons/shell.png',
            width: 28,
            height: 28,
          ),
        ),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outlined, size: 28),
        activeIcon: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person, size: 28, color: AppColors.secondary),
        ),
        label: '',
      ),
    ];

    return Container(
      padding: const EdgeInsets.only(top: 6),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Colors.white,
        elevation: 8,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: items,
      ),
    );
  }
}
