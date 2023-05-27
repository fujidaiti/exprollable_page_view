import 'dart:math';

import 'package:exprollable_page_view/src/internal/scroll.dart';
import 'package:exprollable_page_view/src/internal/utils.dart';
import 'package:exprollable_page_view/src/core/view.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Viewport;
import 'package:meta/meta.dart';

/// An inherited widget used in [ExprollablePageView] to provides
/// its [ExprollablePageController] to its descendants.
///
/// [ExprollablePageController.of] is a convenience method that obtains
/// the controller sotred in this inherited widget.
@internal
class InheritedExprollablePageController extends InheritedWidget {
  const InheritedExprollablePageController({
    super.key,
    required super.child,
    required this.controller,
  });

  /// A controller to be provided to the descendants.
  final ExprollablePageController controller;

  @override
  bool updateShouldNotify(InheritedExprollablePageController oldWidget) =>
      !identical(controller, oldWidget.controller);
}

/// An inherited widget that provides a [PageViewport] to its descendants.
@internal
class InheritedPageViewport extends InheritedWidget {
  const InheritedPageViewport({
    super.key,
    required super.child,
    required this.pageView,
  });

  /// A page viewport to be provided to the descendants.
  final PageViewport pageView;

  @override
  bool updateShouldNotify(InheritedPageViewport oldWidget) =>
      !identical(pageView, oldWidget.pageView);
}

/// An inherited widget that provides a [PageContentScrollController] to its descendants.
@internal
class InheritedPageContentScrollController extends InheritedWidget {
  const InheritedPageContentScrollController({
    super.key,
    required super.child,
    required this.controller,
  });

  /// A scroll controller to be provided to the descendants.
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
/// This controller lets you manipulate which page is visible in a [ExprollablePageView].
/// It also can be used to programmatically change the viewport state.
class ExprollablePageController extends PageController {
  /// Create a page controller.
  ///
  /// Specifying [viewportFractionBehavior] allows you to control how the viewport fraction changes
  /// along with vertical scrolling. [DefaultViewportFractionBehavior] is used by default.
  ///
  /// To configure the properties of the viewport, specify [viewportConfiguration] with the desired values.
  /// [ViewportConfiguration.defaultConfiguration] is used as the default configuration.
  ExprollablePageController({
    super.initialPage,
    super.keepPage,
    ViewportConfiguration viewportConfiguration =
        ViewportConfiguration.defaultConfiguration,
    ViewportFractionBehavior viewportFractionBehavior =
        const DefaultViewportFractionBehavior(),
  }) : super(viewportFraction: viewportConfiguration.minFraction) {
    viewport = Viewport(
      absorber: _absorberGroup,
      fractionBehavior: viewportFractionBehavior,
      configuration: viewportConfiguration,
    );
    _snapPhysics = _SnapViewportInsetPhysics(
      snapInsets: viewportConfiguration.snapInsets,
      viewport: viewport,
    );
    _currentPage = _CurrentPageNotifier(controller: this);
  }

  final _absorberGroup = ScrollAbsorberGroup();
  final Map<int, PageContentScrollController> _contentScrollControllers = {};

  late final _SnapViewportInsetPhysics _snapPhysics;

  /// A notifier that stores the index of the current active page.
  ///
  /// The new index is notified whenever the page that fully occupies the viewport changes.
  /// The initial value is [ExprollablePageController.initialPage].
  ValueListenable<int> get currentPage => _currentPage;
  late final _CurrentPageNotifier _currentPage;

  /// An object that stores the viewport state.
  ///
  /// You can subscribe this object to get notified when the viewport state changes.
  late final Viewport viewport;

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

  /// Animates the viewport inset of the controlled [ExprollablePageView]
  /// from the current inset to the given inset.
  Future<void> animateViewportInsetTo(
    ViewportInset inset, {
    required Curve curve,
    required Duration duration,
  }) {
    return _contentScrollController.animateTo(
      inset.toScrollOffset(viewport),
      curve: curve,
      duration: duration,
    );
  }

