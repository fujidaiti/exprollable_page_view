import 'dart:math';

import 'package:exprollable_page_view/src/internal/scroll.dart';
import 'package:exprollable_page_view/src/internal/utils.dart';
import 'package:exprollable_page_view/src/core/view.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// An inherited widget used in [ExprollablePageView] to provides
/// its [ExprollablePageController] to its descendants.
/// [ExprollablePageController.of] is a convenience method that obtains
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
/// This lets you manipulate which page is visible in a [ExprollablePageView].
/// It also can be used to programmatically change the viewport state.
class ExprollablePageController extends PageController {
  /// Create a page controller.
  ///
  /// Specifying [viewportFractionBehavior] allows you to control how the viewport fraction changes
  /// along with vertical scrolling. [DefaultViewportFractionBehavior] is used by default.
  ///
  /// To configure the metrics of the viewport, specify [viewportConfiguration] with the desired values.
  /// [ViewportConfiguration.defaultConfiguration] is used as the default configuration.
  ExprollablePageController({
    super.initialPage,
    super.keepPage,
    ViewportConfiguration viewportConfiguration =
        ViewportConfiguration.defaultConfiguration,
    ViewportFractionBehavior viewportFractionBehavior =
        const DefaultViewportFractionBehavior(),
  }) : super(viewportFraction: viewportConfiguration.minFraction) {
    viewport = PageViewport(
      absorber: _absorberGroup,
      fractionBehavior: viewportFractionBehavior,
      configuration: viewportConfiguration,
    );
    _snapPhysics = _SnapViewportOffsetPhysics(
      snapOffsets: viewportConfiguration.snapOffsets,
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

  /// {@template exprollable_page_view.controller.ViewportMetrics.minFraction}
  /// The lower bound of [fraction].
  /// {@endtemplate}
  double get minFraction;

  /// {@template exprollable_page_view.controller.ViewportMetrics.maxFraction}
  /// The upper bound of [fraction].
  /// {@endtemplate}
  double get maxFraction;

  /// The distance from the top of the viewport to the top of the current page.
  ///
  /// [offset] is always greater than or equals to [minOffset], but might exceeds [maxOffset].
  /// For eample, if the scrollable widget in the current page uses [BouncingScrollPhysics]
  /// as its scroll physics and a user tries to overscroll the page,
  /// [offset] will exceeds [maxOffset] according to the physics.
  double get offset;

  /// {@template exprollable_page_view.controller.ViewportMetrics.minOffset}
  /// The lower bound of the offset.
  /// {@endtemplate}
  double get minOffset;

  /// {@template exprollable_page_view.controller.ViewportMetrics.maxOffset}
  /// The upper bound of the offset. The actual [offset] might exceeds this value.
  /// {@endtemplate}
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
  /// {@template exprollable_page_view.controller.PageViewportMetrics.shrunkOffset}
  /// The lower bound of the offset at which the viewport is fully shrunk.
  /// {@endtemplate}
  double get shrunkOffset;

  /// {@template exprollable_page_view.controller.PageViewportMetrics.expandedOffset}
  /// The upper bound of the offset at which the viewport is fully expanded.
  /// {@endtemplate}
  double get expandedOffset;

  /// Indicates if the viewport is fully shrunk.
  bool get isShrunk =>
      offset.almostEqualTo(shrunkOffset) || offset > shrunkOffset;

  // Indicates if the viewport is fully expanded.
  bool get isExpanded =>
      offset.almostEqualTo(expandedOffset) || offset < expandedOffset;
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

/// Describes how the viewport fraction changes when the page is scrolled vertically .
///
/// Use the convenient [DefaultViewportFractionBehavior] which implements the default behavior,
/// or extend this class and override [preferredFraction] to create a custom behavior.
abstract class ViewportFractionBehavior {
  /// Calculate the viewport fraction according to the state of the current viewport and the new offset.
  ///
  /// This method is called by [PageViewport] whenever the fraction should be updated.
  /// The calculated fraction must be [PageViewportMetrics.minFraction]
  /// when [PageViewportMetrics.offset] is greater than or equal to [PageViewportMetrics.shrunkOffset],
  /// and must be [PageViewportMetrics.maxFraction] when [PageViewportMetrics.offset] is less than or equal to [PageViewportMetrics.expandedOffset].
  /// There's no restriction in the other cases, but it will usually took a value
  /// between [PageViewportMetrics.minFraction] and [PageViewportMetrics.maxFraction].
  double preferredFraction(PageViewportMetrics viewport, double newOffset);
}

/// The default implementation of [ViewportFractionBehavior].
///
/// The calculated viewport fractions take values between [PageViewportMetrics.minFraction]
/// and [PageViewportMetrics.maxFraction], along the [curve].
class DefaultViewportFractionBehavior implements ViewportFractionBehavior {
  /// Create the default implementation of [ViewportFractionBehavior].
  const DefaultViewportFractionBehavior({this.curve = Curves.easeIn});

  /// The curve of the viewport fraction.
  final Curve curve;

  @override
  double preferredFraction(PageViewportMetrics viewport, double newOffset) {
    assert(viewport.hasDimensions);
    final pixels = newOffset - viewport.expandedOffset;
    final delta = viewport.shrunkOffset - viewport.expandedOffset;
    assert(delta > 0.0);
    final t = 1.0 - (pixels / delta).clamp(0.0, 1.0);
    return curve.transform(t) * viewport.deltaFraction + viewport.minFraction;
  }
}

/// A configuration for the viewport.
class ViewportConfiguration {
  /// A const object to be used as the default configuration of [PageViewport].
  static const defaultConfiguration = ViewportConfiguration.raw(
    minFraction: 0.9,
    maxFraction: 1.0,
    minOffset: ViewportOffset.expanded,
    maxOffset: ViewportOffset.shrunk,
    shrunkOffset: ViewportOffset.shrunk,
    expandedOffset: ViewportOffset.expanded,
    initialOffset: ViewportOffset.shrunk,
    snapOffsets: [ViewportOffset.expanded, ViewportOffset.shrunk],
  );

  /// A general constructor for [ViewportConfiguration].
  ///
  /// It is recommended to use [ViewportConfiguration.new],
  /// which is a convenient constructor sufficient for most use cases.
  const ViewportConfiguration.raw({
    required this.minFraction,
    required this.maxFraction,
    required this.minOffset,
    required this.maxOffset,
    required this.shrunkOffset,
    required this.expandedOffset,
    required this.initialOffset,
    required this.snapOffsets,
  });

  /// Create a configuration for standard use cases.
  ///
  /// If [extraSnapOffsets] is not empty, viewport will snap to the offsets
  /// given by [extraSnapOffsets] in addition to [ViewportOffset.expanded] and [ViewportOffset.shrunk].
  /// The list must be sorted in ascending order by the actual offset value
  /// calculated from [ViewportOffset.toConcreteValue].
  ///
  /// If [initialOffset] is not specified, the last element in [extraSnapOffsets]
  /// is used as the initial offset. If [extraSnapOffsets] is also not specified,
  /// [initialOffset] is set to [shrunkOffset].
  ///
  /// If [overshootEffect] is enabled, the upper segment of the active page will
  /// slightly exceed the top of the viewport when it goes fullscreen.
  /// To be precise, this means that the viewport offset will take a negative value
  /// when the viewport fraction is 1.0. This trick creates a dynamic visual effect
  /// when the page goes fullscreen. The figures below are a demonstration of
  /// how the overshoot effect affects (disabled in the left, enabled in the right).
  ///
  /// ![overshoot-disabled](https://user-images.githubusercontent.com/68946713/231827343-155a750d-b21f-4a96-b81a-74c8873c46cb.gif) ![overshoot-enabled](https://user-images.githubusercontent.com/68946713/231827364-40843efc-5a91-49ff-ab74-c9af1e4b0c62.gif)
  ///
  /// Overshoot effect will works correctly only if:
  ///
  /// - [MediaQueryData.padding.data] > 0
  /// - Ther lower segment of [ExprollablePageView] is behind a widget such as [NavigationBar], [BottomAppBar]
  ///
  /// Perhaps the most common use is to wrap an [ExprollablePageView] with a [Scaffold].
  /// In that case, do not forget to enable [Scaffold.extentBody] and then everything should be fine.
  ///
  /// ```dart
  /// controller = ExprollablePageController(
  ///   viewportConfiguration: ViewportConfiguration(
  ///    overshootEffect: true,
  ///   ),
  /// );
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
  factory ViewportConfiguration({
    bool overshootEffect = false,
    double minFraction = 0.9,
    double maxFraction = 1.0,
    ViewportOffset shrunkOffset = ViewportOffset.shrunk,
    ViewportOffset? initialOffset,
    List<ViewportOffset> extraSnapOffsets = const [],
  }) {
    final expandedOffset =
        overshootEffect ? ViewportOffset.overshoot : ViewportOffset.expanded;
    final snapOffsets = [
      expandedOffset,
      shrunkOffset,
      ...extraSnapOffsets,
    ];
    return ViewportConfiguration.raw(
      minFraction: minFraction,
      maxFraction: maxFraction,
      minOffset: expandedOffset,
      maxOffset: snapOffsets.last,
      shrunkOffset: shrunkOffset,
      expandedOffset: expandedOffset,
      initialOffset: initialOffset ?? snapOffsets.last,
      snapOffsets: snapOffsets,
    );
  }

  /// {@macro exprollable_page_view.controller.ViewportMetrics.minFraction}
  final double minFraction;

  /// {@macro exprollable_page_view.controller.ViewportMetrics.maxFraction}
  final double maxFraction;

  /// {@macro exprollable_page_view.controller.ViewportMetrics.minOffset}
  final ViewportOffset minOffset;

  /// {@macro exprollable_page_view.controller.ViewportMetrics.maxOffset}
  final ViewportOffset maxOffset;

  /// {@macro exprollable_page_view.controller.PageViewportMetrics.shrunkOffset}
  final ViewportOffset shrunkOffset;

  /// {@macro exprollable_page_view.controller.PageViewportMetrics.expandedOffset}
  final ViewportOffset expandedOffset;

  /// The initial viewport offset.
  final ViewportOffset initialOffset;

  /// The list of offsets that the viewport will snap to.
  ///
  /// The list must be sorted in ascending order by the actual offset value
  /// calculated from [ViewportOffset.toConcreteValue].
  final List<ViewportOffset> snapOffsets;
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
    required this.fractionBehavior,
    required this.configuration,
    required ScrollAbsorber absorber,
  }) : _absorber = absorber {
    _absorber.addListener(_invalidateState);
  }

  /// Describes how the [fraction] changes along with vertical scrolling.
  final ViewportFractionBehavior fractionBehavior;

  /// The configuration of the viewport.
  final ViewportConfiguration configuration;

  final ScrollAbsorber _absorber;

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
  double get maxOffset => configuration.maxOffset.toConcreteValue(this);

  @override
  double get minOffset => configuration.minOffset.toConcreteValue(this);

  double? _offset;

  @override
  double get offset {
    assert(hasDimensions);
    return _offset!;
  }

  @override
  double get minFraction => configuration.minFraction;

  @override
  double get maxFraction => configuration.maxFraction;

  double? _fraction;

  @override
  double get fraction {
    assert(hasDimensions);
    return _fraction!;
  }

  @override
  double get expandedOffset =>
      configuration.expandedOffset.toConcreteValue(this);

  @override
  double get shrunkOffset => configuration.shrunkOffset.toConcreteValue(this);

  double get _initialAbsorberPixels {
    final initialOffset = configuration.initialOffset.toConcreteValue(this);
    assert(initialOffset >= minOffset);
    return initialOffset - minOffset;
  }

  /// Correct the state of this object for the given [dimensions].
  /// This method should be called whenever the dimensions of the viewport changes in [ExprollablePageView.build].
  /// Therefore this method does not notify its listeners even if the state changes after recalculation.
  @internal
  void correctForNewDimensions(ViewportDimensions dimensions) {
    _dimensions = dimensions;

    assert(
      minOffset <= expandedOffset,
      "Invalid order of offset properties: "
      "minOffset <= expandedOffset must be satisfied, "
      "but minOffset is $minOffset and expandedOffset is $expandedOffset.",
    );
    assert(
      expandedOffset <= shrunkOffset,
      "Invalid order of offset properties: "
      "expandedOffset <= shrunkOffset must be satisfied, "
      "but expandedOffset is $expandedOffset and shrunkOffset is $shrunkOffset.",
    );
    assert(
      shrunkOffset <= maxOffset,
      "Invalid order of offset properties: "
      "shrunkOffset <= maxOffset must be satisfied, "
      "but shrunkOffset is $shrunkOffset and maxOffset is $maxOffset.",
    );

    _absorber.correct((it) {
      it.capacity = deltaOffset;
      if (it.pixels == null) {
        it.absorb(_initialAbsorberPixels);
      }
    });

    _correctState();
  }

  void _correctState() {
    assert(_absorber.pixels != null);
    assert(hasDimensions);
    final newOffset = minOffset + _absorber.pixels!;
    final dim = dimensions;
    final lowerBoundFraction =
        (dim.height - dim.padding.bottom - max(0.0, newOffset)) / dim.height;
    final preferredFraction =
        fractionBehavior.preferredFraction(this, newOffset);

    _fraction = max(lowerBoundFraction, preferredFraction);
    _offset = newOffset;
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

    assert((() {
      final snaps =
          snapOffsets.map((s) => s.toConcreteValue(viewport)).toList();
      return listEquals(snaps, [...snaps]..sort());
    })(), "'snapOffsets' must be sorted in ascending order.");

    final snapScrollOffsets =
        snapOffsets.map((s) => s.toScrollOffset(viewport)).toList();
    final minSnap = snapScrollOffsets.last;
    final maxSnap = snapScrollOffsets.first;
    if (position.pixels < minSnap || position.pixels > maxSnap) {
      return null;
    }

    final pixels = position.pixels;
    double nearest(double p, double q) =>
        (pixels - p).abs() < (pixels - q).abs() ? p : q;

    return snapScrollOffsets.reduce(nearest);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final snapTo = findScrollSnapPosition(position, velocity);
    if (snapTo == null) {
      return super.createBallisticSimulation(position, velocity);
    }
    return position.pixels.almostEqualTo(snapTo)
        ? null
        : ScrollSpringSimulation(
            spring,
            position.pixels,
            snapTo,
            velocity,
            tolerance: Tolerance.defaultTolerance,
          );
  }
}

/// An object that represents a viewport offset.
/// 
/// There are 3 predefined [ViewportOffset]s:
/// - [ViewportOffset.expanded] : The default offset at which the page viewport is fully expanded. 
/// - [ViewportOffset.shrunk] : The default offset at which the page viewport is fully shrunk. 
/// - [ViewportOffset.overshoot] : The default offset at which the page viewport is fully expanded and overshot.
/// 
/// User defined offsets can be created using [ViewportOffset.fixed] and [ViewportOffset.fractional],
/// or extend [ViewportOffset] to perform more complex calculations.
abstract class ViewportOffset {
  /// {@macro exprollable_page_view.controller.DefaultExpandedViewportOffset}
  static const expanded = DefaultExpandedViewportOffset();

