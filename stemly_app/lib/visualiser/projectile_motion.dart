// lib/visualiser/components/projectile_motion.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ProjectileComponent extends PositionComponent {
  double U; // m/s
  double theta; // degrees
  double g; // m/s^2

  double t = 0; // time seconds
  Vector2 start = Vector2.zero();

  // scale factor: meters -> pixels (tweak for visual)
  double scale = 5.0;

  late CircleComponent ball;

  ProjectileComponent({
    required this.U,
    required this.theta,
    required this.g,
    Vector2? position,
    this.scale = 5.0,
  }) {
    start = position ?? Vector2(50, 300); // default origin in pixels
    size = Vector2(800, 400);
    anchor = Anchor.topLeft;
    ball = CircleComponent(radius: 8.0, paint: Paint()..color = Colors.red);
  }

  @override
  Future<void>? onLoad() async {
    add(ball);
    ball.position = start;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;

    final rad = theta * pi / 180.0;
    // compute in meters — convert to pixel by *scale
    final x_m = U * cos(rad) * t;
    final y_m = U * sin(rad) * t - 0.5 * g * t * t;

    final x_px = start.x + x_m * scale;
    final y_px = start.y - y_m * scale; // screen y increases downward

    // stop when below ground or out of bounds
    if (y_px > size.y + start.y || x_px > size.x + start.x) {
      // reset after it falls
      t = 0;
    }

    ball.position = Vector2(x_px, y_px);
  }

  // call this when params change
  void updateParams({double? U, double? theta, double? g}) {
    if (U != null) this.U = U;
    if (theta != null) this.theta = theta;
    if (g != null) this.g = g;
    // reset time to start animation from origin
    t = 0;
  }
}
