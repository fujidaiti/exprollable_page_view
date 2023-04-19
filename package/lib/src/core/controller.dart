import 'dart:math';

import 'package:exprollable_page_view/src/internal/scroll.dart';
import 'package:exprollable_page_view/src/internal/utils.dart';
import 'package:exprollable_page_view/src/core/view.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

/// An inherited widget used in [ExprollablePageView] to provides
/// its [ExprollablePageController] to its descendants.
/// [ExprollablePageController.of] is an convenience method that obtains
/// the controller sotred in this inherited widget.
@internal
class InheritedExprollablePageController extends InheritedWidget {
  const InheritedExprollablePageController({
    super.key,
    required super.child,
    required this.controller,
  });

  /// A controller that attached to the ancestor [ExprollablePageView].
  final ExprollablePageController controller;

  @override
  bool updateShouldNotify(InheritedExprollablePageController oldWidget) =>
      !identical(controller, oldWidget.controller);
}

/// An inherited widget that provides a [ViewportController] to its descendants.
@internal
class InheritedViewportController extends InheritedWidget {
  const InheritedViewportController({
    super.key,
    required super.child,
    required this.controller,
  });

  /// A provided controller.
  final ViewportController controller;

  @override
  bool updateShouldNotify(InheritedViewportController oldWidget) =>
      !identical(controller, oldWidget.controller);
}

/// An inherited widget that provides a [PageContentScrollController] to its descendants.
@internal
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

/// A controller for [ExprollablePageView].
///
/// A [ExprollablePageController] lets you manipulate which page is visible in a [ExprollablePageView].
/// It also can be used to programmatically change the viewport state.
class ExprollablePageController extends PageController {
  /// Create a page controller.
  ///
  /// `snapViewportOffsets` is used to specify the viewport offsets that the active page will snap to.
  /// [ViewportOffset.explored] and [ViewportOffset.shrunk] are set to be snaped by default.
  /// If you specify additional offsets, you may need to also specify `maxViewportOffset`
  /// to be able to drag the page to the additional snap offsets larger than [ViewportOffset.shrunk].
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

  /// A notifier that stores the index of the current visible page.
  /// The new index is notified whenever the page that fully occupies the viewport changes.
  /// [ExprollablePageController.initialPage] is used as an initial value.
  ValueListenable<int> get currentPage => _currentPage;
  late final _CurrentPageNotifier _currentPage;

  /// An object that stores the viewport state.
  /// You can subscribe this object to get notified when the viewport state changes.
  late final PageViewport viewport;

  PageContentScrollController get _contentScrollController {
    assert(_contentScrollControllers.containsKey(currentPage.value));
    return _contentScrollControllers[currentPage.value]!;
  }

  /// Creates a [ScrollController] associated with this controller
  /// for a page in the [ExprollablePageView].
  ///
  /// [InheritedPageContentScrollController] is used to provide the created controller
  /// to the descendant widgets of the [ExprollablePageView] and it can be obtained
  /// using [PageContentScrollController.of].
  @internal
  PageContentScrollController createScrollController(int page) {
    assert(!_contentScrollControllers.containsKey(page));
    final controller = PageContentScrollController._(snapPhysics: _snapPhysics);
    _contentScrollControllers[page] = controller;
    _absorberGroup.attach(controller.absorber);
    return controller;
  }

  /// Dispose the [ScrollController] which is created by [createScrollController] for [page].
  @internal
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

  /// Animates the controlled [ExprollablePageView] from the current viewport offset
  /// to the given offset.
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

  /// instantly changes the current viewport offset without animation.
  void jumpViewportOffsetTo(ViewportOffset offset) {
    _contentScrollController.jumpTo(offset.toScrollOffset(viewport));
  }

  /// Obtians a controller from an ancestor [InheritedExprollablePageController]
  /// if exists, return null otherwise.
  ///
  /// The [ExprollablePageView] has an [InheritedExprollablePageController] as its descendant,
  /// so you can use this method anywhere in the subtree of the page view.
  /// Note that the instance of the provided controller may changes; if you subscribe it,
  /// do not forget to unbscribe the old one in [State.didChangeDependencies].
  static ExprollablePageController? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<InheritedExprollablePageController>()
      ?.controller;
}

/// A description of the viewport mesurements.
@immutable
class ViewportDimensions {
  /// The width dimension in pixels.
  final double width;

  // The height dimension in pixels.
  final double height;

  /// The padding set aorund the viewport.
  ///
  /// This does not include dynamically added padding
  /// (e.g., software keyboard padding shown on the screen).
  final EdgeInsets padding;

