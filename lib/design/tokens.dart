/// Spacing, radius and motion tokens. 4pt grid.
abstract final class Space {
  static const double xxs = 2;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Side padding of every screen.
  static const double screen = 20;

  /// Inner padding of cards.
  static const double card = 16;
}

abstract final class Radii {
  static const double card = 24;
  static const double list = 22;
  static const double sheet = 32;
  static const double button = 16;
  static const double chip = 999;
  static const double bar = 4;
}

abstract final class Motion {
  /// Ring fill and count-up, on the first open of the day only.
  static const reveal = Duration(milliseconds: 700);
  static const quick = Duration(milliseconds: 200);
  static const toast = Duration(seconds: 4);
  static const toastWithAction = Duration(seconds: 8);
}
