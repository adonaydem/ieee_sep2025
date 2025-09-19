import 'package:flutter/material.dart';

class RisingTideBottomBar extends StatefulWidget {
  const RisingTideBottomBar({
    Key? key,
    required this.isRecording,
    required this.isLoading,
    required this.onHomeTap,
    required this.onChatTap,
    required this.onSettingsTap,
    required this.onAvatarTap,
    required this.onMicPressed,
  }) : super(key: key);

  final bool isRecording;
  final bool isLoading;
  final VoidCallback onHomeTap;
  final VoidCallback onChatTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onAvatarTap;
  final VoidCallback onMicPressed;

  @override
  _RisingTideBottomBarState createState() => _RisingTideBottomBarState();
}

class _RisingTideBottomBarState extends State<RisingTideBottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // slow, casual spin
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavButton(icon: Icons.home, onTap: widget.onHomeTap),
            _NavButton(icon: Icons.chat, onTap: widget.onChatTap),
            _MetallicMicButton(
              isRecording: widget.isRecording,
              isLoading: widget.isLoading,
              onMicPressed: widget.onMicPressed,
              controller: _controller,
            ),
            _NavButton(icon: Icons.settings, onTap: widget.onSettingsTap),
            _AvatarButton(onTap: widget.onAvatarTap),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: const Color(0xFFFFF8E1),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(icon, color: Colors.black54, size: 28),
        ),
      ),
    );
  }
}

class _MetallicMicButton extends StatelessWidget {
  const _MetallicMicButton({
    required this.isRecording,
    required this.isLoading,
    required this.onMicPressed,
    required this.controller,
  });

  final bool isRecording;
  final bool isLoading;
  final VoidCallback onMicPressed;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating metallic border
          RotationTransition(
            turns: controller,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade300,
                    Colors.grey.shade100,
                    Colors.grey.shade300,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          if (isLoading)
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(
                    isRecording ? Colors.red : Colors.blueGrey),
              ),
            ),
          Material(
            shape: const CircleBorder(),
            color: Colors.white,
            elevation: 6,
            child: IconButton(
              iconSize: 40,
              onPressed: isLoading ? null : onMicPressed,
              icon: Icon(
                isLoading
                    ? Icons.autorenew
                    : (isRecording ? Icons.stop : Icons.mic),
                color: isRecording ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: const Color(0xFFFFF8E1),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: const CircleAvatar(
            backgroundImage: AssetImage('assets/images/avatar.jpg'),
          ),
        ),
      ),
    );
  }
}
