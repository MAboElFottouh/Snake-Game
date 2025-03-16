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

  // Add new properties
  List<Wall> walls = [];
  Timer? wallTimer;
  static const int numWalls = 4;

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
    if (widget.gameMode == 'Walls') {
      _generateWalls();
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
        
        // Increase speed every 5 food items
        if (foodCount % 5 == 0) {
          currentSpeed = (currentSpeed * speedIncrease).toInt();
          _updateGameTimer();

          // Add new wall in Walls mode
          if (widget.gameMode == 'Walls') {
            Wall newWall = Wall(
              position: Offset(0, 0),
              isVertical: walls.length % 2 == 0,
              speed: 0.1 * (randomGen.nextBool() ? 1 : -1),
              length: 5.0,
            );
            newWall.randomizePosition(randomGen, squaresPerRow, squaresPerCol);
            walls.add(newWall);
          }
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
    
    // All modes except Boxed have wrap around
    if (widget.gameMode != 'Boxed') {
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
          if (obstacle.move(squaresPerRow, squaresPerCol)) {
            // When obstacle reaches edge, generate new random direction and position
            obstacle.direction = Direction.values[randomGen.nextInt(4)];
            obstacle.randomizePosition(randomGen, squaresPerRow, squaresPerCol);
          }
        }
      });
    });
  }

  void _addNewObstacle() {
    Direction randomDirection = Direction.values[randomGen.nextInt(4)];
    Obstacle newObstacle = Obstacle(
      position: Offset(0, 0), // Initial position will be set by randomizePosition
      direction: randomDirection,
      speed: 0.2 + (randomGen.nextDouble() * 0.3), // Random speed between 0.2 and 0.5
    );
    newObstacle.randomizePosition(randomGen, squaresPerRow, squaresPerCol);
    obstacles.add(newObstacle);
  }

  void _generateWalls() {
    walls.clear();
    // Create some vertical and horizontal walls
    for (int i = 0; i < numWalls; i++) {
      Wall wall = Wall(
        position: Offset(0, 0),  // Initial position will be set by randomizePosition
        isVertical: i % 2 == 0,
        speed: 0.1 * (randomGen.nextBool() ? 1 : -1),
        length: 5.0,
      );
      wall.randomizePosition(randomGen, squaresPerRow, squaresPerCol);
      walls.add(wall);
    }

    // Move walls
    wallTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!isPlaying) return;
      setState(() {
        for (var wall in walls) {
          if (wall.move(squaresPerRow, squaresPerCol)) {
            // When wall goes off screen, give it a new random position
            wall.randomizePosition(randomGen, squaresPerRow, squaresPerCol);
          }
        }
      });
    });
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

    // Check wall collisions
    if (widget.gameMode == 'Walls') {
      for (var wall in walls) {
        if (wall.isVertical) {
          if (position.dx.round() == wall.position.dx.round() &&
              position.dy >= wall.position.dy &&
              position.dy <= wall.position.dy + wall.length) {
            AudioService.playGameOverSound();
            return true;
          }
        } else {
          if (position.dy.round() == wall.position.dy.round() &&
              position.dx >= wall.position.dx &&
              position.dx <= wall.position.dx + wall.length) {
            AudioService.playGameOverSound();
            return true;
          }
        }
      }
    }

    return false;
  }

  void _gameOver() async {
    // Stop all timers
    timer?.cancel();
    obstacleTimer?.cancel();  // Stop obstacles movement
    wallTimer?.cancel();
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
              // Regenerate obstacles/walls based on game mode
              if (widget.gameMode == 'Challenge') {
                _generateObstacles();
              } else if (widget.gameMode == 'Walls') {
                _generateWalls();  // Add this line to regenerate walls
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
    wallTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable system back button
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.red,
            ),
            onPressed: () {
              if (isPlaying) {
                isPlaying = false;
                showDialog(
                  context: context,
                  barrierDismissible: false, // Prevent dialog dismissal by tapping outside
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
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text(
                          'Exit',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Score: $score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    isPlaying = !isPlaying;
                  });
                },
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
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
                      gameMode: widget.gameMode,
                      obstacles: obstacles,
                      walls: walls,
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
  final List<Wall> walls; // Add this parameter

  GamePainter({
    required this.snakePos,
    required this.food,
    this.bonusFood,
    required this.squaresPerRow,
    required this.squaresPerCol,
    this.bonusTimeLeft = 0,
    required this.gameMode, // Add this
    this.obstacles = const [], // Add this
    this.walls = const [], // Add this parameter
  });

  // Add gradient colors as static constants
  static const Color snakeGradientStart = Color(0xFF8B0000); // Dark red
  static const Color snakeGradientEnd = Color(0xFFFF4444);   // Light red

  // Add new property for tail animation
  final double tailFade = 0.8;

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

    // Draw snake with gradient and tail effects
    for (var i = 0; i < snakePos.length; i++) {
      // Calculate fade factor for tail segments
      final fadeProgress = 1.0 - ((i / snakePos.length) * tailFade);
      
      // Calculate segment size with reduction for tail
      final segmentSize = 0.95 * min(
        size.width / squaresPerRow,
        size.height / squaresPerCol,
      ) * (i == 0 ? 1.0 : fadeProgress);

      // Create gradient color for each segment
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            snakeGradientStart.withOpacity(fadeProgress),
            snakeGradientEnd.withOpacity(fadeProgress),
          ],
          stops: [0.0, 1.0],
        ).createShader(
          Rect.fromCenter(
            center: Offset(
              (snakePos[i].dx + 0.5) * size.width / squaresPerRow,
              (snakePos[i].dy + 0.5) * size.height / squaresPerCol,
            ),
            width: size.width / squaresPerRow,
            height: size.height / squaresPerCol,
          ),
        )
        ..style = PaintingStyle.fill;

      // Add glow effect with fading
      final glowPaint = Paint()
        ..color = snakeGradientStart.withOpacity(0.3 * fadeProgress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3);

      final center = Offset(
        (snakePos[i].dx + 0.5) * size.width / squaresPerRow,
        (snakePos[i].dy + 0.5) * size.height / squaresPerCol,
      );

      // Draw rounded rectangle for segments with tail effect
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: segmentSize,
          height: segmentSize,
        ),
        Radius.circular(segmentSize / 4),
      );

      // Draw glow and segment
      canvas.drawRRect(rect, glowPaint);
      canvas.drawRRect(rect, paint);

      // Draw head details only for first segment
      if (i == 0) {
        final headPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        // Add eyes
        final eyeSize = segmentSize / 6;
        final eyeOffset = segmentSize / 4;

        canvas.drawCircle(
          center.translate(-eyeOffset, -eyeOffset),
          eyeSize,
          headPaint,
        );
        canvas.drawCircle(
          center.translate(eyeOffset, -eyeOffset),
          eyeSize,
          headPaint,
        );
      }
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

    // Draw moving walls
    if (gameMode == 'Walls') {
      final wallPaint = Paint()
        ..color = Colors.red[700]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      // Add glow effect for walls
      final glowPaint = Paint()
        ..color = Colors.red[700]!.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);

      for (var wall in walls) {
        if (wall.isVertical) {
          // Draw vertical wall with glow
          final startPoint = Offset(
            (wall.position.dx + 0.5) * size.width / squaresPerRow,
            wall.position.dy * size.height / squaresPerCol,
          );
          final endPoint = Offset(
            (wall.position.dx + 0.5) * size.width / squaresPerRow,
            (wall.position.dy + wall.length) * size.height / squaresPerCol,
          );

          // Draw glow effect
          canvas.drawLine(startPoint, endPoint, glowPaint);
          // Draw wall
          canvas.drawLine(startPoint, endPoint, wallPaint);
        } else {
          // Draw horizontal wall with glow
          final startPoint = Offset(
            wall.position.dx * size.width / squaresPerRow,
            (wall.position.dy + 0.5) * size.height / squaresPerCol,
          );
          final endPoint = Offset(
            (wall.position.dx + wall.length) * size.width / squaresPerRow,
            (wall.position.dy + 0.5) * size.height / squaresPerCol,
          );

          // Draw glow effect
          canvas.drawLine(startPoint, endPoint, glowPaint);
          // Draw wall
          canvas.drawLine(startPoint, endPoint, wallPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}

enum Direction { up, down, left, right }

class Obstacle {
  Offset position;
  Direction direction;
  final double speed;

  Obstacle({
    required this.position,
    required this.direction,
    this.speed = 1.0,
  });

  bool move(int squaresPerRow, int squaresPerCol) {
    bool shouldReposition = false;
    
    switch (direction) {
      case Direction.up:
        position = Offset(position.dx, position.dy - speed);
        if (position.dy < 0) shouldReposition = true;
        break;
      case Direction.down:
        position = Offset(position.dx, position.dy + speed);
        if (position.dy >= squaresPerCol) shouldReposition = true;
        break;
      case Direction.left:
        position = Offset(position.dx - speed, position.dy);
        if (position.dx < 0) shouldReposition = true;
        break;
      case Direction.right:
        position = Offset(position.dx + speed, position.dy);
        if (position.dx >= squaresPerRow) shouldReposition = true;
        break;
    }
    
    return shouldReposition;
  }

  void randomizePosition(Random randomGen, int squaresPerRow, int squaresPerCol) {
    // Generate position on a random edge based on direction
    switch (direction) {
      case Direction.up:
        position = Offset(
          randomGen.nextInt(squaresPerRow).toDouble(),
          squaresPerCol.toDouble(),
        );
        break;
      case Direction.down:
        position = Offset(
          randomGen.nextInt(squaresPerRow).toDouble(),
          0,
        );
        break;
      case Direction.left:
        position = Offset(
          squaresPerRow.toDouble(),
          randomGen.nextInt(squaresPerCol).toDouble(),
        );
        break;
      case Direction.right:
        position = Offset(
          0,
          randomGen.nextInt(squaresPerCol).toDouble(),
        );
        break;
    }
  }
}

// Add Wall class after Obstacle class
class Wall {
  Offset position;
  bool isVertical;
  double speed;
  double length;

  Wall({
    required this.position,
    required this.isVertical,
    this.speed = 0.1,
    this.length = 5.0,
  });

  bool move(int squaresPerRow, int squaresPerCol) {
    bool shouldReposition = false;
    
    if (isVertical) {
      position = Offset(position.dx, position.dy + speed);
      if (position.dy + length < 0 || position.dy > squaresPerCol) {
        shouldReposition = true;
      }
    } else {
      position = Offset(position.dx + speed, position.dy);
      if (position.dx + length < 0 || position.dx > squaresPerRow) {
        shouldReposition = true;
      }
    }
    
    return shouldReposition;
  }

  void randomizePosition(Random randomGen, int squaresPerRow, int squaresPerCol) {
    if (isVertical) {
      position = Offset(
        randomGen.nextInt(squaresPerRow - 2).toDouble() + 1,
        speed > 0 ? -length : squaresPerCol.toDouble(),
      );
    } else {
      position = Offset(
        speed > 0 ? -length : squaresPerRow.toDouble(),
        randomGen.nextInt(squaresPerCol - 2).toDouble() + 1,
      );
    }
  }
}