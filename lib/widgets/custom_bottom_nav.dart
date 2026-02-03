import 'dart:io';
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isAndroid = Platform.isAndroid;
    // Altura base compacta: 40px + padding superior de 5px
    // En Android: 40px + bottomPadding (para safe area) + 10px padding bottom
    // En iOS: 40px + bottomPadding (si existe, para dispositivos con notch)
    final totalHeight = isAndroid 
        ? 40.0 + bottomPadding 
        : 50.0 + (bottomPadding > 0 ? bottomPadding : 0);
    
    Widget content = Container(
      height: totalHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: isAndroid ? 5 : 20,
          bottom: isAndroid ? 10 : (bottomPadding > 0 ? bottomPadding : 0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Regalos
            _buildNavItem(
              index: 0,
              inactiveIcon: Image.asset(
                'assets/images/icons/giftn.png',
                width: 24,
                height: 24,
              ),
              activeIcon: Image.asset(
                'assets/images/icons/gift.png',
                width: 24,
                height: 24,
              ),
            ),
            // Home (Shell)
            _buildNavItem(
              index: 1,
              inactiveIcon: Image.asset(
                'assets/images/icons/shell.png',
                width: 24,
                height: 24,
              ),
              activeIcon: Image.asset(
                'assets/images/icons/shell.png',
                width: 24,
                height: 24,
              ),
            ),
            // Perfil
            _buildNavItem(
              index: 2,
              inactiveIcon: Icon(
                Icons.person_outlined,
                size: 28,
                color: AppColors.textSecondary,
              ),
              activeIcon: Icon(
                Icons.person,
                size: 28,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
    
    // Envolver con SafeArea solo en Android
    if (isAndroid) {
      return SafeArea(
        top: false,
        child: content,
      );
    }
    
    return content;
  }

  Widget _buildNavItem({
    required int index,
    required Widget inactiveIcon,
    required Widget activeIcon,
  }) {
    final isActive = currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          child: Container(
            width: 40,
            height: 40,
            decoration: isActive
                ? BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  )
                : null,
            alignment: Alignment.center,
            child: isActive ? activeIcon : inactiveIcon,
          ),
        ),
      ),
    );
  }
}
