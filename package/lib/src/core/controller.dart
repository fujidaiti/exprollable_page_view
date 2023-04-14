import 'dart:math';

import 'package:exprollable_page_view/src/internal/scroll.dart';
import 'package:exprollable_page_view/src/internal/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

class InheritedExprollablePageController extends InheritedWidget {
  const InheritedExprollablePageController({
    super.key,
    required super.child,
    required this.controller,
  });

  final ExprollablePageController controller;

  @override
  bool updateShouldNotify(InheritedExprollablePageController oldWidget) =>
      !identical(controller, oldWidget.controller);
}

class InheritedViewportController extends InheritedWidget {
  const InheritedViewportController({
    super.key,
    required super.child,
    required this.controller,
  });

  final ViewportController controller;

  @override
  bool updateShouldNotify(InheritedViewportController oldWidget) =>
      !identical(controller, oldWidget.controller);
}

class InheritedPageContentScrollController extends InheritedWidget {
  const InheritedPageContentScrollController({
    super.key,
    required super.child,
    required this.controller,
  });

  final PageContentScrollController controller;

  @override
  bool updateShouldNotify(InheritedPageContentScrollController oldWidget) =>
      !identical(controller, oldWidget.controller);
}

class _CurrentPageNotifier extends ValueNotifier<int> {
  _CurrentPageNotifier({required this.controller})
      : super(controller.initialPage) {
    controller.addListener(_invalidate);
  }

  final PageController controller;

  void _invalidate() {
    assert(controller.hasClients);
    assert(controller.position.hasContentDimensions);
    final page = controller.page!;
    value = page > value ? page.floor() : page.ceil();
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeListener(_invalidate);
  }
}

class ExprollablePageController extends PageController {
  ExprollablePageController({
    super.initialPage,
    super.keepPage,
    double minViewportFraction = 0.9,
    bool overshootEffect = false,
    ViewportOffset initialViewportOffset = ViewportOffset.shrunk,
    ViewportOffset maxViewportOffset = ViewportOffset.shrunk,
    List<ViewportOffset> snapViewportOffsets = const [
      ViewportOffset.expanded,
      ViewportOffset.shrunk,
    ],
  })  : assert(0 <= minViewportFraction && minViewportFraction <= 1.0),
        super(viewportFraction: minViewportFraction) {
    final snapOffsets = [...snapViewportOffsets]..sort();
    viewport = PageViewport(
      minFraction: viewportFraction,
      absorber: _absorberGroup,
      overshootEffect: overshootEffect,
      initialOffset: initialViewportOffset,
      maxOffset: maxViewportOffset,
    );
    _snapPhysics = _SnapViewportOffsetPhysics(
      snapOffsets: snapOffsets,
      viewport: viewport,
    );
    _currentPage = _CurrentPageNotifier(controller: this);
  }

  final _absorberGroup = ScrollAbsorberGroup();
  final Map<int, PageContentScrollController> _contentScrollControllers = {};

  late final _SnapViewportOffsetPhysics _snapPhysics;

  late final _CurrentPageNotifier _currentPage;
  ValueListenable<int> get currentPage => _currentPage;

  late final PageViewport viewport;

  PageContentScrollController get _contentScrollController {
    assert(_contentScrollControllers.containsKey(currentPage.value));
    return _contentScrollControllers[currentPage.value]!;
  }

  PageContentScrollController createScrollController(int page) {
    assert(!_contentScrollControllers.containsKey(page));
    final controller = PageContentScrollController._(snapPhysics: _snapPhysics);
    _contentScrollControllers[page] = controller;
    _absorberGroup.attach(controller.absorber);
    return controller;
  }

  void disposeScrollController(int page) {
    assert(_contentScrollControllers.containsKey(page));
    final controller = _contentScrollControllers.remove(page)!;
    _absorberGroup.detach(controller.absorber);
    controller.dispose();
  }

  @override
  void dispose() {
    super.dispose();
    _absorberGroup.dispose();
    _currentPage.dispose();
  }

