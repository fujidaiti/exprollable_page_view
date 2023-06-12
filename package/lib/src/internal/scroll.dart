import 'dart:math';

import 'package:exprollable_page_view/src/internal/utils.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class ScrollAbsorber extends ChangeNotifier {
  double _capacity;
  double get capacity => _capacity;
  set capacity(double value) {
    assert(value >= 0.0);
    if (_capacity == value) return;
    _capacity = value;
    if (pixels != null) {
      absorb(pixels!);
    }
  }

  double? _absorbedPixels;
  double? get absorbedPixels => _absorbedPixels;

  double? _overflow;
  double? get overflow => _overflow;

  double? get pixels {
    assert((absorbedPixels != null) == (overflow != null));
    return absorbedPixels != null ? absorbedPixels! + overflow! : null;
  }

  ScrollAbsorber({double capacity = 0.0})
      : assert(capacity >= 0),
        _capacity = capacity;

  void absorb(double pixels) {
    assert(pixels >= 0.0);
    final oldAbsorbedPixels = _absorbedPixels;
    final oldOverflow = _overflow;
    _absorbedPixels = min(pixels, capacity);
    _overflow = max(0.0, pixels - capacity);
    assert(absorbedPixels != null);
    assert(overflow != null);
    if (oldAbsorbedPixels?.almostEqualTo(absorbedPixels!) != true ||
        oldOverflow?.almostEqualTo(overflow!) != true) {
      notifyListeners();
    }
  }

  bool _shouldNotify = true;

  @override
  void notifyListeners() {
    if (_shouldNotify) {
      super.notifyListeners();
    }
  }

  void correct(void Function(ScrollAbsorber it) changes) {
    _shouldNotify = false;
    changes(this);
    _shouldNotify = true;
  }
}

class ScrollAbsorberGroup extends ScrollAbsorber {
  ScrollAbsorberGroup({super.capacity});

  final List<ScrollAbsorber> _absorbers = [];
  final List<VoidCallback> _callbacks = [];

  void attach(ScrollAbsorber absorber) {
    if (_absorbers.contains(absorber)) return;
    absorber.correct((it) {
      it.capacity = capacity;
      if (pixels != null) {
        it.absorb(pixels!);
      }
    });
    void callback() => absorb(absorber.pixels!);
    absorber.addListener(callback);
    _absorbers.add(absorber);
    _callbacks.add(callback);
  }

  void detach(ScrollAbsorber absorber) {
    if (!_absorbers.contains(absorber)) return;
    final index = _absorbers.indexOf(absorber);
    absorber.removeListener(_callbacks[index]);
    _absorbers.removeAt(index);
    _callbacks.removeAt(index);
  }

  @override
  set capacity(double newCapacity) {
    for (final a in _absorbers) {
      a.correct((it) => it.capacity = newCapacity);
    }
    super.capacity = newCapacity;
  }

  @override
  void absorb(double pixels) {
    for (final a in _absorbers) {
      a.correct((it) => it.absorb(pixels));
    }
    super.absorb(pixels);
  }

  @override
  void dispose() {
    super.dispose();
    assert(_absorbers.length == _callbacks.length);
    for (var i = 0; i < _absorbers.length; ++i) {
      final absorber = _absorbers[i];
      final callback = _callbacks[i];
      absorber.removeListener(callback);
    }
    _absorbers.clear();
    _callbacks.clear();
  }
}