  /// {@macro exprollable_page_view.controller.DefaultShrunkViewportOffset}
  static const shrunk = DefaultShrunkViewportOffset();

  /// {@macro exprollable_page_view.controller.OvershootViewportOffset}
  static const overshoot = OvershootViewportOffset();

  /// {@macro exprollable_page_view.controller.FractionalViewportOffset.new}
  const factory ViewportOffset.fractional(double fraction) =
      FractionalViewportOffset;

  /// {@macro exprollable_page_view.controller.FixedViewportOffset.new}
  const factory ViewportOffset.fixed(double pixels) = FixedViewportOffset;

  /// Contructs a [ViewportOffset].
  const ViewportOffset();

  /// Calculate the concrete pixels represented by this object
  /// from the current viewport dimensions.
  double toConcreteValue(PageViewportMetrics metrics);

  /// Convert the offset to a scroll offset for [ScrollPosition].
  @nonVirtual
  double toScrollOffset(PageViewportMetrics metrics) {
    final offset = toConcreteValue(metrics);
    assert(offset >= metrics.minOffset);
    return -1 * (offset - metrics.minOffset);
  }
}

/// {@template exprollable_page_view.controller.OvershootViewportOffset}
/// The default offset at which the viewport will be fully expanded and overshot.
/// {@endtemplate}
class OvershootViewportOffset extends ViewportOffset {
  /// Create the overshot viewport offset.
  const OvershootViewportOffset();

