import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/user_model.dart';
import '../../layouts/main_layout.dart';
import '../onboarding/onboarding_page.dart';

class LoadingVideoPage extends StatefulWidget {
  final UserModel user;
  final bool hasCompletedOnboarding;

  const LoadingVideoPage({
    super.key,
    required this.user,
    required this.hasCompletedOnboarding,
  });

  @override
  State<LoadingVideoPage> createState() => _LoadingVideoPageState();
}

class _LoadingVideoPageState extends State<LoadingVideoPage> {
  late VideoPlayerController _controller;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset(
      'assets/videos/animationShell.mp4',
    );

    await _controller.initialize();

    if (mounted) {
      setState(() {});
      _controller.play();
      _controller.setLooping(false);

      // Escuchar cuando el video termine
      _controller.addListener(_videoListener);
    }
  }

  void _videoListener() {
    if (_controller.value.position >= _controller.value.duration &&
        !_controller.value.isPlaying &&
        !_hasNavigated) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    _controller.removeListener(_videoListener);

    // Navegar después de que termine el video
    if (widget.hasCompletedOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainLayout(user: widget.user)),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OnboardingPage(user: widget.user),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _controller.value.isInitialized
          ? ClipRect(
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator(color: Colors.black)),
    );
  }
}