  Future<void> animateViewportOffsetTo(
    ViewportOffset offset, {
    required Curve curve,
    required Duration duration,
  }) {
    return _contentScrollController.animateTo(
      offset.toScrollOffset(viewport),
      curve: curve,
      duration: duration,
    );
  }

  void jumpViewportOffsetTo(ViewportOffset offset) {
    _contentScrollController.jumpTo(offset.toScrollOffset(viewport));
  }

  static ExprollablePageController? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<InheritedExprollablePageController>()
      ?.controller;
}

@immutable
class ViewportDimensions {
  final double width;
  final double height;
  final EdgeInsets padding;

  const ViewportDimensions({
    required this.width,
    required this.height,
    required this.padding,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (runtimeType == other.runtimeType &&
          other is ViewportDimensions &&
          width == other.width &&
          height == other.height &&
          padding == other.padding);

  @override
  int get hashCode => Object.hash(runtimeType, width, height, padding);
}

mixin ViewportMetrics {
  ViewportDimensions get dimensions;
  bool get hasDimensions;
  double get fraction;
  double get minFraction;
  double get maxFraction;
  double get offset;
  double get minOffset;
  double get maxOffset;

  double get deltaOffset {
    assert(minOffset <= maxOffset);
    return maxOffset - minOffset;
  }

  double get deltaFraction {
    assert(minFraction <= maxFraction);
    return maxFraction - minFraction;
  }
}

mixin PageViewportMetrics on ViewportMetrics {
  bool get overshootEffect;
  double get shrunkOffset;
  double get expandedOffset;
  bool get isShrunk => offset >= shrunkOffset;
  bool get isExpanded => offset <= expandedOffset;
}

@immutable
class StaticPageViewportMetrics with ViewportMetrics, PageViewportMetrics {
  const StaticPageViewportMetrics({
    required this.fraction,
    required this.minFraction,
    required this.maxFraction,
    required this.offset,
    required this.minOffset,
    required this.maxOffset,
    required this.shrunkOffset,
    required this.expandedOffset,
    required this.dimensions,
    required this.overshootEffect,
  });

  factory StaticPageViewportMetrics.from(
    PageViewportMetrics metrics,
  ) =>
      StaticPageViewportMetrics(
        fraction: metrics.fraction,
        minFraction: metrics.minFraction,
        maxFraction: metrics.maxFraction,
        offset: metrics.offset,
        minOffset: metrics.minOffset,
        maxOffset: metrics.maxOffset,
        shrunkOffset: metrics.shrunkOffset,
        expandedOffset: metrics.expandedOffset,
        dimensions: metrics.dimensions,
        overshootEffect: metrics.overshootEffect,
      );

  @override
  final double fraction;

  @override
  final double minFraction;

  @override
  final double maxFraction;

  @override
  final double offset;

  @override
  final double minOffset;

  @override
  final double maxOffset;

  @override
  final double shrunkOffset;

  @override
  final double expandedOffset;

  @override
  final ViewportDimensions dimensions;

  @override
  final bool overshootEffect;

  @override
  bool get hasDimensions => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaticPageViewportMetrics &&
          runtimeType == other.runtimeType &&
          fraction == other.fraction &&
          minFraction == other.minFraction &&
          maxFraction == other.maxFraction &&
          offset == other.offset &&
          minOffset == other.minOffset &&
          maxOffset == other.maxOffset &&
          shrunkOffset == other.shrunkOffset &&
          expandedOffset == other.expandedOffset &&
          dimensions == other.dimensions);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        fraction,
        minFraction,
        maxFraction,
        offset,
        minOffset,
        maxOffset,
        shrunkOffset,
        expandedOffset,
        dimensions,
      );
}

class PageViewportUpdateNotification extends Notification {
  const PageViewportUpdateNotification(this.metrics);
  final PageViewportMetrics metrics;
}

