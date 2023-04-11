import 'package:flutter/physics.dart';

extension AlmostEqualTo on double {
  bool almostEqualTo(double value) =>
      nearEqual(this, value, Tolerance.defaultTolerance.distance);
}