  /// A description of the viewport mesurements.
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

/// A description of the viewport state.
///
/// The state of the viewport is described by the 2 mesurements: fraction and offset.
/// A fraction indicates how much space each page should occupy in the viewport,
/// and it must be between 0.0 and 1.0. An offset is the distance from the top of the viewport
/// to the top of a page.
///
/// ![viewport-fraction-offset](https://user-images.githubusercontent.com/68946713/231830114-f4d9bec4-cb85-41f8-a9fd-7b3f21ff336a.png)
///
mixin ViewportMetrics {
  /// A static description of the viewport mesurements.
  /// Available only if [hasDimensions] is true.
  ViewportDimensions get dimensions;

  /// Indicates if [dimensions] property is available.
  bool get hasDimensions;

  /// Indicates how much space each page should occupy in the viewport.
  /// [fraction] is between [minFraction] and [maxFraction] including both edges.
  double get fraction;

  /// The lower bound of [fraction].
  double get minFraction;

  /// The upper bound of [fraction].
  double get maxFraction;

  /// The distance from the top of the viewport to the top of the current page.
  ///
  /// [offset] is always greater than or equals to [minOffset], but might exceeds [maxOffset].
  /// For eample, if the scrollable widget in the current page uses [BouncingScrollPhysics]
  /// as its scroll physics and a user tries to overscroll the page,
  /// [offset] will exceeds [maxOffset] according to the physics.
  double get offset;

  /// The lower bound of the offset.
  double get minOffset;

  /// The upper bound of the offset. The actual [offset] might exceeds this value.
  double get maxOffset;

  /// Calculate the difference between [minOffset] and [maxOffset].
  double get deltaOffset {
    assert(minOffset <= maxOffset);
    return maxOffset - minOffset;
  }

  /// Calculate the difference between [minFraction] and [maxOffset].
  double get deltaFraction {
    assert(minFraction <= maxFraction);
    return maxFraction - minFraction;
  }
}

/// A description of the state of the **conceptual** viewport.
mixin PageViewportMetrics on ViewportMetrics {
  /// Inidicates if overshoot effect is enabled. If [overshootEffect] is enabled,
  /// the upper segment of the active page will slightly exceed the top of the viewport when it goes fullscreen.
  /// To be precise, this means that the viewport offset will take a negative value when the viewport fraction is 1.0.
  /// This trick creates a dynamic visual effect when the page goes fullscreen.
  /// The figures below are a demonstration of how the overshoot effect affects (disabled in the left, enabled in the right).
  ///
  /// ![overshoot-disabled](https://user-images.githubusercontent.com/68946713/231827343-155a750d-b21f-4a96-b81a-74c8873c46cb.gif) ![overshoot-enabled](https://user-images.githubusercontent.com/68946713/231827364-40843efc-5a91-49ff-ab74-c9af1e4b0c62.gif)
  ///
  /// Overshoot effect will works correctly only if:
  ///
  /// - `MediaQuery.padding.bottom` > 0
  /// - Ther lower segment of `ExprollablePageView` is behind a widget such as `NavigationBar`, `BottomAppBar`
  ///
  /// Perhaps the most common use is to wrap an `ExprollablePageView` with a `Scaffold`. In that case, do not forget to enable `Scaffold.extentBody` and then everything should be fine.
  ///
  /// ```dart
  /// controller = ExprollablePageController(overshootEffect: true);
  ///
  /// Widget build(BuildContext context) {
  ///   return Scaffold(
  ///     extendBody: true,
  ///     bottomNavigationBar: BottomNavigationBar(...),
  ///     body: ExprollablePageView(
  ///       controller: controller,
  ///       itemBuilder: (context, page) { ... },
  ///     ),
  ///   );
  /// }
  /// ```
  ///
  bool get overshootEffect;

  /// The lower bound of the offset at which the viewport is fully shrunk.
  double get shrunkOffset;

  /// The upper bound of the offset at which the viewport is fully expanded.
  double get expandedOffset;

  /// Indicates if the viewport is fully shrunk.
  bool get isShrunk => offset >= shrunkOffset;

  // Indicates if the viewport is fully expanded.
  bool get isExpanded => offset <= expandedOffset;
}

/// A snapshot of the state of the conceptual viewport.
@immutable
class StaticPageViewportMetrics with ViewportMetrics, PageViewportMetrics {
  /// Create a snapshot of the viewport state.
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

