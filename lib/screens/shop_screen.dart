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
    final manifestContent = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
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
          children: [
            _buildSection('Фоны', backgroundPaths, state.selectedBackground,
                state.ownedBackgrounds, (path) => state.selectBackground(path), (path, price) => state.buyBackground(path, price)),
            const SizedBox(height: 20),
            _buildSection('Рамки', framePaths, state.selectedFrame,
                state.ownedFrames, (path) => state.selectFrame(path), (path, price) => state.buyFrame(path, price)),
            const SizedBox(height: 20),
            _buildSection('Аватары', avatarPaths, state.selectedAvatar,
                state.ownedAvatars, (path) => state.selectAvatar(path), (path, price) => state.buyAvatar(path, price)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<String> paths,
    String selectedPath,
    List<String> ownedPaths,
    Function(String) selectFunc,
    bool Function(String, int) buyFunc,
  ) {
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
          itemCount: paths.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          itemBuilder: (context, index) {
            final path = paths[index];
            final bool isOwned = ownedPaths.contains(path);
            final bool isSelected = selectedPath == path;
            final int price = 100; // можно задать дефолтную цену или хранить мапу цен

            double progress = isOwned ? 1.0 : (Provider.of<GameState>(context, listen: false).coins / price).clamp(0, 1).toDouble();

            return GestureDetector(
              onTap: () {if (isOwned) {
                  selectFunc(path);
                } else {
                  final success = buyFunc(path, price);
                  if (success) {
                    selectFunc(path);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: outlinedText('Вы купили!', fontSize: 14),
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.white : const Color(0xFF37464F),
                    width: isSelected ? 3 : 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(path, fit: BoxFit.cover),
                    ),
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
                        child: isOwned
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
                                      outlinedText('$price', fontSize: 12, fillColor: Colors.white),
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
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: const Color(0xFF37464F),
                                      color: const Color(0xFF58A700),
                                      minHeight: 6,
                                    ),
                                  ),
                                ],),
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