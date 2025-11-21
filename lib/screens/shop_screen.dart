import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // для currentBackground, если нужен
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

  final List<Map<String, dynamic>> frames = const [
    {'id': 'default', 'price': 0},
    {'id': 'gold', 'price': 300},
    {'id': 'silver', 'price': 200},
    {'id': 'bronze', 'price': 100},
  ];

  final List<Map<String, dynamic>> avatars = const [
    {'id': 'default', 'price': 0},
    {'id': 'wizard', 'price': 300},
    {'id': 'knight', 'price': 400},
    {'id': 'archer', 'price': 500},
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    final ownedBackgrounds = backgrounds
        .where((bg) => state.ownedBackgrounds.contains(bg['id']))
        .toList();
    final lockedBackgrounds = backgrounds
        .where((bg) => !state.ownedBackgrounds.contains(bg['id']))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF131F24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF067D06),
        centerTitle: true,
        title: outlinedText('Магазин', fontSize: 20),
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
              outlinedText('${state.coins}', fontSize: 16, fillColor: Colors.white),
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
            _buildSection(context, 'Фоны', backgrounds, state.selectedBackground, state.ownedBackgrounds, (id) => state.selectBackground(id), (id, price) => state.buyBackground(id, price)),
            const SizedBox(height: 20),
            _buildSection(context, 'Рамки', frames, state.selectedFrame, state.ownedFrames, (id) => state.selectFrame(id), (id, price) => state.buyFrame(id, price)),
            const SizedBox(height: 20),
            _buildSection(context, 'Аватары', avatars, state.selectedAvatar, state.ownedAvatars, (id) => state.selectAvatar(id), (id, price) => state.buyAvatar(id, price)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> items,
    String selectedId,
    List<String> ownedIds,
    Function(String) selectFunc,
    bool Function(String, int) buyFunc,
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
            final item = items[index];
            final bool isOwned = ownedIds.contains(item['id']);final bool isSelected = selectedId == item['id'];
            final int price = item['price'] ?? 0;

            double progress = isOwned ? 1.0 : (state.coins / (price == 0 ? 1 : price)).clamp(0, 1).toDouble();

            return GestureDetector(
              onTap: () {
                if (isOwned) {
                  selectFunc(item['id']);
                } else {
                  final success = buyFunc(item['id'], price);
                  if (success) {
                    selectFunc(item['id']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: outlinedText('Вы купили ${item['id']}!', fontSize: 14),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: outlinedText('Недостаточно монет 💰', fontSize: 14),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: item['color'] ?? Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF37464F),
                    width: isSelected ? 3 : 1.5,
                  ),
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
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
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
                            isOwned
                                ? outlinedText(
                                    isSelected ? 'Выбран' : 'Доступен',
                                    fontSize: 12,
                                    fillColor: Colors.white70,
                                  )
                                : Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          outlinedText('${state.coins}/$price', fontSize: 12, fillColor: Colors.white),
                                          const SizedBox(width: 4),
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: Image.asset('assets/images/coin.png', fit: BoxFit.cover),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),child: LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: const Color(0xFF37464F),
                                          color: const Color(0xFF58A700),
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