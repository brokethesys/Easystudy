import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SubjectMenu {
  static Future<void> show(
    BuildContext context, {
    required BuildContext hudContext,
  }) async {
    final media = MediaQuery.of(context);
    final renderBox = hudContext.findRenderObject() as RenderBox?;
    final hudOffset = renderBox?.localToGlobal(Offset.zero);
    final menuTop = (hudOffset?.dy ?? media.viewPadding.top) +
        (renderBox?.size.height ?? 88);
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Subject menu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        final colors = AppColors.of(context);

        const entry = _SubjectEntry(
          title: 'SOFTWARE ENGINEERING',
          iconPath: 'assets/images/software-application.png',
        );

        final overlayFade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );

        const double menuHeight = 104;

        return Stack(
          children: [
            Positioned.fill(
              top: menuTop,
              child: FadeTransition(
                opacity: overlayFade,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(color: Colors.black54),
                ),
              ),
            ),
            Positioned(
              top: menuTop,
              left: 0,
              right: 0,
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final dy = menuHeight * (1 - animation.value);
                    return Transform.translate(
                      offset: Offset(0, -dy),
                      child: child,
                    );
                  },
                  child: SizedBox(
                    height: menuHeight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.background,
                        border: Border(
                          top: BorderSide(color: colors.track, width: 1),
                        ),
                      ),
                      child: _SubjectRow(
                        entry: entry,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
    );
  }
}

class _SubjectEntry {
  final String title;
  final String iconPath;

  const _SubjectEntry({
    required this.title,
    required this.iconPath,
  });
}

class _SubjectRow extends StatelessWidget {
  final _SubjectEntry entry;
  final VoidCallback onTap;

  const _SubjectRow({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.track, width: 1),
                ),
                child: Center(
                  child: Image.asset(entry.iconPath, width: 40, height: 40),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  entry.title,
                  style: TextStyle(
                    fontFamily: 'ClashRoyale',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