class PageViewport extends ChangeNotifier
    with ViewportMetrics, PageViewportMetrics
    implements ValueListenable<PageViewportMetrics> {
  PageViewport({
    required this.minFraction,
    required this.overshootEffect,
    required ScrollAbsorber absorber,
    required ViewportOffset initialOffset,
    required ViewportOffset maxOffset,
  })  : assert(0.0 <= minFraction && minFraction <= 1.0),
        _absorber = absorber,
        _maxOffset = maxOffset,
        _initialOffset = initialOffset {
    _absorber.addListener(_invalidateState);
  }

  final ViewportOffset _maxOffset;
  final ViewportOffset _initialOffset;
  final ScrollAbsorber _absorber;

  @override
  final bool overshootEffect;

  @override
  PageViewportMetrics get value => this;

  ViewportDimensions? _dimensions;

  @override
  ViewportDimensions get dimensions {
    assert(hasDimensions);
    return _dimensions!;
  }

  @override
  bool get hasDimensions => _dimensions != null;

  @override
  double get maxOffset => _maxOffset.toConcreteValue(this);

  @override
  double get minOffset => expandedOffset;

  double? _offset;

  @override
  double get offset {
    assert(hasDimensions);
    return _offset!;
  }

  @override
  final double minFraction;

  @override
  double get maxFraction => 1.0;

  double? _fraction;

  @override
  double get fraction {
    assert(hasDimensions);
    return _fraction!;
  }

  @override
  double get expandedOffset =>
      const ExpandedViewportOffset().toConcreteValue(this);

  @override
  double get shrunkOffset => const ShrunkViewportOffset().toConcreteValue(this);

  double get _initialAbsorberPixels {
    final initialOffset = _initialOffset.toConcreteValue(this);
    assert(initialOffset >= minOffset);
    return initialOffset - minOffset;
  }

  void correctForNewDimensions(ViewportDimensions dimensions) {
    _dimensions = dimensions;
    _absorber.correct((it) {
      it.capacity = deltaOffset;
      if (it.pixels == null) {
        it.absorb(_initialAbsorberPixels);
      }
    });

    _correctState();
  }

  void _correctState() {
    _fraction = _computeFraction();
    _offset = _computeOffset();
  }

  void _invalidateState() {
    final oldOffset = offset;
    final oldFraction = fraction;
    _correctState();
    if (!oldFraction.almostEqualTo(fraction) ||
        !oldOffset.almostEqualTo(offset)) {
      notifyListeners();
    }
  }

  double _computeOffset() {
    assert(_absorber.pixels != null);
    return minOffset + _absorber.pixels!;
  }

  double _computeFraction() {
    assert(_absorber.pixels != null);
    assert(hasDimensions);

    final a = _absorber;
    final dim = dimensions;

    final offset = max(0.0, _computeOffset());
    final lowerBoundFraction = overshootEffect
        ? (dim.height - dim.padding.bottom - offset) / dim.height
        : (dim.height - offset) / dim.height;

    final delta = shrunkOffset - expandedOffset;
    assert(delta > 0.0);
    final t = 1.0 - (a.absorbedPixels! / delta).clamp(0.0, 1.0);
    const curve = Curves.easeIn;
    final fraction = curve.transform(t) * deltaFraction + minFraction;
    return max(lowerBoundFraction, fraction);
  }
}

