import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/game_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    // Фон профиля
    final backgroundColor = _colorFromId(state.selectedBackground);

    // Аватар и рамка
    final avatar = state.selectedAvatar == 'default'
        ? 'assets/images/avatar_default.png'
        : 'assets/images/avatar_${state.selectedAvatar}.png';
    final frame = state.selectedFrame == 'default'
        ? 'assets/images/frame_default.png'
        : 'assets/images/frame_${state.selectedFrame}.png';

    final nickname = state.nickname;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Аватар с рамкой
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 108,
                        height: 108,
                        child: Image.asset(
                          avatar,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Image.asset(
                      frame,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Ник
              Expanded(
                child: Text(
                  nickname,
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Преобразование ID фона в цвет
  Color _colorFromId(String id) {
    switch (id) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'cyan':
        return Colors.cyan;
      case 'pink':
        return Colors.pink;
      case 'teal':
        return Colors.teal;
      default:
        return const Color(0xFF131F24);
    }
  }
}