  /// Create a [StaticPageViewportMetrics] copying another [PageViewportMetrics].
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

/// A notification that bubbles up the widget tree from a [ExprollablePageView] whenever the viewport state changes.
/// Listening for this notification is equivalent to observe [ExprollablePageController.viewport].
class PageViewportUpdateNotification extends Notification {
  const PageViewportUpdateNotification(this.metrics);
  final PageViewportMetrics metrics;
}

/// An object that represents the state of the **conceptual** viewport.
///
/// "Conceptual" means that the actual measurements for each page is calculated according to the state of this object,
/// and individually managed by [ViewportController]s attached to the pages.
/// This is because the visual position of each page may differ, for example,
/// the default behavior of [PageViewport] is for the offset of the active page to be zero
/// (or negative if overshoot effect is enabled) when it is fully expanded,
/// but the offset for the inactive page is positive even if the active page is fully expanded.
///
/// This object subscribes to the given [ScrollAbsorber] to calculates the [offset] and [fraction]
/// depending on [ScrollAbsorber.pixels], and if there are any changes, notifies its listeners.
class PageViewport extends ChangeNotifier
    with ViewportMetrics, PageViewportMetrics
    implements ValueListenable<PageViewportMetrics> {
  /// Creates an object that represents the state of the **conceptual** viewport.
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

  /// Correct the state of this object for the given [dimensions].
  /// This method should be called whenever the dimensions of the viewport changes in [ExprollablePageView.build].
  /// Therefore this method does not notify its listeners even if the state changes after recalculation.
  @internal
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

/// Stores the actual metrics of the viewport for a specific [page].
/// Some of the metrics may be different from those of the conceptulal viewport
/// depending on whether the page is active or not.
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

  /// The page corresponding to the viewport that this object represents.
  final int page;

  final ExprollablePageController _pageController;

  late Offset _translation = _computeTranslation();
  late double _fraction = _computeFraction();

  /// How many pixels the page should translate from the actual position in the page view.
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

  /// Obtains the [ViewportController] of a page that is the nearest ancestor from [context].
  static ViewportController? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<InheritedViewportController>()
      ?.controller;
}

/// A [ScrollController] that must be attached to a [Scrollable] widget in each page.
///
/// Since [PageViewport] subscribes to [PageContentScrollController.absorber]
/// to calculate the viewport state according to the scroll position,
/// it is important that the [PageContentScrollController] obtained from
/// [PageContentScrollController.of] is attached to a [Scrollable] widget in each page.
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

  /// Obtains the [PageContentScrollController] for a page that is the nearest ancestor from [context].
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

/// An object that represents a viewport offset.
///
/// There are 2 pre-defined offsets, [ViewportOffset.expanded] and [ViewportOffset.shrunk],
/// at which the viewport fraction is 1.0 and the minimum, respectively.
/// A user defined offset can be created from a fractional value using [ViewportOffset.fractional].
/// For example, `ViewportOffset.fractional(1.0)` is equivalent to [ViewportOffset.shrunk],
/// and `ViewportOffset.fractional(0.0)` matches the bottom of the viewport.
/// [ViewportOffset]s are comarable. The order is:
/// - `ViewportOffset.expanded < ViewportOffset.shrunk`
/// -  `ViewportOffset.shrunk == ViewportOffset.fractional(1.0)`
/// -  `ViewportOffset.fractional(1.0) < ViewportOffset.fractional(0.0)`
///
/// ![viewport-offsets](https://user-images.githubusercontent.com/68946713/231827251-fed9575c-980a-40b8-b01a-da984d58f3ec.png)
@sealed
abstract class ViewportOffset implements Comparable<ViewportOffset> {
  /// The offset at which the viewport is fully expanded
  /// (more precisely, when [PageViewport.fraction] is equal to [PageViewport.maxFraction]).
  static const expanded = ExpandedViewportOffset();

  /// The offset at which the viewport is fully shrunk
  /// (more precisely, when [PageViewport.fraction] is equal to [PageViewport.minFraction]).
  static const shrunk = ShrunkViewportOffset();

  /// Create an user defined viewport offset from a fractional value.
  /// [fraction] must be between 0.0 and 1.0.
  const factory ViewportOffset.fractional(double fraction) =
      FractionalViewportOffset;

  const ViewportOffset();

  /// Calculate the concrete pixels represented by this object
  /// from the current viewport dimensions.
  double toConcreteValue(PageViewportMetrics metrics);

  /// Convert the offset to a scroll offset for [ScrollPosition].
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

/// The upper bound of the offset at which the viewport is fully expanded.
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

/// The lower bound of the offset at which the viewport is fully shrunk.
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

/// A viewport offset that is defined by a fractional value.
///
/// `fraction == 1.0` is equivalent to [ViewportOffset.shrunk],
/// and `fraction == 0.0` corresponds to the bottom of the viewport excluding the padding.
class FractionalViewportOffset extends ViewportOffset {
  /// Creates a viewport offset from a fractional value.
  /// [fraction] must be between 0.0 and 1.0.
  const FractionalViewportOffset(this.fraction)
      : assert(0.0 <= fraction && fraction <= 1.0);

  /// The fractional value of the offset.
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