class ViewportController extends ChangeNotifier
    with ViewportMetrics
    implements ValueListenable<ViewportMetrics> {
  ViewportController({
    required this.page,
    required ExprollablePageController pageController,
  }) : _pageController = pageController {
    _pageController
      ..currentPage.addListener(_invalidateState)
      ..viewport.addListener(_invalidateState);
  }

  @override
  void dispose() {
    super.dispose();
    _pageController
      ..currentPage.removeListener(_invalidateState)
      ..viewport.removeListener(_invalidateState);
  }

  final int page;
  final ExprollablePageController _pageController;

  late Offset _translation = _computeTranslation();
  late double _fraction = _computeFraction();

  Offset get translation => _translation;

  @override
  double get fraction => _fraction;

  @override
  double get minFraction => _pageController.viewport.minFraction;

  @override
  double get maxFraction => _pageController.viewport.maxFraction;

  @override
  ViewportDimensions get dimensions => _pageController.viewport.dimensions;

  @override
  bool get hasDimensions => _pageController.viewport.hasDimensions;

  @override
  double get offset => _isPageActive
      ? _pageController.viewport.offset
      : max(0.0, _pageController.viewport.offset) + translation.dy;

  @override
  double get minOffset => _isPageActive
      ? _pageController.viewport.minOffset
      : dimensions.padding.top;

  @override
  double get maxOffset => _pageController.viewport.offset;

  @override
  ViewportMetrics get value => this;

  bool get _isPageActive => page == _pageController.currentPage.value;

  Offset _computeTranslation() => Offset(
        _computeHorizontalTranslation(),
        _computeVerticalTranslation(),
      );

  double _computeVerticalTranslation() {
    final vp = _pageController.viewport;
    if (_isPageActive) {
      return min(vp.offset, 0.0);
    } else {
      return (vp.dimensions.padding.top - vp.offset)
          .clamp(0.0, vp.dimensions.padding.top);
    }
  }

  double _computeHorizontalTranslation() {
    final vp = _pageController.viewport;
    if (_isPageActive) {
      return vp.dimensions.width * (vp.fraction - vp.minFraction) / -2.0;
    } else {
      final isOnLeftSide = page < _pageController.currentPage.value;
      return isOnLeftSide
          ? -vp.dimensions.width * (vp.fraction - vp.minFraction) * 1.5
          : vp.dimensions.width * (vp.fraction - vp.minFraction) / 2.0;
    }
  }

  double _computeFraction() => _pageController.viewport.fraction;

  void _correctState() {
    _translation = _computeTranslation();
    _fraction = _computeFraction();
  }

  void _invalidateState() {
    final oldTranslation = translation;
    final oldOffset = offset;
    final oldFraction = fraction;
    _correctState();
    if (!oldTranslation.dx.almostEqualTo(translation.dx) ||
        !oldTranslation.dy.almostEqualTo(translation.dy) ||
        !oldOffset.almostEqualTo(offset) ||
        !oldFraction.almostEqualTo(fraction)) {
      notifyListeners();
    }
  }

  static ViewportController? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<InheritedViewportController>()
      ?.controller;
}

class PageContentScrollController extends AbsorbScrollController {
  PageContentScrollController._(
      {required _SnapViewportOffsetPhysics? snapPhysics})
      : _snapPhysics = snapPhysics;

  final _SnapViewportOffsetPhysics? _snapPhysics;

  @override
  double get initialScrollOffset {
    assert(absorber.pixels != null);
    // TODO: Consider the cases where [ScrollPosition.minScrollExtent] is non zero.
    return -1 * absorber.pixels!;
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) =>
      super.createScrollPosition(
        _snapPhysics?.applyTo(physics) ?? physics,
        context,
        oldPosition,
      );

  static PageContentScrollController? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<
          InheritedPageContentScrollController>()
      ?.controller;
}

class _SnapViewportOffsetPhysics extends ScrollPhysics {
  // ignore: prefer_const_constructors_in_immutables
  _SnapViewportOffsetPhysics({
    super.parent,
    required this.snapOffsets,
    required this.viewport,
  });

  final List<ViewportOffset> snapOffsets;
  final PageViewport viewport;

  @override
  ScrollPhysics applyTo(ScrollPhysics? ancestor) => _SnapViewportOffsetPhysics(
        parent: buildParent(ancestor),
        snapOffsets: snapOffsets,
        viewport: viewport,
      );

