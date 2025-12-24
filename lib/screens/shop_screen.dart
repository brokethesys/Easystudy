import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // для currentBackground
import '../data/game_state.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  final List<Map<String, dynamic>> backgrounds = const [
    {'id': 'blue', 'color': Colors.blue, 'price': 0},
    {'id': 'green', 'color': Colors.green, 'price': 0},
    {'id': 'purple', 'color': Colors.purple, 'price': 0},
    {'id': 'orange', 'color': Colors.orange, 'price': 0},
    {'id': 'red', 'color': Colors.red, 'price': 300},
    {'id': 'cyan', 'color': Colors.cyan, 'price': 400},
    {'id': 'pink', 'color': Colors.pink, 'price': 500},
    {'id': 'teal', 'color': Colors.teal, 'price': 600},
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    final ownedItems = backgrounds
        .where((bg) => state.ownedBackgrounds.contains(bg['id']))
        .toList();
    final lockedItems = backgrounds
        .where((bg) => !state.ownedBackgrounds.contains(bg['id']))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF131F24), // 🔹 Статичный фон
      appBar: AppBar(
  backgroundColor: backgrounds.firstWhere(
    (bg) => bg['id'] == state.selectedBackground,
    orElse: () => {'color': const Color(0xFF067D06)}, // если вдруг нет совпадения
  )['color'],
  centerTitle: true,
  title: outlinedText('Магазин фонов', fontSize: 20),
  elevation: 0,
  actions: [
    Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Image.asset('assets/images/coin.png', fit: BoxFit.cover),
        ),
        const SizedBox(width: 4),
        outlinedText(
          '${state.coins}',
          fontSize: 16,
          fillColor: Colors.white,
        ),
        const SizedBox(width: 16),
      ],
    ),
  ],
),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSection(context, 'Ваши фоны', ownedItems, true),
            const SizedBox(height: 20),
            _buildSection(context, 'Недоступные', lockedItems, false),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> items,
    bool ownedSection,
  ) {
    final state = context.read<GameState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Center(child: outlinedText(title, fontSize: 20)),
        ),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          itemBuilder: (context, index) {
            final bg = items[index];
            final bool isSelected = state.selectedBackground == bg['id'];
            final bool isOwned = state.ownedBackgrounds.contains(bg['id']);
            final double progress =
                (state.coins / (bg['price'] == 0 ? 1 : bg['price']))
                    .clamp(0, 1)
                    .toDouble();
return GestureDetector(
              onTap: () {
                if (isOwned) {
                  state.selectBackground(bg['id']);
                  currentBackground.value = bg['id'];
                } else {
                  final success = state.buyBackground(bg['id'], bg['price']);
                  if (success) {
                    currentBackground.value = bg['id'];
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: outlinedText(
                          'Фон "${bg['id']}" успешно куплен!',
                          fontSize: 14,
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: outlinedText(
                          'Недостаточно монет 💰',
                          fontSize: 14,
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: bg['color'], // 🔹 Используем цвет фона из массива
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF37464F), // 🔹 Обводка
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    if (!isOwned)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (isOwned)
                              outlinedText(
                                isSelected ? 'Выбран' : 'Доступен',
                                fontSize: 12,
                                fillColor: Colors.white70,
                              )
                            else
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      outlinedText(
                                        '${state.coins}/${bg['price']}',
                                        fontSize: 12,
                                        fillColor: const Color.fromARGB(255, 255, 255, 255),
                                      ), // Зеленый прогресс
                                      const SizedBox(width: 4),
                                      SizedBox(
width: 16,
                                        height: 16,
                                        child: Image.asset(
                                          'assets/images/coin.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: const Color(
                                        0xFF37464F,
                                      ), // Пустая часть
                                      color: const Color(
                                        0xFF58A700,
                                      ), // Заполненная часть
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget outlinedText(
    String text, {
    Color fillColor = Colors.white,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontFamily: 'ClashRoyale',
            fontSize: fontSize,
            fontWeight: fontWeight,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = Colors.black,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'ClashRoyale',
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: fillColor,
          ),
        ),
      ],
    );
  }
}