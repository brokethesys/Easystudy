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
    {'id': 'amber', 'color': Colors.amber, 'price': 700},
    {'id': 'deepPurple', 'color': Colors.deepPurple, 'price': 800},
    {'id': 'lightBlue', 'color': Colors.lightBlue, 'price': 900},
    {'id': 'lime', 'color': Colors.lime, 'price': 1000},
    {'id': 'indigo', 'color': Colors.indigo, 'price': 1100},
    {'id': 'deepOrange', 'color': Colors.deepOrange, 'price': 1200},
    {'id': 'brown', 'color': Colors.brown, 'price': 1300},
    {'id': 'blueGrey', 'color': Colors.blueGrey, 'price': 1400},
    {'id': 'gradient1', 'color': null, 'price': 1500}, // Градиент 1
    {'id': 'gradient2', 'color': null, 'price': 1600}, // Градиент 2
    {'id': 'gradient3', 'color': null, 'price': 1700}, // Градиент 3
    {'id': 'gradient4', 'color': null, 'price': 1800}, // Градиент 4
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
          orElse: () => {
            'color': const Color(0xFF067D06),
          }, // если вдруг нет совпадения
        )['color'],
        centerTitle: true,
        title: Text(
          'Магазин фонов',
          style: TextStyle(
            fontFamily: 'ClashRoyale',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
              Text(
                '${state.coins}',
                style: TextStyle(
                  fontFamily: 'ClashRoyale',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'ClashRoyale',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65, // Уменьшил для компактности
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
                        content: Text(
                          'Фон "${_getBackgroundName(bg['id'])}" успешно куплен!',
                          style: TextStyle(
                            fontFamily: 'ClashRoyale',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Недостаточно монет 💰',
                          style: TextStyle(
                            fontFamily: 'ClashRoyale',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.amber : const Color(0xFF37464F),
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 🔹 Квадратная верхняя часть (превью фона)
                    Container(
                      height: 85, // Фиксированная высота для квадрата
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: bg['color'] != null ? bg['color'] : null,
                        gradient: bg['color'] == null
                            ? _getGradient(bg['id'])
                            : null,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: !isOwned
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                              ),
                              child: const Icon(
                                Icons.lock,
                                color: Colors.white70,
                                size: 24,
                              ),
                            )
                          : isSelected
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 24,
                              ),
                            )
                          : null,
                    ),

                    // 🔹 Нижняя часть с информацией
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (isOwned)
                              Text(
                                isSelected ? 'ВЫБРАН' : 'ДОСТУПЕН',
                                style: TextStyle(
                                  fontFamily: 'ClashRoyale',
                                  fontSize: 11,
                                  color: isSelected
                                      ? Colors.amber
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              )
                            else
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${bg['price']}',
                                        style: TextStyle(
                                          fontFamily: 'ClashRoyale',
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: Image.asset(
                                          'assets/images/coin.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
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

  // Функция для получения градиента по id
  Gradient? _getGradient(String id) {
    switch (id) {
      case 'gradient1':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple, Colors.pink, Colors.orange],
        );
      case 'gradient2':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.green],
        );
      case 'gradient3':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red, Colors.yellow],
        );
      case 'gradient4':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal, Colors.indigo, Colors.purple],
        );
      default:
        return null;
    }
  }

  // Функция для получения читаемого имени фона (используется только в SnackBar)
  String _getBackgroundName(String id) {
    switch (id) {
      case 'blue':
        return 'Синий';
      case 'green':
        return 'Зеленый';
      case 'purple':
        return 'Фиолетовый';
      case 'orange':
        return 'Оранжевый';
      case 'red':
        return 'Красный';
      case 'cyan':
        return 'Бирюзовый';
      case 'pink':
        return 'Розовый';
      case 'teal':
        return 'Тиаровый';
      case 'amber':
        return 'Янтарный';
      case 'deepPurple':
        return 'Темно-фиолетовый';
      case 'lightBlue':
        return 'Светло-синий';
      case 'lime':
        return 'Лаймовый';
      case 'indigo':
        return 'Индиго';
      case 'deepOrange':
        return 'Темно-оранжевый';
      case 'brown':
        return 'Коричневый';
      case 'blueGrey':
        return 'Серо-синий';
      case 'gradient1':
        return 'Радуга';
      case 'gradient2':
        return 'Океан';
      case 'gradient3':
        return 'Закат';
      case 'gradient4':
        return 'Сумерки';
      default:
        return id;
    }
  }
}