  /// instantly changes the current viewport inset of
  /// the controlled [ExprollablePageView] without animation.
  void jumpViewportInsetTo(ViewportInset inset) {
    _contentScrollController.jumpTo(inset.toScrollOffset(viewport));
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

  /// Construct a description of the viewport mesurements.
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

/// A description of the page viewport mesurements.
@immutable
class PageViewportDimensions {
  const PageViewportDimensions({
    required this.minWidth,
    required this.minHeight,
    required this.maxWidth,
    required this.maxHeight,
  });

  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (runtimeType == other.runtimeType &&
          other is PageViewportDimensions &&
          minWidth == other.minWidth &&
          maxWidth == other.maxWidth &&
          minHeight == other.minHeight &&
          maxHeight == other.maxHeight);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        minWidth,
        maxWidth,
        minHeight,
        maxHeight,
      );
}

/// A description of the viewport state.
///
/// {@template exprollable_page_view.controller.ViewportMetrics}
/// The state of the viewport is described by the 2 mesurements: fraction and inset.
/// The fraction indicates how much space each page should occupy in the viewport,
/// and the inset is the distance from the top of the viewport to the top of the current page viewport.
/// {@endtemplate}
mixin ViewportMetrics {
  /// The mesurements of the viewport.
  ///
  /// Available only if [hasDimensions] is true.
  ViewportDimensions get dimensions;

  /// Indicates if [dimensions] property is available.
  bool get hasDimensions;

  /// The fraction of the viewport that the each page should occupy.
  ///
  /// [fraction] must be between [minFraction] and [maxFraction] including both edges.
  double get fraction;

  /// {@template exprollable_page_view.controller.ViewportMetrics.minFraction}
  /// The lower bound of [fraction].
  /// {@endtemplate}
  double get minFraction;

  /// {@template exprollable_page_view.controller.ViewportMetrics.maxFraction}
  /// The upper bound of [fraction].
  /// {@endtemplate}
  double get maxFraction;

  /// The distance from the top of the viewport to the top of the current page vieewport.
  ///
  /// [inset] is always greater than or equals to [minInset], but might exceeds [maxInset].
  /// For example, if a scrollable widget in the current page uses [BouncingScrollPhysics]
  /// as its scroll physics and a user tries to overscroll the page,
  /// [inset] will exceeds [maxInset] according to the physics.
  double get inset;

  /// {@template exprollable_page_view.controller.ViewportMetrics.minInset}
  /// The lower bound of the inset.
  /// {@endtemplate}
  double get minInset;

  /// {@template exprollable_page_view.controller.ViewportMetrics.maxInset}
  /// The upper bound of the inset.
  ///
  /// In certain cases, the [inset] might exceeds this value,
  /// but it will eventually settle to this value.
  /// {@endtemplate}
  double get maxInset;

  /// Calculate the difference between [minInset] and [maxInset].
  ///
  /// Always returns zero or a positive value.
  double get deltaInset {
    assert(minInset <= maxInset);
    return maxInset - minInset;
  }

  /// Calculate the difference between [minFraction] and [maxInset].
  ///
  /// Always returns zero or a positive value.
  double get deltaFraction {
    assert(minFraction <= maxFraction);
    return maxFraction - minFraction;
  }

  /// {@template exprollable_page_view.controller.ViewportMetrics.shrunkInset}
  /// The lower bound of the [inset] at which the current page viewport is fully shrunk.
  /// {@endtemplate}
  double get shrunkInset;

  /// {@template exprollable_page_view.controller.ViewportMetrics.expandedInset}
  /// The upper bound of the [inset] at which the current page viewport is fully expanded.
  /// {@endtemplate}
  double get expandedInset;

  /// Indicates if the current page viewport is fully shrunk.
  bool get isPageShrunk =>
      fraction.almostEqualTo(minFraction) || fraction < minFraction;

  /// Indicates if the current page viewport is fully expanded.
  bool get isPageExpanded =>
      fraction.almostEqualTo(maxFraction) || fraction > maxFraction;

  /// The measurements of the current page viewport.
  ///
  /// Only available if [hasDimensions] is true.
  PageViewportDimensions get pageDimensions;
}

/// A snapshot of the viewport state.
@immutable
class StaticViewportMetrics with ViewportMetrics {
  /// Create a snapshot of the viewport state.
  const StaticViewportMetrics({
    required this.fraction,
    required this.minFraction,
    required this.maxFraction,
    required this.inset,
    required this.minInset,
    required this.maxInset,
    required this.shrunkInset,
    required this.expandedInset,
    required this.dimensions,
    required this.pageDimensions,
  });

