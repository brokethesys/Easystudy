import 'dart:async';
import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  final VoidCallback onLoadingComplete;
  
  const LoadingScreen({
    super.key,
    required this.onLoadingComplete,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() {
    // Имитация загрузки с 100 шагами
    const totalSteps = 100;
    const stepDuration = Duration(milliseconds: 20); // Ускоренная загрузка
    
    for (int i = 0; i <= totalSteps; i++) {
      Timer(stepDuration * i, () {
        if (mounted) {
          setState(() {
            _progress = i / totalSteps;
          });
          
          // Когда загрузка завершена
          if (i == totalSteps) {
            _completeLoading();
          }
        }
      });
    }
  }

  void _completeLoading() {
    // Небольшая задержка перед переходом
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onLoadingComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Центральный логотип
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF58A700),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.school,
                    size: 80,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
          
          // Нижняя полоса прогресса
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  // Полоса прогресса
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Stack(
                      children: [
                        // Фон полосы
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        
                        // Прогресс
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: MediaQuery.of(context).size.width * 0.8 * _progress,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF58A700),
                                Color(0xFF8BC34A),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Процент загрузки
                  Text(
                    "${(_progress * 100).toInt()}%",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}