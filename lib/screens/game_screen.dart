import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../services/score_service.dart';
import '../services/audio_service.dart';
import '../widgets/score_board.dart';

class GameScreen extends StatefulWidget {
  final String difficulty;
  final String gameMode;

  const GameScreen({
    Key? key,
    required this.difficulty,
    required this.gameMode,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int squaresPerRow = 20;
  static const int squaresPerCol = 40;
  final randomGen = Random();

  // حالة اللعبة
  List<Offset> snakePos = [];
  Offset? food;
  Timer? timer;
  Direction direction = Direction.right;
  bool isPlaying = false;
  int score = 0;
  int highScore = 0;

  late final int pointsPerFood;
  late final int gameSpeed;

  // إضافة متغيرات البونص
  Offset? bonusFood;
  Timer? bonusTimer;
  int foodCount = 0;
  int bonusPoints = 0;
  int bonusTimeLeft = 5;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    switch (widget.difficulty) {
      case 'Easy':
        pointsPerFood = 3;
        gameSpeed = 200; 
        break;
      case 'Medium':
        pointsPerFood = 5;
        gameSpeed = 150; 
        break;
      case 'Hard':
        pointsPerFood = 7;
        gameSpeed = 100;
        break;
      default:
        pointsPerFood = 3;
        gameSpeed = 200;
    }
    _startGame();
  }

  Future<void> _loadHighScore() async {
    highScore = await ScoreService.getHighScore();
    setState(() {});
  }

  void _startGame() {
    setState(() {
      // وضع الثعبان في المنتصف
      snakePos = [
        Offset(squaresPerRow / 2, squaresPerCol / 2),
      ];
      _generateFood();
      isPlaying = true;
      score = 0;
      
      timer = Timer.periodic(Duration(milliseconds: gameSpeed), (timer) {
        _updateGame();
      });
    });
  }

  void _updateGame() {
    if (!isPlaying) return;

    setState(() {
      Offset newHead = _getNextPosition();
      
      if (_checkCollision(newHead)) {
        _gameOver();
        return;
      }

      snakePos.insert(0, newHead);

      // التحقق من أكل الطعام العادي
      if (newHead == food) {
        score += pointsPerFood;
        AudioService.playEatSound();
        foodCount++;
        
        // بعد كل 5 طعام، إنشاء طعام بونص
        if (foodCount % 5 == 0) {
          _generateBonusFood();
        }
        
        _generateFood();
      } 
      // التحقق من أكل طعام البونص
      else if (bonusFood != null && newHead == bonusFood) {
        score += bonusPoints;
        AudioService.playEatSound();
        bonusFood = null;
        bonusTimer?.cancel();
      } else {
        snakePos.removeLast();
      }
    });
  }

  Offset _getNextPosition() {
    Offset head = snakePos.first;
    switch (direction) {
      case Direction.up:
        return Offset(head.dx, (head.dy - 1) % squaresPerCol);
      case Direction.down:
        return Offset(head.dx, (head.dy + 1) % squaresPerCol);
      case Direction.left:
        return Offset((head.dx - 1) % squaresPerRow, head.dy);
      case Direction.right:
        return Offset((head.dx + 1) % squaresPerRow, head.dy);
    }
  }

  void _generateFood() {
    bool validPosition = false;
    while (!validPosition) {
      food = Offset(
        randomGen.nextInt(squaresPerRow).toDouble(),
        randomGen.nextInt(squaresPerCol).toDouble(),
      );
      validPosition = !snakePos.contains(food);
    }
  }

  void _generateBonusFood() {
    bonusTimeLeft = 5;
    bonusPoints = 30; // يبدأ ب 30 نقطة
    
    // توليد موقع عشوائي للطعام البونص
    bool validPosition = false;
    while (!validPosition) {
      bonusFood = Offset(
        randomGen.nextInt(squaresPerRow).toDouble(),
        randomGen.nextInt(squaresPerCol).toDouble(),
      );
      validPosition = !snakePos.contains(bonusFood) && bonusFood != food;
    }

    // بدء العد التنازلي
    bonusTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        bonusTimeLeft--;
        // تقليل النقاط كل ثانية
        switch (bonusTimeLeft) {
          case 4: bonusPoints = 20; break;
          case 3: bonusPoints = 15; break;
          case 2: bonusPoints = 10; break;
          case 1: bonusPoints = 5; break;
          case 0:
            bonusFood = null;
            timer.cancel();
            break;
        }
      });
    });
  }

  bool _checkCollision(Offset position) {
    if (widget.gameMode == 'Boxed') {
      if (position.dx < 0 || position.dx >= squaresPerRow ||
          position.dy < 0 || position.dy >= squaresPerCol) {
        return true;
      }
    }
    return snakePos.contains(position);
  }

  void _gameOver() async {
    timer?.cancel();
    AudioService.playGameOverSound();
    
    HapticFeedback.vibrate();
    
    await ScoreService.updateHighScore(score);
    await _loadHighScore();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text('Game Over!',
            style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: $score',
                style: TextStyle(color: Colors.white)),
            Text('High Score: $highScore',
                style: TextStyle(color: Colors.amber)),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Play Again',
                style: TextStyle(color: Colors.green)),
            onPressed: () {
              Navigator.of(context).pop();
              _startGame();
            },
          ),
          TextButton(
            child: Text('Main Menu',
                style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    bonusTimer?.cancel();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            ScoreBoard(
              currentScore: score,
              highScore: highScore,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Score: $score',
                      style: TextStyle(color: Colors.white, fontSize: 20)),
                  IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white),
                    onPressed: () {
                      setState(() {
                        isPlaying = !isPlaying;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (direction != Direction.up && details.delta.dy > 0) {
                    direction = Direction.down;
                  } else if (direction != Direction.down && details.delta.dy < 0) {
                    direction = Direction.up;
                  }
                },
                onHorizontalDragUpdate: (details) {
                  if (direction != Direction.left && details.delta.dx > 0) {
                    direction = Direction.right;
                  } else if (direction != Direction.right && details.delta.dx < 0) {
                    direction = Direction.left;
                  }
                },
                child: CustomPaint(
                  painter: GamePainter(
                    snakePos: snakePos,
                    food: food,
                    bonusFood: bonusFood,
                    squaresPerRow: squaresPerRow,
                    squaresPerCol: squaresPerCol,
                    bonusTimeLeft: bonusTimeLeft,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Game painting class
class GamePainter extends CustomPainter {
  final List<Offset> snakePos;
  final Offset? food;
  final Offset? bonusFood;
  final int squaresPerRow;
  final int squaresPerCol;
  final int bonusTimeLeft;

  GamePainter({
    required this.snakePos,
    required this.food,
    this.bonusFood,
    required this.squaresPerRow,
    required this.squaresPerCol,
    this.bonusTimeLeft = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw snake with gradient effects
    for (var i = 0; i < snakePos.length; i++) {
      // Create gradient color effect for snake
      paint.color = HSVColor.fromAHSV(
        1.0,
        120 - (i * 2), // Green gradient
        1.0,
        0.8 - (i * 0.02), // Brightness gradient
      ).toColor();

      // Variable size for snake segments
      double sizeFactor = 1.0 - (i * 0.01);
      
      // Draw snake segment with rounded corners
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(
              (snakePos[i].dx + 0.5) * size.width / squaresPerRow,
              (snakePos[i].dy + 0.5) * size.height / squaresPerCol,
            ),
            width: (size.width / squaresPerRow - 1) * sizeFactor,
            height: (size.height / squaresPerCol - 1) * sizeFactor,
          ),
          Radius.circular(8), // Rounded corners
        ),
        paint,
      );
    }

    // Draw regular food with normal red color
    if (food != null) {
      final paint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(
          (food!.dx + 0.5) * size.width / squaresPerRow,
          (food!.dy + 0.5) * size.height / squaresPerCol,
        ),
        min(size.width / squaresPerRow, size.height / squaresPerCol) / 2.5,
        paint,
      );
    }

    // Draw bonus food if available with larger size and red glow
    if (bonusFood != null) {
      final bonusSize = 2.0; // Increased size multiplier
      final paint = Paint()
        ..color = Colors.red.withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);
      
      final center = Offset(
        (bonusFood!.dx + 0.5) * size.width / squaresPerRow,
        (bonusFood!.dy + 0.5) * size.height / squaresPerCol,
      );
      
      // Draw red glow halo
      canvas.drawCircle(
        center,
        min(size.width / squaresPerRow, size.height / squaresPerCol) * bonusSize,
        paint,
      );
      
      // Draw solid red bonus food
      canvas.drawCircle(
        center,
        min(size.width / squaresPerRow, size.height / squaresPerCol) * 0.8,
        Paint()..color = Colors.red,
      );
      
      // Draw countdown timer
      final textSpan = TextSpan(
        text: bonusTimeLeft.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24, // Larger font size
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}

enum Direction { up, down, left, right }