  /// Create a [StaticViewportMetrics] copying another [ViewportMetrics].
  factory StaticViewportMetrics.from(
    ViewportMetrics metrics,
  ) =>
      StaticViewportMetrics(
        fraction: metrics.fraction,
        minFraction: metrics.minFraction,
        maxFraction: metrics.maxFraction,
        inset: metrics.inset,
        minInset: metrics.minInset,
        maxInset: metrics.maxInset,
        shrunkInset: metrics.shrunkInset,
        expandedInset: metrics.expandedInset,
        dimensions: metrics.dimensions,
        pageDimensions: metrics.pageDimensions,
      );

  @override
  final double fraction;

  @override
  final double minFraction;

  @override
  final double maxFraction;

  @override
  final double inset;

  @override
  final double minInset;

  @override
  final double maxInset;

  @override
  final double shrunkInset;

  @override
  final double expandedInset;

  @override
  final ViewportDimensions dimensions;

  @override
  final PageViewportDimensions pageDimensions;

  @override
  bool get hasDimensions => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaticViewportMetrics &&
          runtimeType == other.runtimeType &&
          fraction == other.fraction &&
          minFraction == other.minFraction &&
          maxFraction == other.maxFraction &&
          inset == other.inset &&
          minInset == other.minInset &&
          maxInset == other.maxInset &&
          shrunkInset == other.shrunkInset &&
          expandedInset == other.expandedInset &&
          dimensions == other.dimensions &&
          pageDimensions == other.pageDimensions);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        fraction,
        minFraction,
        maxFraction,
        inset,
        minInset,
        maxInset,
        shrunkInset,
        expandedInset,
        dimensions,
        pageDimensions,
      );
}

/// A notification that bubbles up the widget tree from a [ExprollablePageView] whenever the viewport state changes.
///
/// Listening for this notification is equivalent to observe [ExprollablePageController.viewport].
class ViewportUpdateNotification extends Notification {
  const ViewportUpdateNotification(this.metrics);
  final ViewportMetrics metrics;
}

/// Describes how the viewport fraction changes when the current page is scrolled vertically.
///
/// Use the convenient [DefaultViewportFractionBehavior] which implements the default behavior,
/// or extend this class and override [preferredFraction] to create your own behavior.
abstract class ViewportFractionBehavior {
  /// Calculate a viewport fraction according to the current viewport state and the new inset.
  ///
  /// This method is called by [Viewport] whenever the [Viewport.fraction] should be updated.
  /// The calculated fraction must be [ViewportMetrics.minFraction]
  /// when [ViewportMetrics.inset] is greater than or equal to [ViewportMetrics.shrunkInset],
  /// and must be [ViewportMetrics.maxFraction] when [ViewportMetrics.inset] is less than or equal to [ViewportMetrics.expandedInset].
  /// There's no restriction in the other cases, but it will usually took a value
  /// between [ViewportMetrics.minFraction] and [ViewportMetrics.maxFraction].
  double preferredFraction(ViewportMetrics viewport, double newInset);
}

/// The default implementation of [ViewportFractionBehavior].
///
/// The calculated viewport fractions take values between [ViewportMetrics.minFraction]
/// and [ViewportMetrics.maxFraction], along the [curve].
class DefaultViewportFractionBehavior implements ViewportFractionBehavior {
  /// Create the default implementation of [ViewportFractionBehavior].
  const DefaultViewportFractionBehavior({this.curve = Curves.easeIn});

  /// The curve of the viewport fraction.
  final Curve curve;

  @override
  double preferredFraction(ViewportMetrics viewport, double newInset) {
    assert(viewport.hasDimensions);
    final pixels = newInset - viewport.expandedInset;
    final delta = viewport.shrunkInset - viewport.expandedInset;
    assert(delta > 0.0);
    final t = 1.0 - (pixels / delta).clamp(0.0, 1.0);
    return curve.transform(t) * viewport.deltaFraction + viewport.minFraction;
  }
}

/// A configuration for the viewport.
class ViewportConfiguration {
  /// A const object to be used as the default configuration of [Viewport].
  static const defaultConfiguration = ViewportConfiguration.raw();

