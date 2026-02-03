import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // для currentBackground
import '../data/game_state.dart';
import '../theme/app_theme.dart';

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
    final colors = AppColors.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final ownedItems = backgrounds
        .where((bg) => state.ownedBackgrounds.contains(bg['id']))
        .toList();
    final lockedItems = backgrounds
        .where((bg) => !state.ownedBackgrounds.contains(bg['id']))
        .toList();

    // Адаптивные размеры
    final itemSpacing = screenWidth * 0.03; // 3% от ширины экрана
    final itemSize = screenWidth * 0.2; // 20% от ширины экрана (для 4 колонок)
    final paddingHorizontal = screenWidth * 0.04; // 4% от ширины экрана
    final sectionSpacing = screenHeight * 0.02; // 2% от высоты экрана
    final titleFontSize = screenWidth * 0.05; // 5% от ширины экрана
    final coinFontSize = screenWidth * 0.04; // 4% от ширины экрана

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Адаптивный AppBar
            Container(
              height: 56,
              color: colors.background,
              padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'МАГАЗИН',
                        style: TextStyle(
                          fontFamily: 'ClashRoyale',
                          fontSize: titleFontSize.clamp(16, 22),
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: screenWidth * 0.05,
                        height: screenWidth * 0.05,
                        child: Image.asset('assets/images/coin.png', fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${state.coins}',
                        style: TextStyle(
                          fontFamily: 'ClashRoyale',
                          fontSize: coinFontSize.clamp(14, 18),
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Разделительная линия
            Container(
              color: colors.border,
              height: 1.0,
            ),
            
            // Контент с прокруткой
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(paddingHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSection(
                      context, 
                      'Ваши фоны', 
                      ownedItems, 
                      true, 
                      screenWidth, 
                      itemSize, 
                      itemSpacing,
                      titleFontSize,
                    ),
                    SizedBox(height: sectionSpacing * 2),
                    _buildSection(
                      context, 
                      'Недоступные', 
                      lockedItems, 
                      false, 
                      screenWidth, 
                      itemSize, 
                      itemSpacing,
                      titleFontSize,
                    ),
                    SizedBox(height: screenHeight * 0.05), // Отступ снизу
                  ],
                ),
              ),
            ),
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
    double screenWidth,
    double itemSize,
    double itemSpacing,
    double titleFontSize,
  ) {
    final state = context.read<GameState>();
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: itemSpacing),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'ClashRoyale',
              fontSize: titleFontSize.clamp(16, 20),
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
        
        if (items.isEmpty)
          Container(
            height: itemSize * 1.5,
            alignment: Alignment.center,
            child: Text(
              ownedSection ? 'Нет доступных фонов' : 'Все фоны доступны!',
              style: TextStyle(
                fontFamily: 'ClashRoyale',
                fontSize: screenWidth * 0.04,
                color: colors.textSecondary,
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              // Автоматический расчет количества колонок в зависимости от ширины экрана
              final itemWidth = itemSize;
              final availableWidth = constraints.maxWidth;
              final crossAxisCount = (availableWidth / (itemWidth + itemSpacing)).floor();
              final actualCount = crossAxisCount.clamp(3, 5); // Минимум 3, максимум 5 колонок
              final actualItemSize = (availableWidth - (itemSpacing * (actualCount - 1))) / actualCount;
              
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: actualCount,
                  crossAxisSpacing: itemSpacing,
                  mainAxisSpacing: itemSpacing,
                  childAspectRatio: 0.7, // Оптимальное соотношение для карточек
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
                                  fontSize: screenWidth * 0.035,
                                  color: colors.textPrimary,
                                ),
                              ),
                              backgroundColor: colors.surface,
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
                                  fontSize: screenWidth * 0.035,
                                  color: colors.textPrimary,
                                ),
                              ),
                              backgroundColor: colors.surface,
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
                          color: isSelected ? Colors.amber : colors.track,
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
                            height: actualItemSize * 0.7, // Адаптивная высота
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
                                    child: Icon(
                                      Icons.lock,
                                      color: Colors.white70,
                                  size: screenWidth * 0.06, // Адаптивный размер иконки
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
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: screenWidth * 0.06, // Адаптивный размер иконки
                                    ),
                                  )
                                : null,
                          ),

                          // 🔹 Нижняя часть с информацией
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                vertical: actualItemSize * 0.05,
                                horizontal: actualItemSize * 0.04,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceAlt,
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
                                        fontSize: screenWidth * 0.025,
                                        color: isSelected
                                            ? Colors.amber
                                            : colors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                                fontSize: screenWidth * 0.03,
                                                color: colors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(width: screenWidth * 0.005),
                                            SizedBox(
                                              width: screenWidth * 0.035,
                                              height: screenWidth * 0.035,
                                              child: Image.asset(
                                                'assets/images/coin.png',
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: actualItemSize * 0.02),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: colors.track,
                                            color: const Color(0xFF58A700),
                                            minHeight: screenWidth * 0.015,
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
