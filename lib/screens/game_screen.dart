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

  List<Offset> snakePos = [];
  Offset? food;
  Timer? timer;
  Direction direction = Direction.right;
  bool isPlaying = false;
  int score = 0;
  int highScore = 0;

  late final int pointsPerFood;
  late final int gameSpeed;

  Offset? bonusFood;
  Timer? bonusTimer;
  int foodCount = 0;
  int bonusPoints = 0;
  int bonusTimeLeft = 5;

  // Add new properties
  List<Obstacle> obstacles = [];
  Timer? obstacleTimer;
  static const int numObstacles = 3;

  // Add new properties for dynamic speed and points
  int currentSpeed = 200;
  int currentPointsPerFood = 3;
  static const double speedIncrease = 0.98; // 2% faster each time (was 5%)

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    // Initialize base speed and points based on difficulty
    switch (widget.difficulty) {
      case 'Easy':
        currentPointsPerFood = 3;
        currentSpeed = 200;
        break;
      case 'Medium':
        currentPointsPerFood = 5;
        currentSpeed = 150;
        break;
      case 'Hard':
        currentPointsPerFood = 7;
        currentSpeed = 100;
        break;
      default:
        currentPointsPerFood = 3;
        currentSpeed = 200;
    }
    _startGame();
    if (widget.gameMode == 'Challenge') {
      _generateObstacles();
    }
  }

  Future<void> _loadHighScore() async {
    // Get high score for specific mode
    highScore = await ScoreService.getHighScore(widget.gameMode);
    setState(() {});
  }

  void _startGame() {
    setState(() {
      snakePos = [
        Offset(squaresPerRow / 2, squaresPerCol / 2),
      ];
      _generateFood();
      isPlaying = true;
      score = 0;
      foodCount = 0;
      // Reset speed and points to initial values
      switch (widget.difficulty) {
        case 'Easy':
          currentPointsPerFood = 3;
          currentSpeed = 200;
          break;
        case 'Medium':
          currentPointsPerFood = 5;
          currentSpeed = 150;
          break;
        case 'Hard':
          currentPointsPerFood = 7;
          currentSpeed = 100;
          break;
      }
      
      _updateGameTimer();
    });
  }

  void _updateGameTimer() {
    timer?.cancel();
    timer = Timer.periodic(Duration(milliseconds: currentSpeed), (timer) {
      _updateGame();
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

      if (newHead == food) {
        score += currentPointsPerFood;
        AudioService.playEatSound();
        foodCount++;
        
        // Increase speed every 5 food items instead of every time
        if (foodCount % 5 == 0) {
          currentSpeed = (currentSpeed * speedIncrease).toInt();
          _updateGameTimer();
        }

        // Increase points every 10 food items
        if (foodCount % 10 == 0) {
          currentPointsPerFood++;
        }
        
        // Add new obstacle every 5 food items in Challenge mode
        if (widget.gameMode == 'Challenge' && foodCount % 5 == 0) {
          _addNewObstacle();
        }
        
        if (foodCount % 5 == 0) {
          _generateBonusFood();
        }
        
        _generateFood();
      } 
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
    
    // Both Classic and Challenge modes wrap around the screen
    if (widget.gameMode == 'Classic' || widget.gameMode == 'Challenge') {
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
    // Only Boxed mode has no wrap around
    else {
      switch (direction) {
        case Direction.up:
          return Offset(head.dx, head.dy - 1);
        case Direction.down:
          return Offset(head.dx, head.dy + 1);
        case Direction.left:
          return Offset(head.dx - 1, head.dy);
        case Direction.right:
          return Offset(head.dx + 1, head.dy);
      }
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
    bonusPoints = 30; 
    
    bool validPosition = false;
    while (!validPosition) {
      bonusFood = Offset(
        randomGen.nextInt(squaresPerRow).toDouble(),
        randomGen.nextInt(squaresPerCol).toDouble(),
      );
      validPosition = !snakePos.contains(bonusFood) && bonusFood != food;
    }

    bonusTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        bonusTimeLeft--;
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

  void _generateObstacles() {
    obstacles.clear();
    // Start with 3 obstacles
    for (int i = 0; i < numObstacles; i++) {
      _addNewObstacle();
    }

    // Move obstacles continuously
    obstacleTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!isPlaying) return;
      setState(() {
        for (var obstacle in obstacles) {
          // Move obstacle according to its direction and speed
          obstacle.move(squaresPerRow, squaresPerCol);
        }
      });
    });
  }

  void _addNewObstacle() {
    obstacles.add(
      Obstacle(
        position: Offset(
          randomGen.nextInt(squaresPerRow).toDouble(),
          randomGen.nextInt(squaresPerCol).toDouble(),
        ),
        direction: Direction.values[randomGen.nextInt(4)],
        speed: 0.2 + (randomGen.nextDouble() * 0.3), // Random speed between 0.2 and 0.5
      ),
    );
  }

  bool _checkCollision(Offset position) {
    // Wall collision only in Boxed mode
    if (widget.gameMode == 'Boxed') {
      if (position.dx < 0 || position.dx >= squaresPerRow ||
          position.dy < 0 || position.dy >= squaresPerCol) {
        AudioService.playGameOverSound();
        return true;
      }
    }

    // If this position is food, it's not a collision
    if (position == food || position == bonusFood) {
      return false;
    }
    
    // Check if snake hits its own body (excluding the tail when not growing)
    for (int i = 0; i < snakePos.length - 1; i++) {
      if (position == snakePos[i]) {
        AudioService.playGameOverSound();
        return true;
      }
    }

    // Check obstacle collision
    if (widget.gameMode == 'Challenge') {
      for (var obstacle in obstacles) {
        if ((position - obstacle.position).distance < 1) {
          AudioService.playGameOverSound();
          return true;
        }
      }
    }

    return false;
  }

  void _gameOver() async {
    // Stop all timers
    timer?.cancel();
    obstacleTimer?.cancel();  // Stop obstacles movement
    bonusTimer?.cancel();
    
    // Set game state
    isPlaying = false;
    
    AudioService.playGameOverSound();
    HapticFeedback.vibrate();
    
    // Update high score for specific mode
    await ScoreService.updateHighScore(widget.gameMode, score);
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
            Text('${widget.gameMode} Mode High Score: $highScore',
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
              if (widget.gameMode == 'Challenge') {
                _generateObstacles();  // Regenerate obstacles for new game
              }
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
    timer?.cancel();
    obstacleTimer?.cancel();
    bonusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (isPlaying) {
          isPlaying = false;
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.black87,
              title: const Text(
                'Exit Game?',
                style: TextStyle(color: Colors.red),
              ),
              content: const Text(
                'Are you sure you want to exit the game?',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.green),
                  ),
                  onPressed: () {
                    isPlaying = true;
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text(
                    'Exit',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            ),
          );
        }
        return true;
      },
      child: Scaffold(
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
                      gameMode: widget.gameMode, // Add this line
                      obstacles: obstacles, // Add this line
                    ),
                    size: Size.infinite,
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

// Game painting class
class GamePainter extends CustomPainter {
  final List<Offset> snakePos;
  final Offset? food;
  final Offset? bonusFood;
  final int squaresPerRow;
  final int squaresPerCol;
  final int bonusTimeLeft;
  final String gameMode; // Add this
  final List<Obstacle> obstacles; // Add this

  GamePainter({
    required this.snakePos,
    required this.food,
    this.bonusFood,
    required this.squaresPerRow,
    required this.squaresPerCol,
    this.bonusTimeLeft = 0,
    required this.gameMode, // Add this
    this.obstacles = const [], // Add this
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Update the condition to use gameMode parameter
    if (gameMode == 'Boxed') {
      final wallPaint = Paint()
        ..color = Colors.red[900]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;

      // Draw border walls
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
        wallPaint,
      );
      
      // Add glow effect to walls
      final glowPaint = Paint()
        ..color = Colors.red.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
        
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
        glowPaint,
      );
    }

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

    // Draw obstacles
    final obstaclePaint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (var obstacle in obstacles) {
      canvas.drawCircle(
        Offset(
          (obstacle.position.dx + 0.5) * size.width / squaresPerRow,
          (obstacle.position.dy + 0.5) * size.height / squaresPerCol,
        ),
        min(size.width / squaresPerRow, size.height / squaresPerCol) / 2,
        obstaclePaint,
      );
    }
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}

enum Direction { up, down, left, right }

class Obstacle {
  Offset position;
  Direction direction;
  double speed;

  Obstacle({
    required this.position,
    required this.direction,
    required this.speed,
  });

  void move(int squaresPerRow, int squaresPerCol) {
    switch (direction) {
      case Direction.up:
        position = Offset(position.dx, (position.dy - speed) % squaresPerCol);
        break;
      case Direction.down:
        position = Offset(position.dx, (position.dy + speed) % squaresPerCol);
        break;
      case Direction.left:
        position = Offset((position.dx - speed) % squaresPerRow, position.dy);
        break;
      case Direction.right:
        position = Offset((position.dx + speed) % squaresPerRow, position.dy);
        break;
    }
  }
}