  /// A general constructor for [ViewportConfiguration].
  ///
  /// It is recommended to use [ViewportConfiguration.new],
  /// which is a convenient constructor sufficient for most use cases.
  const ViewportConfiguration.raw({
    this.extendPage = false,
    this.minFraction = 0.9,
    this.maxFraction = 1.0,
    this.minInset = ViewportInset.expanded,
    this.maxInset = ViewportInset.shrunk,
    this.shrunkInset = ViewportInset.shrunk,
    this.expandedInset = ViewportInset.expanded,
    this.initialInset = ViewportInset.shrunk,
    this.snapInsets = const [
      ViewportInset.expanded,
      ViewportInset.shrunk,
    ],
  });

  /// Create a configuration for standard use cases.
  ///
  /// If [extraSnapInsets] is not empty, viewport will snap to the insets
  /// given by [extraSnapInsets] in addition to [ViewportInset.expanded] and [ViewportInset.shrunk].
  /// The list must be sorted in ascending order by the actual inset value
  /// calculated from [ViewportInset.toConcreteValue].
  ///
  /// If [initialInset] is not specified, the last element in [extraSnapInsets]
  /// is used as the initial inset. If [extraSnapInsets] is also not specified,
  /// [initialInset] is set to [shrunkInset].
  ///
  /// If [overshootEffect] is enabled, the upper segment of the current page viewport will
  /// slightly exceed the top of the viewport when it goes fullscreen.
  /// To be precise, this means that [inset] will take a negative value
  /// when the viewport fraction is [maxFraction]. This trick creates a dynamic visual effect
  /// when the page goes fullscreen. The figures below are demonstrations of
  /// how the overshoot effect affects (disabled in the left, enabled in the right).
  ///
  /// ![overshoot-disabled](https://user-images.githubusercontent.com/68946713/231827343-155a750d-b21f-4a96-b81a-74c8873c46cb.gif) ![overshoot-enabled](https://user-images.githubusercontent.com/68946713/231827364-40843efc-5a91-49ff-ab74-c9af1e4b0c62.gif)
  ///
  factory ViewportConfiguration({
    bool overshootEffect = false,
    bool extendPage = false,
    double minFraction = 0.9,
    double maxFraction = 1.0,
    ViewportInset shrunkInset = ViewportInset.shrunk,
    ViewportInset? initialInset,
    List<ViewportInset> extraSnapInsets = const [],
  }) {
    final expandedInset =
        overshootEffect ? ViewportInset.overshoot : ViewportInset.expanded;
    final snapInsets = [
      expandedInset,
      shrunkInset,
      ...extraSnapInsets,
    ];
    return ViewportConfiguration.raw(
      minFraction: minFraction,
      maxFraction: maxFraction,
      minInset: expandedInset,
      maxInset: snapInsets.last,
      shrunkInset: shrunkInset,
      expandedInset: expandedInset,
      initialInset: initialInset ?? snapInsets.last,
      snapInsets: snapInsets,
      extendPage: extendPage,
    );
  }

  /// {@macro exprollable_page_view.controller.ViewportMetrics.minFraction}
  final double minFraction;

  /// {@macro exprollable_page_view.controller.ViewportMetrics.maxFraction}
  final double maxFraction;

  /// {@macro exprollable_page_view.controller.ViewportMetrics.minInset}
  final ViewportInset minInset;

  /// {@macro exprollable_page_view.controller.ViewportMetrics.maxInset}
  final ViewportInset maxInset;

  /// {@macro exprollable_page_view.controller.ViewportMetrics.shrunkInset}
  final ViewportInset shrunkInset;

  /// {@macro exprollable_page_view.controller.ViewportMetrics.expandedInset}
  final ViewportInset expandedInset;

  /// The initial viewport inset.
  final ViewportInset initialInset;

  /// The list of insets that the viewport will snap to.
  ///
  /// The list must be sorted in ascending order by the actual inset value
  /// calculated from [ViewportInset.toConcreteValue].
  final List<ViewportInset> snapInsets;

  /// If true, the page extends to the bottom of the viewport when it fully expanded,
  /// even if the viewport has non-zero bottom padding.
  final bool extendPage;
}