  double? findScrollSnapPosition(ScrollMetrics position, double velocity) {
    // TODO; Find more appropriate threshold
    const thresholdVelocity = 2000;
    if (velocity.abs() > thresholdVelocity) return null;
    if (snapOffsets.isEmpty) return null;

    assert(
      listEquals(snapOffsets, [...snapOffsets]..sort()),
      "'snapOffsets' must be sorted in ascending order.",
    );

    final minSnap = snapOffsets.last.toScrollOffset(viewport);
    final maxSnap = snapOffsets.first.toScrollOffset(viewport);
    if (position.pixels < minSnap || position.pixels > maxSnap) {
      return null;
    }

    final pixels = position.pixels;
    double nearest(double p, double q) =>
        (pixels - p).abs() < (pixels - q).abs() ? p : q;

    return snapOffsets.map((it) => it.toScrollOffset(viewport)).reduce(nearest);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final snapTo = findScrollSnapPosition(position, velocity);
    if (snapTo == null) {
      return super.createBallisticSimulation(position, velocity);
    }
    return (position.pixels - snapTo).abs() < tolerance.distance
        ? null
        : ScrollSpringSimulation(
            spring,
            position.pixels,
            snapTo,
            velocity,
            tolerance: tolerance,
          );
  }
}

@sealed
abstract class ViewportOffset implements Comparable<ViewportOffset> {
  static const expanded = ExpandedViewportOffset();
  static const shrunk = ShrunkViewportOffset();

  const factory ViewportOffset.fractional(double fraction) =
      FractionalViewportOffset;

  const ViewportOffset();

  double toConcreteValue(PageViewportMetrics metrics);

  double toScrollOffset(PageViewportMetrics metrics) {
    final offset = toConcreteValue(metrics);
    assert(offset >= metrics.minOffset);
    return -1 * (offset - metrics.minOffset);
  }

  bool operator >(ViewportOffset other) => compareTo(other) > 0;
  bool operator <(ViewportOffset other) => compareTo(other) < 0;
  bool operator >=(ViewportOffset other) => this > other || this == other;
  bool operator <=(ViewportOffset other) => this < other || this == other;
}

class ExpandedViewportOffset extends ViewportOffset {
  const ExpandedViewportOffset();

  @override
  double toConcreteValue(PageViewportMetrics metrics) {
    return metrics.overshootEffect
        ? -1 * metrics.dimensions.padding.bottom
        : 0.0;
  }

  @override
  int compareTo(ViewportOffset other) {
    if (other is FractionalViewportOffset || other is ShrunkViewportOffset) {
      return -1;
    }
    assert(other is ExpandedViewportOffset);
    return 0;
  }

  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class ShrunkViewportOffset extends ViewportOffset {
  const ShrunkViewportOffset();

  @override
  double toConcreteValue(PageViewportMetrics metrics) {
    assert(metrics.hasDimensions);
    const margin = 16.0;
    final preferredOffset = metrics.dimensions.padding.top + margin;
    final lowerBoundOffset =
        (1.0 - metrics.minFraction) * metrics.dimensions.height;
    return max(preferredOffset, lowerBoundOffset);
  }

  @override
  int compareTo(ViewportOffset other) {
    if (other is ExpandedViewportOffset) return 1;
    if (other is ShrunkViewportOffset) return 0;
    assert(other is FractionalViewportOffset);
    final fraction = (other as FractionalViewportOffset).fraction;
    return fraction == 0.0 ? 0 : -1;
  }

  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class FractionalViewportOffset extends ViewportOffset {
  const FractionalViewportOffset(this.fraction)
      : assert(0.0 <= fraction && fraction <= 1.0);

  final double fraction;

  @override
  double toConcreteValue(PageViewportMetrics metrics) {
    return fraction *
            (metrics.dimensions.height -
                metrics.dimensions.padding.bottom -
                metrics.shrunkOffset) +
        metrics.shrunkOffset;
  }

  @override
  int compareTo(ViewportOffset other) {
    if (other is ExpandedViewportOffset) return 1;
    if (other is ShrunkViewportOffset) return fraction == 0.0 ? 0 : 1;
    assert(other is FractionalViewportOffset);
    return fraction.compareTo((other as FractionalViewportOffset).fraction);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FractionalViewportOffset &&
          runtimeType == other.runtimeType &&
          fraction == other.fraction);

  @override
  int get hashCode => Object.hash(runtimeType, fraction);
}
