import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/game_state.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<String> avatarPaths = [];
  List<String> framePaths = [];
  List<String> backgroundPaths = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final manifestContent = await DefaultAssetBundle.of(
      context,
    ).loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    setState(() {
      avatarPaths = manifestMap.keys
          .where((key) => key.startsWith('assets/images/avatars/'))
          .toList();
      framePaths = manifestMap.keys
          .where((key) => key.startsWith('assets/images/frames/'))
          .toList();
      backgroundPaths = manifestMap.keys
          .where((key) => key.startsWith('assets/images/backgrounds/'))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    return Scaffold(
      backgroundColor: const Color(0xFF131F24),
      body: Stack(
        children: [
          // Содержимое магазина
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 88, 16, 16),
            child: Column(
              children: [
                _buildSection(
                  'Фоны',
                  backgroundPaths,
                  state.selectedBackground,
                  state.ownedBackgrounds,
                  (path) => state.selectBackground(path),
                  (path, price) => state.buyBackground(path, price),
                  rows: 1, // один ряд для фонов
                ),

                _buildSection(
                  'Рамки',
                  framePaths,
                  state.selectedFrame,
                  state.ownedFrames,
                  (path) => state.selectFrame(path),
                  (path, price) => state.buyFrame(path, price),
                  rows: 2, // два ряда для рамок
                ),

                _buildSection(
                  'Аватары',
                  avatarPaths,
                  state.selectedAvatar,
                  state.ownedAvatars,
                  (path) => state.selectAvatar(path),
                  (path, price) => state.buyAvatar(path, price),
                  rows: 2, // два ряда для аватаров
                ),
              ],
            ),
          ),

          // Верхний HUD, повторяет размеры _topHUD
          _topShopHUD(context, state),
        ],
      ),
    );
  }

  // ====== Верхний HUD ======
  Widget _topShopHUD(BuildContext context, GameState state) {
    final double widgetHeight = 24.0;
    final Color backgroundColor = const Color(0xFF131F24);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: backgroundColor,
        child: Column(
          children: [
            SizedBox(
              height: 88, // общая высота HUD
              child: Stack(
                children: [
                  // Заголовок магазина по центру
                  Positioned(
                    top: 52, // чуть выше полосы
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'Магазин',
                        style: const TextStyle(
                          fontFamily: 'ClashRoyale',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Баланс монет справа
                  Positioned(
                    top: 52, // на той же высоте, что и заголовок
                    right: 16,
                    child: Row(
                      children: [
                        SizedBox(
                          width: widgetHeight,
                          height: widgetHeight,
                          child: Image.asset('assets/images/coin.png'),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          state.coins.toString(),
                          style: const TextStyle(
                            fontFamily: 'ClashRoyale',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Тонкая серая линия под HUD
            Container(height: 1, color: Color(0xFF37464F)),
          ],
        ),
      ),
    );
  }

  // ====== Секция товаров ======
  Widget _buildSection(
    String title,
    List<String> paths,
    String selectedPath,
    List<String> ownedPaths,
    Function(String) selectFunc,
    bool Function(String, int) buyFunc, {
    int rows = 2, // количество рядов, по умолчанию 2
  }) {
    const double bottomHeight = 40; // нижняя часть карточки
    final double cardHeight =
        MediaQuery.of(context).size.width / 4 + bottomHeight;
    final double gridHeight =
        cardHeight * rows + (rows - 1) * 12; // учитываем spacing

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'ClashRoyale',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: gridHeight,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: paths.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1 / 1.3,
            ),
            itemBuilder: (context, index) {
              final path = paths[index];
              final bool isOwned = ownedPaths.contains(path);
              final bool isSelected = selectedPath == path;
              final int price = 100;

              return GestureDetector(
                onTap: () {
                  if (isOwned) {
                    selectFunc(path);
                  } else {
                    final success = buyFunc(path, price);
                    if (success) {
                      selectFunc(path);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Вы купили!',
                            style: TextStyle(color: Colors.white),
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Недостаточно монет 💰',
                            style: TextStyle(color: Colors.white),
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF37464F),
                      width: isSelected ? 3 : 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.asset(
                            path,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      Container(
                        height: bottomHeight,
                        alignment: Alignment.center,
                        child: isSelected
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset(
                                  'assets/images/icon_is_equipped.png',
                                ),
                              )
                            : !isOwned
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: Image.asset(
                                      'assets/images/coin.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$price',
                                    style: const TextStyle(
                                      fontFamily: 'ClashRoyale',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
