import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../widgets/custom_bottom_nav.dart';
import '../pages/home/home.dart';
import '../pages/gifts/gifts_page.dart';
import '../pages/profile/profile_page.dart';

class MainLayout extends StatefulWidget {
  final UserModel user;

  const MainLayout({super.key, required this.user});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 1; // Home está en el índice 1
  late PageController _pageController;
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _currentUser = widget.user;
  }

  void _onUserUpdated(UserModel updatedUser) {
    setState(() {
      _currentUser = updatedUser;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 56,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Image.asset(
            'assets/images/brand/logo-2.png',
            height: 18,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
          ),
        ),
        centerTitle: false,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          // Página 0: Regalos
          GiftsPage(user: _currentUser, onUserUpdated: _onUserUpdated),
          // Página 1: Home
          ClubShellHome(user: _currentUser, onUserUpdated: _onUserUpdated),
          // Página 2: Perfil
          ProfilePage(user: _currentUser, onUserUpdated: _onUserUpdated),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        user: _currentUser,
      ),
    );
  }
}