class AbsorbScrollPosition extends ScrollPositionWithSingleContext {
  AbsorbScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    super.initialPixels,
    super.debugLabel,
    super.keepScrollOffset,
  });

  // May be initialized in [correctPixels] since it will be called
  // in the super constructor if [initialPixels] is not null.
  final ScrollAbsorber _absorber = ScrollAbsorber();

  double get impliedPixels =>
      _absorber.pixels != null ? pixels - _absorber.pixels! : pixels;

  double get impliedMinScrollExtent => minScrollExtent - _absorber.capacity;

  static double _computeOverscroll(double pixels, double minScrollExtent) =>
      max(0.0, minScrollExtent - pixels);

  static double _computeApparentPixels(double pixels, double minScrollExtent) =>
      max(minScrollExtent, pixels);

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    if (hasContentDimensions) {
      return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
    } else {
      // Once the viewport's content extents are established,
      // we can calculate the initial overscroll from current [pixels]
      // which is equal to [initialPixels] or [oldPosition.pixels] passed in the constructor.
      // Then, initialize [OverscrollAbsorber] with the calculated overscroll.
      _absorber.correct((it) {
        it.absorb(_computeOverscroll(pixels, minScrollExtent));
      });
      final oldPixels = pixels;
      super.correctPixels(_computeApparentPixels(pixels, minScrollExtent));
      super.applyContentDimensions(minScrollExtent, maxScrollExtent);
      return oldPixels == pixels;
    }
  }

  @override
  bool correctForNewDimensions(
      ScrollMetrics oldPosition, ScrollMetrics newPosition) {
    final double newActualPixels = physics.adjustPositionForNewDimensions(
      isScrolling: activity!.isScrolling,
      velocity: activity!.velocity,
      oldPosition: oldPosition,
      newPosition: copyWith(
        pixels: impliedPixels,
        minScrollExtent: impliedMinScrollExtent,
      ),
    );
    final oldPixels = pixels;
    correctPixels(newActualPixels);
    return pixels == oldPixels;
  }

  @override
  void absorb(ScrollPosition other) {
    super.absorb(other);
    if (other.hasPixels && other is AbsorbScrollPosition) {
      // `super.absorb(other)` may set `super._pixels` to an invalid value,
      // which needs to be corrected.
      correctPixels(other.impliedPixels);
    }
  }

  @override
  void saveScrollOffset() {
    PageStorage.maybeOf(context.storageContext)
        ?.writeState(context.storageContext, impliedPixels);
  }

  @override
  void saveOffset() {
    assert(hasPixels);
    context.saveOffset(impliedPixels);
  }

  @override
  void restoreOffset(double offset, {bool initialRestore = false}) {
    super.restoreOffset(
      hasContentDimensions
          ? _computeApparentPixels(offset, minScrollExtent)
          : offset,
      initialRestore: initialRestore,
    );
  }

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(
        delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    final actualDelta = physics.applyPhysicsToUserOffset(
      copyWith(minScrollExtent: impliedMinScrollExtent, pixels: impliedPixels),
      delta,
    );
    setPixels(impliedPixels - actualDelta);
  }

  @override
  void correctPixels(double value) {
    if (hasPixels && value == impliedPixels) return;
    if (hasContentDimensions) {
      _absorber.correct((it) {
        it.absorb(_computeOverscroll(value, minScrollExtent));
      });
      super.correctPixels(_computeApparentPixels(value, minScrollExtent));
    } else {
      super.correctPixels(value);
    }
  }

  @override
  // The code was mostly borrowed from [super.pointerScroll]:
  void pointerScroll(double delta) {
    if (delta == 0.0) {
      goBallistic(0.0);
      return;
    }

    final double targetPixels =
        (impliedPixels + delta).clamp(impliedMinScrollExtent, maxScrollExtent);
    if (targetPixels != impliedPixels) {
      goIdle();
      updateUserScrollDirection(
        -delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse,
      );
      final double oldPixels = pixels;
      isScrollingNotifier.value = true;
      forcePixels(targetPixels);
      didStartScroll();
      didUpdateScrollPositionBy(pixels - oldPixels);
      didEndScroll();
      goBallistic(0.0);
    }
  }

  /// Copied from 'package:flutter/lib/src/widgets/scroll_position.dart'.
  /// This is only used in [forcePixels] and [recommendDeferredLoading].
  double _impliedVelocity = 0;

  @override
  void forcePixels(double value) {
    assert(hasPixels);
    _impliedVelocity = value - impliedPixels;
    _absorber.absorb(_computeOverscroll(value, minScrollExtent));
    super.correctPixels(_computeApparentPixels(value, minScrollExtent));
    notifyListeners();
    SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
      _impliedVelocity = 0;
    });
  }

  @override
  bool recommendDeferredLoading(BuildContext context) {
    assert(activity != null);
    return physics.recommendDeferredLoading(
      activity!.velocity + _impliedVelocity,
      hasContentDimensions
          ? copyWith(
              pixels: impliedPixels,
              minScrollExtent: impliedMinScrollExtent,
            )
          : copyWith(),
      context,
    );
  }

  @override
  double setPixels(double newPixels) {
    if (newPixels == impliedPixels) return 0.0;
    final unhandledOverscroll = applyBoundaryConditions(newPixels);
    final newActualPixels = newPixels - unhandledOverscroll;
    _absorber.absorb(_computeOverscroll(newActualPixels, minScrollExtent));
    super.setPixels(_computeApparentPixels(newActualPixels, minScrollExtent));
    if (unhandledOverscroll != 0.0) {
      didOverscrollBy(unhandledOverscroll);
      return unhandledOverscroll;
    }
    return 0.0;
  }

  @override
  double applyBoundaryConditions(double value) {
    return physics.applyBoundaryConditions(
      copyWith(
        minScrollExtent: impliedMinScrollExtent,
        pixels: impliedPixels,
      ),
      value,
    );
  }

  @override
  void goBallistic(double velocity) {
    final Simulation? simulation = physics.createBallisticSimulation(
      copyWith(minScrollExtent: impliedMinScrollExtent, pixels: impliedPixels),
      velocity,
    );
    if (simulation != null) {
      beginActivity(
        BallisticScrollActivity(
          this,
          simulation,
          context.vsync,
          activity?.shouldIgnorePointer ?? true,
        ),
      );
    } else {
      goIdle();
    }
  }

  @override
  Future<void> animateTo(
    double to, {
    required Duration duration,
    required Curve curve,
  }) {
    if (impliedPixels.almostEqualTo(to)) {
      // Skip the animation, go straight to the position as we are already close.
      jumpTo(to);
      return Future<void>.value();
    }

    final DrivenScrollActivity activity = DrivenScrollActivity(
      this,
      from: impliedPixels,
      to: to,
      duration: duration,
      curve: curve,
      vsync: context.vsync,
    );
    beginActivity(activity);
    return activity.done;
  }

  @override
  void jumpTo(double value) {
    goIdle();
    if (!impliedPixels.almostEqualTo(value)) {
      final double oldPixels = pixels;
      forcePixels(value);
      didStartScroll();
      if (pixels.almostEqualTo(oldPixels)) {
        didUpdateScrollPositionBy(pixels - oldPixels);
      }
      didEndScroll();
    }
    goBallistic(0.0);
  }

  @override
  void dispose() {
    super.dispose();
    _absorber.dispose();
  }
}

class AbsorbScrollController extends ScrollController {
  AbsorbScrollController({
    super.debugLabel,
    super.initialScrollOffset,
    super.keepScrollOffset,
    double absorberCapacity = 0.0,
  }) : absorber = ScrollAbsorberGroup(capacity: absorberCapacity);

  final ScrollAbsorberGroup absorber;

  @override
  AbsorbScrollPosition get position => super.position as AbsorbScrollPosition;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return AbsorbScrollPosition(
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      debugLabel: debugLabel,
      physics: physics,
      context: context,
      oldPosition: oldPosition,
    );
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    assert(position is AbsorbScrollPosition);
    absorber.attach((position as AbsorbScrollPosition)._absorber);
  }

  @override
  void detach(ScrollPosition position) {
    super.detach(position);
    assert(position is AbsorbScrollPosition);
    absorber.detach((position as AbsorbScrollPosition)._absorber);
  }

  @override
  void dispose() {
    super.dispose();
    absorber.dispose();
  }
}