/// An object that represents the state of the viewport.
///
/// {@macro exprollable_page_view.controller.ViewportMetrics}
///
/// This object subscribes to the given [ScrollAbsorber] to calculates the [inset] and [fraction]
/// depending on [ScrollAbsorber.pixels], and if there are any changes, notifies its listeners.
class Viewport extends ChangeNotifier
    with ViewportMetrics
    implements ValueListenable<ViewportMetrics> {
  /// Creates an object that represents the state of the **conceptual** viewport.
  Viewport({
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
  ViewportMetrics get value => this;

  ViewportDimensions? _dimensions;

  @override
  ViewportDimensions get dimensions {
    assert(hasDimensions);
    return _dimensions!;
  }

  @override
  bool get hasDimensions => _dimensions != null;

  @override
  double get maxInset => configuration.maxInset.toConcreteValue(this);

  @override
  double get minInset => configuration.minInset.toConcreteValue(this);

  double? _inset;

  @override
  double get inset {
    assert(hasDimensions);
    return _inset!;
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
  double get expandedInset => configuration.expandedInset.toConcreteValue(this);

  @override
  double get shrunkInset => configuration.shrunkInset.toConcreteValue(this);

  @override
  PageViewportDimensions get pageDimensions {
    assert(hasDimensions);
    final baseHeight = configuration.extendPage
        ? dimensions.height - minInset
        : dimensions.height - minInset - dimensions.padding.bottom;
    assert(baseHeight > 0);
    return PageViewportDimensions(
      minWidth: dimensions.width * minFraction,
      maxWidth: dimensions.width * maxFraction,
      minHeight: baseHeight * minFraction,
      maxHeight: baseHeight * maxFraction,
    );
  }

  double get _initialAbsorberPixels {
    final initialInset = configuration.initialInset.toConcreteValue(this);
    assert(initialInset >= minInset);
    return initialInset - minInset;
  }

  /// Correct the state of this object for the given [dimensions].
  ///
  /// This method should be called whenever the dimensions of the viewport changes in [ExprollablePageView.build].
  /// Therefore this method does not notify its listeners even if the state changes after recalculation.
  @internal
  void correctForNewDimensions(ViewportDimensions dimensions) {
    _dimensions = dimensions;

    assert(
      minInset <= expandedInset,
      "Invalid order of inset properties: "
      "minInset <= expandedInset must be satisfied, "
      "but minInset is $minInset and expandedInset is $expandedInset.",
    );
    assert(
      expandedInset <= shrunkInset,
      "Invalid order of inset properties: "
      "expandedInset <= shrunkInset must be satisfied, "
      "but expandedInset is $expandedInset and shrunkInset is $shrunkInset.",
    );
    assert(
      shrunkInset <= maxInset,
      "Invalid order of inset properties: "
      "shrunkInset <= maxInset must be satisfied, "
      "but shrunkInset is $shrunkInset and maxInset is $maxInset.",
    );

    _absorber.correct((it) {
      it.capacity = deltaInset;
      if (it.pixels == null) {
        it.absorb(_initialAbsorberPixels);
      }
    });

    _correctState();
  }

  void _correctState() {
    assert(_absorber.pixels != null);
    assert(hasDimensions);
    final newInset = minInset + _absorber.pixels!;
    final preferredFraction =
        fractionBehavior.preferredFraction(this, newInset);
    final lowerBoundPageHeight = configuration.extendPage
        ? dimensions.height - dimensions.padding.bottom - max(0.0, newInset)
        : dimensions.height - max(0.0, newInset);
    final lowerBoundFraction = lowerBoundPageHeight / pageDimensions.maxHeight;
    _fraction = max(lowerBoundFraction, preferredFraction);
    _inset = newInset;
  }

  void _invalidateState() {
    final oldInset = inset;
    final oldFraction = fraction;
    _correctState();
    if (!oldFraction.almostEqualTo(fraction) ||
        !oldInset.almostEqualTo(inset)) {
      notifyListeners();
    }
  }
}

/// An object that sotres the page viewport state for a specific page.
class PageViewport extends ChangeNotifier {
  PageViewport({
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

  /// The page corresponding to this page viewport.
  final int page;

  final ExprollablePageController _pageController;

  late Offset _translation = _computeTranslation();
  late double _fraction = _computeFraction();

  /// How many pixels the page should translate from the actual position in the page view.
  Offset get translation => _translation;

  /// The fraction of the viewport that the page should occupy.
  double get fraction => _fraction;

  /// The lower bound of [fraction].
  double get minFraction => _pageController.viewport.minFraction;

  /// The upper bound of [fraction].
  double get maxFraction => _pageController.viewport.maxFraction;

  /// The distance from the top of the viewport to the top of this page viewport.
  ///
  /// This value will be equal to [Viewport.inset] if [page] is the current page.
  double get offset => _isPageActive
      ? _pageController.viewport.inset
      : max(0.0, _pageController.viewport.inset) + translation.dy;

  /// The lower bound of [offset].
  double get minOffset => _isPageActive
      ? _pageController.viewport.minInset
      : _pageController.viewport.dimensions.padding.top;

  /// The upper bound of [offset].
  double get maxOffset => _pageController.viewport.inset;

  bool get _isPageActive => page == _pageController.currentPage.value;

  Offset _computeTranslation() => Offset(
        _computeHorizontalTranslation(),
        _computeVerticalTranslation(),
      );

  double _computeVerticalTranslation() {
    final vp = _pageController.viewport;
    if (_isPageActive) {
      return min(vp.inset, 0.0);
    } else {
      return (vp.dimensions.padding.top - vp.inset)
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

  /// Obtains the [PageViewport] attached to the page that is the nearest ancestor from [context].
  static PageViewport? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<InheritedPageViewport>()
      ?.pageView;
}

/// A [ScrollController] that must be attached to a [Scrollable] widget in each page.
///
/// Since [Viewport] subscribes to [PageContentScrollController.absorber]
/// to calculate the viewport state according to the scroll position,
/// it is important that the [PageContentScrollController] obtained from
/// [PageContentScrollController.of] is attached to a [Scrollable] widget in each page.
class PageContentScrollController extends AbsorbScrollController {
  PageContentScrollController._(
      {required _SnapViewportInsetPhysics? snapPhysics})
      : _snapPhysics = snapPhysics;

  final _SnapViewportInsetPhysics? _snapPhysics;

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

  /// Obtains the [PageContentScrollController] for the page that is the nearest ancestor from [context].
  static PageContentScrollController? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<
          InheritedPageContentScrollController>()
      ?.controller;
}

class _SnapViewportInsetPhysics extends ScrollPhysics {
  // ignore: prefer_const_constructors_in_immutables
  _SnapViewportInsetPhysics({
    super.parent,
    required this.snapInsets,
    required this.viewport,
  });

  final List<ViewportInset> snapInsets;
  final Viewport viewport;

  @override
  ScrollPhysics applyTo(ScrollPhysics? ancestor) => _SnapViewportInsetPhysics(
        parent: buildParent(ancestor),
        snapInsets: snapInsets,
        viewport: viewport,
      );

  double? findScrollSnapPosition(ScrollMetrics position, double velocity) {
    // TODO; Find more appropriate threshold
    const thresholdVelocity = 2000;
    if (velocity.abs() > thresholdVelocity) return null;
    if (snapInsets.isEmpty) return null;

    assert((() {
      final snaps = snapInsets.map((s) => s.toConcreteValue(viewport)).toList();
      return listEquals(snaps, [...snaps]..sort());
    })(), "'snapInsets' must be sorted in ascending order.");

    final snapScrollInsets =
        snapInsets.map((s) => s.toScrollOffset(viewport)).toList();
    final minSnap = snapScrollInsets.last;
    final maxSnap = snapScrollInsets.first;
    if (position.pixels < minSnap || position.pixels > maxSnap) {
      return null;
    }

    final pixels = position.pixels;
    double nearest(double p, double q) =>
        (pixels - p).abs() < (pixels - q).abs() ? p : q;

    return snapScrollInsets.reduce(nearest);
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

/// An object that represents a viewport inset.
///
/// There are 3 predefined [ViewportInset]s:
/// - [ViewportInset.expanded] : The default inset at which the current page is fully expanded.
/// - [ViewportInset.shrunk] : The default inset at which the current page is fully shrunk.
/// - [ViewportInset.overshoot] : The default inset at which the current page is fully expanded and overshot.
///
/// User defined insets can be created using [ViewportInset.fixed] and [ViewportInset.fractional],
/// or extend [ViewportInset] to perform more complex calculations.
abstract class ViewportInset {
  /// {@macro exprollable_page_view.controller.DefaultExpandedViewportInset}
  static const expanded = DefaultExpandedViewportInset();

  /// {@macro exprollable_page_view.controller.DefaultShrunkViewportInset}
  static const shrunk = DefaultShrunkViewportInset();

  /// {@macro exprollable_page_view.controller.OvershootViewportInset}
  static const overshoot = OvershootViewportInset();

  /// {@macro exprollable_page_view.controller.FractionalViewportInset.new}
  const factory ViewportInset.fractional(double fraction) =
      FractionalViewportInset;

  /// {@macro exprollable_page_view.controller.FixedViewportInset.new}
  const factory ViewportInset.fixed(double pixels) = FixedViewportInset;

  /// Contructs a [ViewportInset].
  const ViewportInset();

  /// Calculate the concrete pixels represented by this object
  /// from the current viewport dimensions.
  double toConcreteValue(ViewportMetrics metrics);

  /// Convert the inset to a scroll offset for [ScrollPosition].
  @nonVirtual
  double toScrollOffset(ViewportMetrics metrics) {
    final offset = toConcreteValue(metrics);
    assert(offset >= metrics.minInset);
    return -1 * (offset - metrics.minInset);
  }
}

/// {@template exprollable_page_view.controller.OvershootViewportInset}
/// The default inset at which the current page will be fully expanded and overshot.
/// {@endtemplate}
class OvershootViewportInset extends ViewportInset {
  /// Create the overshot viewport inset.
  const OvershootViewportInset();

  static const _defaultPixels = -82.0;

  @override
  double toConcreteValue(ViewportMetrics metrics) =>
      min(-1 * metrics.dimensions.padding.bottom, _defaultPixels);
}

/// {@template exprollable_page_view.controller.DefaultExpandedViewportInset}
/// The default inset at which the current page is fully expanded.
///
/// The inset value is always 0.0.
/// {@endtemplate}
class DefaultExpandedViewportInset extends ViewportInset {
  /// Create the default expanded viewport inset.
  const DefaultExpandedViewportInset();

  @override
  double toConcreteValue(ViewportMetrics metrics) => 0.0;
}

/// {@template exprollable_page_view.controller.DefaultShrunkViewportInset}
/// The default inset at which the current page will be fully shrunk.
///
/// The preferred inset value is the top padding plus 16.0 pixels,
/// but if it is less than the lower limit, it will be clamped to that value.
/// The lower limit is calculated by subtracting the height of the shrunk page
/// from the height of the viewport. This clamping process is necessary to prevent
/// unwanted white space between the bottom of the page and the viewport.
/// {@endtemplate}
class DefaultShrunkViewportInset extends ViewportInset {
  /// Create the default shrunk viewport inset.
  const DefaultShrunkViewportInset();

  @override
  double toConcreteValue(ViewportMetrics metrics) {
    assert(metrics.hasDimensions);
    const margin = 16.0;
    final preferredInset = metrics.dimensions.padding.top + margin;
    final lowerBoundInset =
        metrics.dimensions.height - metrics.pageDimensions.minHeight;
    return max(preferredInset, lowerBoundInset);
  }
}

/// A viewport inset that is defined by a fractional value.
class FractionalViewportInset extends ViewportInset {
  /// {@template exprollable_page_view.controller.FractionalViewportInset.new}
  /// Creates a viewport inset from a fractional value.
  ///
  /// [fraction] is a relative value of the viewport height substracted
  /// by the bottom padding and must be between 0.0 and 1.0.
  /// {@endtemplate}
  const FractionalViewportInset(this.fraction)
      : assert(0.0 <= fraction && fraction <= 1.0);

  /// The fractional value of the inset.
  final double fraction;

  @override
  double toConcreteValue(ViewportMetrics metrics) =>
      fraction *
      (metrics.dimensions.height - metrics.dimensions.padding.bottom);
}

/// A viewport inset that is defined by a fixed value.
class FixedViewportInset extends ViewportInset {
  /// {@template exprollable_page_view.controller.FixedViewportInset.new}
  /// Creates a viewport inset from a fixed value.
  /// {@endtemplate}
  const FixedViewportInset(this.pixels);

  /// The fixed value of the inset in terms of logical pixels.
  final double pixels;

  @override
  double toConcreteValue(ViewportMetrics metrics) => pixels;
}