  @override
  double toConcreteValue(PageViewportMetrics metrics) =>
      -1 * metrics.dimensions.padding.bottom;
}

/// {@template exprollable_page_view.controller.DefaultExpandedViewportOffset}
/// The default offset at which the viewport is fully expanded.
///
/// The offset value is always 0.0.
/// {@endtemplate}
class DefaultExpandedViewportOffset extends ViewportOffset {
  /// Create the default expanded viewport offset.
  const DefaultExpandedViewportOffset();

  @override
  double toConcreteValue(PageViewportMetrics metrics) => 0.0;
}

/// {@template exprollable_page_view.controller.DefaultShrunkViewportOffset}
/// The default offset at which the viewport will be fully shrunk.
///
/// The preferred offset value is the top padding plus 16.0 pixels,
/// but if it is less than the lower limit, it will be clamped to that value.
/// The lower limit is calculated by subtracting the height of the shrunk page
/// from the height of the viewport. This clamping process is necessary to prevent
/// unwanted white space between the bottom of the page and the viewport.
/// {@endtemplate}
class DefaultShrunkViewportOffset extends ViewportOffset {
  /// Create the default shrunk viewport offset.
  const DefaultShrunkViewportOffset();

  @override
  double toConcreteValue(PageViewportMetrics metrics) {
    assert(metrics.hasDimensions);
    const margin = 16.0;
    final preferredOffset = metrics.dimensions.padding.top + margin;
    final lowerBoundOffset =
        (1.0 - metrics.minFraction) * metrics.dimensions.height;
    return max(preferredOffset, lowerBoundOffset);
  }
}

/// A viewport offset that is defined by a fractional value.
class FractionalViewportOffset extends ViewportOffset {
  /// {@template exprollable_page_view.controller.FractionalViewportOffset.new}
  /// Creates a viewport offset from a fractional value.
  ///
  /// [fraction] is a relative value of the viewport height substracted
  /// by the bottom padding and must be between 0.0 and 1.0.
  /// {@endtemplate}
  const FractionalViewportOffset(this.fraction)
      : assert(0.0 <= fraction && fraction <= 1.0);

  /// The fractional value of the offset.
  final double fraction;

  @override
  double toConcreteValue(PageViewportMetrics metrics) =>
      fraction *
      (metrics.dimensions.height - metrics.dimensions.padding.bottom);
}

/// A viewport offset that is defined by a fixed value.
class FixedViewportOffset extends ViewportOffset {
  /// {@template exprollable_page_view.controller.FixedViewportOffset.new}
  /// Creates a viewport offset from a fixed value.
  /// {@endtemplate}
  const FixedViewportOffset(this.pixels);

  /// The fixed value of the offset in terms of logical pixels.
  final double pixels;

  @override
  double toConcreteValue(PageViewportMetrics metrics) => pixels;
}
