class Obstacle {
  Offset position;
  Direction direction;
  final double speed;

  Obstacle({
    required this.position,
    required this.direction,
    this.speed = 1.0,
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