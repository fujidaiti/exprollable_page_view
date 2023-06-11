import 'dart:math';
import 'dart:ui';

import 'package:exprollable_page_view/src/core/controller.dart';
import 'package:exprollable_page_view/src/core/view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Viewport;

// TODO: Deprecate this
//
/// Shows an [ExprollablePageView] as a modal dialog.
Future<T?> showModalExprollable<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Color darkestBarrierColor = Colors.black54,
  Color lightestBarrierColor = Colors.black26,
  Color initialBarrierColor = Colors.black54,
  void Function(BuildContext) dismissBehavior = _defaultDismissBehavior,
  bool barrierDismissible = true,
  ViewportInset dismissThresholdInset = const DismissThresholdInset(),
}) =>
    showDialog<T>(
      context: context,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: ModalExprollable(
          builder: builder,
          darkestBarrierColor: darkestBarrierColor,
          lightestBarrierColor: lightestBarrierColor,
          initialBarrierColor: initialBarrierColor,
          dismissBehavior: dismissBehavior,
          barrierDismissible: barrierDismissible,
          dismissThresholdInset: dismissThresholdInset,
        ),
      ),
    );

void _defaultDismissBehavior(BuildContext context) =>
    Navigator.of(context).pop();

class DismissThresholdInset extends ViewportInset {
  const DismissThresholdInset({
    this.dragMargin = 86.0,
  });

  final double dragMargin;

  @override
  double toConcreteValue(ViewportMetrics metrics) =>
      metrics.shrunkInset + dragMargin;
}

// TODO: Deprecate this
//
/// A widget that makes a modal dialog style [ExprollablePageView].
///
/// This widget adds a translucent background (barrier) and
/// *swipe down to dismiss* action to the decendant page view.
/// Use [showModalExprollable] as a convenience method
/// to show the [ExprollablePageView] as a dialog,
/// which wraps the page view with [ModalExprollable].
/// If you want to customize reveal/dismiss behavior of the dialog,
/// create your own [PageRoute] and use [ModalExprollable] in it.
class ModalExprollable extends StatefulWidget {
  /// Creates a modal dialog style [ExprollablePageView].
  const ModalExprollable({
    super.key,
    required this.builder,
    this.darkestBarrierColor = Colors.black54,
    this.lightestBarrierColor = Colors.black26,
    this.initialBarrierColor = Colors.black54,
    this.dismissBehavior = _defaultDismissBehavior,
    this.barrierDismissible = true,
    this.dismissThresholdInset = const DismissThresholdInset(),
  });

  /// Called when the dialog should be dismissed.
  ///
  /// The default behavior is to pop the dialog
  /// by calling [Navigator.pop] without result value.
  final void Function(BuildContext) dismissBehavior;

  /// The threshold inset used to trigger *swipe down to dismiss* action.
  ///
  /// When the [Viewport.inset] exceeds this threshold,
  /// [dismissBehavior] is called to dismiss the dialog.
  final ViewportInset dismissThresholdInset;

  /// Whether the dialog is dismissible by tapping the barrier.
  final bool barrierDismissible;

  /// The darkest color of the barrier.
  final Color darkestBarrierColor;

  /// The lightest color of the barrier.
  final Color lightestBarrierColor;

  /// The initial color of the barrier.
  final Color initialBarrierColor;

  /// The builder of the child page view.
  final WidgetBuilder builder;

  @override
  State<StatefulWidget> createState() => _ModalExprollableState();
}

class _ModalExprollableState extends State<ModalExprollable> {
  final ValueNotifier<double?> barrierColorFraction = ValueNotifier(null);
  ViewportMetrics? lastViewportMetrics;

  @override
  void dispose() {
    super.dispose();
    barrierColorFraction.dispose();
  }

  void onViewportChanged(ViewportMetrics metrics) {
    lastViewportMetrics = metrics;
    invalidateBarrierColorFraction();
  }

  void onPointerUp() {
    if (shouldDismiss()) {
      widget.dismissBehavior(context);
    }
  }

  bool shouldDismiss() {
    if (lastViewportMetrics != null && lastViewportMetrics!.hasDimensions) {
      final vp = lastViewportMetrics!;
      final threshold = widget.dismissThresholdInset.toConcreteValue(vp);
      if (vp.inset > threshold) return true;
    }
    return false;
  }

  void onBarrierTapped() {
    if (widget.barrierDismissible) {
      widget.dismissBehavior(context);
    }
  }

  void invalidateBarrierColorFraction() {
    assert(lastViewportMetrics != null);
    assert(lastViewportMetrics!.hasDimensions);
    final vp = lastViewportMetrics!;
    final dismissThresholdInset =
        widget.dismissThresholdInset.toConcreteValue(vp);
    assert(dismissThresholdInset > vp.shrunkInset);
    final maxOverscroll = dismissThresholdInset - vp.shrunkInset;
    final overscroll = max(0.0, vp.inset - vp.maxInset);
    barrierColorFraction.value = (overscroll / maxOverscroll).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final barrier = GestureDetector(
      onTap: onBarrierTapped,
      child: ValueListenableBuilder(
        valueListenable: barrierColorFraction,
        builder: (_, fraction, __) {
          return ColoredBox(
            color: fraction != null
                ? Color.lerp(
                    widget.darkestBarrierColor,
                    widget.lightestBarrierColor,
                    fraction,
                  )!
                : widget.initialBarrierColor,
          );
        },
      ),
    );

    final pageView = Listener(
      onPointerUp: (_) => onPointerUp(),
      child: NotificationListener<ViewportUpdateNotification>(
        onNotification: (notification) {
          onViewportChanged(notification.metrics);
          return false;
        },
        child: widget.builder(context),
      ),
    );

    return ScrollConfiguration(
      behavior: const _ModalExprollableScrollBehavior(),
      child: Stack(
        children: [
          Positioned.fill(child: barrier),
          Positioned.fill(child: pageView),
        ],
      ),
    );
  }
}

/// Scroll physics normally used for descendant scrollables of [ModalExprollable].
///
/// This physics always lets the user overscroll making *drag down to dismiss* action
/// available on every platform. [ModalExprollable] provides this as the default physics
/// for its descendants via [ScrollConfiguration].
/// If you explicitly specify a physics for a descendant scrollable,
/// consider to wrap that physics with this.
///
/// ```dart
/// final physics = const ModalExprollableScrollPhysics(
///   parnet: ClampScrollPhysics(),
/// );
/// ```
class ModalExprollableScrollPhysics extends ScrollPhysics {
  /// Creates a scroll physics that always lets the user overscroll.
  ///
  /// This physics will delegate its logic to a [BouncingScrollPhysics]
  /// while the user is overscrolling, so that the *drag down to dismiss* action is available
  /// on every platform. Otherwise, it delegates to the given [parent].
  const ModalExprollableScrollPhysics({
    ScrollPhysics? parent,
  }) : super(parent: parent);

  @override
  ModalExprollableScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ModalExprollableScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  bool get allowImplicitScrolling =>
      parent?.allowImplicitScrolling ?? super.allowImplicitScrolling;

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    if (parent == null ||
        _outOfRange(oldPosition) ||
        _outOfRange(newPosition)) {
      return const BouncingScrollPhysics().adjustPositionForNewDimensions(
        oldPosition: oldPosition,
        newPosition: newPosition,
        isScrolling: isScrolling,
        velocity: velocity,
      );
    } else {
      return parent!.adjustPositionForNewDimensions(
        oldPosition: oldPosition,
        newPosition: newPosition,
        isScrolling: isScrolling,
        velocity: velocity,
      );
    }
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    return velocity < 0
        ? const BouncingScrollPhysics()
            .createBallisticSimulation(position, velocity)
        : super.createBallisticSimulation(position, velocity);
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (parent == null ||
        _outOfRange(position) ||
        _outOfRange(position.copyWith(pixels: value))) {
      return const BouncingScrollPhysics()
          .applyBoundaryConditions(position, value);
    } else {
      return parent!.applyBoundaryConditions(position, value);
    }
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (parent == null ||
        _outOfRange(position) ||
        _outOfRange(position.copyWith(
          pixels: position.pixels + offset,
        ))) {
      return const BouncingScrollPhysics()
          .applyPhysicsToUserOffset(position, offset);
    } else {
      return parent!.applyPhysicsToUserOffset(position, offset);
    }
  }

  bool _outOfRange(ScrollMetrics position) {
    return position.hasPixels &&
        position.hasContentDimensions &&
        position.pixels < position.minScrollExtent;
  }
}

/// Provides [BouncingScrollPhysics] or [ModalExprollableScrollPhysics]
/// as the default scroll physics for descendants.
class _ModalExprollableScrollBehavior extends ScrollBehavior {
  const _ModalExprollableScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    final defaultPhysics = super.getScrollPhysics(context);
    return defaultPhysics is BouncingScrollPhysics
        ? defaultPhysics
        : ModalExprollableScrollPhysics(parent: defaultPhysics);
  }
}

/// A utility class for defining modal route style [ExprollablePageView]s.
///
/// This route has a translucent background (barrier) and
/// adds the *drag down to dismiss* action to the decendant page view.
class ModalExprollableRouteBuilder<T> extends PageRouteBuilder<T> {
  ///Creates a modal style route for a page view.
  ///
  /// If the routes behind this route do not need to be painted,
  /// it is recommended to enable [opaque] and specify [backgroundColor] as well,
  /// which can reduce the cost of building hidden widgets.
  /// See [opaque] for more information.
  ///
  /// If you want to customize reveal/dismiss behavior of the route,
  /// specify your own transitions in [ModalExprollableRouteBuilder.transitionsBuilder].
  ModalExprollableRouteBuilder({
    super.settings,
    required super.pageBuilder,
    super.transitionsBuilder = _defaultTransitionsBuilder,
    super.transitionDuration = const Duration(milliseconds: 300),
    super.reverseTransitionDuration = const Duration(milliseconds: 300),
    super.opaque = false,
    super.barrierDismissible = true,
    super.barrierLabel,
    super.maintainState = true,
    super.fullscreenDialog,
    super.allowSnapshotting = true,
    super.barrierColor = Colors.black54,
    this.backgroundColor,
    this.dismissThresholdInset = const DismissThresholdInset(),
    this.dragDownDismissible = true,
    this.onDismiss,
  }) : assert(backgroundColor == null || opaque,
            "Only opaque routes can have a background color");

  /// The color used for the background if the route is opaque.
  final Color? backgroundColor;

  /// The threshold viewport inset used to trigger the *drap down to dismiss* action.
  ///
  /// When the [Viewport.inset] of the descendant page view
  /// exceeds this threshold and [dragDownDismissible] is true,
  /// [onDismiss] is called to pop the route.
  final DismissThresholdInset dismissThresholdInset;

  /// Specifies if the route will be dismissed by the *drag down to dismiss* action.
  final bool dragDownDismissible;

  /// Called when the route should be dismissed.
  ///
  /// If null, [Navigator.maybePop] is called.
  final VoidCallback? onDismiss;

  ViewportMetrics? _lastReportedViewportMetrics;

  late final ValueNotifier<double?> _userDragDrivenBarrierOpacity;

  bool get _barrierIsNotTransparent => !_barrierIsTransparent;

  bool get _barrierIsTransparent =>
      barrierColor == null || barrierColor!.alpha == 0;

  @override
  void install() {
    super.install();
    if (_barrierIsNotTransparent) {
      _userDragDrivenBarrierOpacity = ValueNotifier(null);
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (_barrierIsNotTransparent) {
      _userDragDrivenBarrierOpacity.dispose();
    }
  }

  void _onViewportMetricsChanged(ViewportMetrics metrics) {
    _lastReportedViewportMetrics = metrics;
    if (_barrierIsNotTransparent) {
      _updateUserDragDrivenBarrierOpacity();
    }
  }

  void _updateUserDragDrivenBarrierOpacity() {
    assert(barrierColor != null);
    assert(_lastReportedViewportMetrics != null);
    assert(_lastReportedViewportMetrics!.hasDimensions);
    final metrics = _lastReportedViewportMetrics!;
    final dismissThresholdInset =
        this.dismissThresholdInset.toConcreteValue(metrics);
    assert(dismissThresholdInset > metrics.shrunkInset);
    final maxOverscroll = dismissThresholdInset - metrics.shrunkInset;
    final overscroll = max(0.0, metrics.inset - metrics.maxInset);
    final dimmedBarrierOpacity = barrierColor!.opacity;
    final brightenedBarrierOpacity = barrierColor!.opacity * 0.5;
    _userDragDrivenBarrierOpacity.value = lerpDouble(
      brightenedBarrierOpacity,
      dimmedBarrierOpacity,
      1.0 - (overscroll / maxOverscroll).clamp(0.0, 1.0),
    );
  }

  @override
  Widget buildModalBarrier() {
    if (_barrierIsTransparent || offstage) {
      return ModalBarrier(
        onDismiss: onDismiss,
        dismissible: barrierDismissible,
        semanticsLabel: barrierLabel,
        barrierSemanticsDismissible: semanticsDismissible,
      );
    }

    assert(animation != null);
    assert(barrierColor != null);
    final targetOpacity =
        _userDragDrivenBarrierOpacity.value ?? barrierColor!.opacity;
    final barrier = _AnimatedModalExprollableRouteBarrier(
      color: barrierColor!,
      userDragDrivenOpacity: _userDragDrivenBarrierOpacity,
      animationDrivenOpacity: animation!.drive(
        Tween(begin: 0.0, end: targetOpacity)
            .chain(CurveTween(curve: barrierCurve)),
      ),
      dismissible: barrierDismissible,
      semanticsLabel: barrierLabel,
      barrierSemanticsDismissible: semanticsDismissible,
      onDismiss: onDismiss,
    );

    if (!opaque || backgroundColor == null || backgroundColor!.alpha == 0) {
      return barrier;
    }

    final background = FadeTransition(
      opacity: animation!.drive(CurveTween(curve: barrierCurve)),
      child: ColoredBox(color: backgroundColor!),
    );
    return Stack(children: [
      Positioned.fill(child: background),
      Positioned.fill(child: barrier),
    ]);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    Widget page = pageBuilder(context, animation, secondaryAnimation);
    if (_barrierIsNotTransparent) {
      page = NotificationListener<ViewportUpdateNotification>(
        onNotification: (notification) {
          _onViewportMetricsChanged(notification.metrics);
          return false;
        },
        child: page,
      );
    }
    if (dragDownDismissible) {
      page = _ModalExprollableDismissible(
        dismissThresholdInset: dismissThresholdInset,
        onDismiss: onDismiss,
        child: page,
      );
    }
    return page;
  }

  static Widget _defaultTransitionsBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return DefaultModalExprollableRouteTransition(
      parentAnimation: animation,
      slideInCurve: Curves.easeOutCubic,
      slideOutCurve: Curves.easeInCubic,
      child: child,
    );
  }
}

/// The default transition for [ModalExprollableRouteBuilder].
///
/// It is a combination of a slide transition and a fade transition.
class DefaultModalExprollableRouteTransition extends StatefulWidget {
  /// Creates a default transition for [ModalExprollableRouteBuilder].
  const DefaultModalExprollableRouteTransition({
    super.key,
    required this.parentAnimation,
    this.fadeInCurve = Curves.easeInOut,
    this.fadeOutCurve,
    this.slideInCurve = Curves.easeOutCubic,
    this.slideOutCurve,
    required this.child,
  });

  /// An animation that drives this transition.
  final Animation<double> parentAnimation;

  /// The curve used for the fade in transition.
  final Curve fadeInCurve;

  /// The curve used for the fade out transition.
  ///
  /// If null, [fadeInCurve] is used.
  final Curve? fadeOutCurve;

  /// The curve used for the slide in transition.
  final Curve slideInCurve;

  /// The curve used for the slide out transition.
  ///
  /// If null, [slideInCurve] is used.
  final Curve? slideOutCurve;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  State<DefaultModalExprollableRouteTransition> createState() =>
      _DefaultModalExprollableRouteTransitionState();
}

class _DefaultModalExprollableRouteTransitionState
    extends State<DefaultModalExprollableRouteTransition> {
  late Animation<double> opacityAnimation;
  late Animation<Offset> positionAnimation;

  @override
  void initState() {
    super.initState();
    initAnimations();
  }

  @override
  void didUpdateWidget(DefaultModalExprollableRouteTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.parentAnimation != oldWidget.parentAnimation ||
        widget.fadeInCurve != oldWidget.fadeInCurve ||
        widget.fadeOutCurve != oldWidget.fadeOutCurve ||
        widget.slideInCurve != oldWidget.slideInCurve ||
        widget.slideOutCurve != oldWidget.slideOutCurve) {
      initAnimations();
    }
  }

  void initAnimations() {
    opacityAnimation = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: widget.parentAnimation,
        curve: widget.fadeInCurve,
        reverseCurve: widget.fadeOutCurve ?? widget.fadeInCurve,
      ),
    );
    positionAnimation = Tween(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: widget.parentAnimation,
        curve: widget.slideInCurve,
        reverseCurve: widget.slideOutCurve ?? widget.slideInCurve,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacityAnimation,
      child: SlideTransition(
        position: positionAnimation,
        child: widget.child,
      ),
    );
  }
}

class _AnimatedModalExprollableRouteBarrier extends StatefulWidget {
  _AnimatedModalExprollableRouteBarrier({
    required this.color,
    required this.animationDrivenOpacity,
    required this.userDragDrivenOpacity,
    this.dismissible = true,
    this.barrierSemanticsDismissible,
    this.semanticsLabel,
    this.onDismiss,
  }) : assert(color.alpha != 0);

  final Color color;
  final Animation<double> animationDrivenOpacity;
  final ValueListenable<double?> userDragDrivenOpacity;
  final bool dismissible;
  final bool? barrierSemanticsDismissible;
  final String? semanticsLabel;
  final VoidCallback? onDismiss;

  @override
  State<_AnimatedModalExprollableRouteBarrier> createState() =>
      _AnimatedModalExprollableRouteBarrierState();
}

class _AnimatedModalExprollableRouteBarrierState
    extends State<_AnimatedModalExprollableRouteBarrier> {
  @override
  void initState() {
    super.initState();
    attachUserDrivenOpacity(widget.userDragDrivenOpacity);
    attachAnimationDrivenOpacity(widget.animationDrivenOpacity);
  }

  @override
  void dispose() {
    super.dispose();
    detachUserDrivenOpacity(widget.userDragDrivenOpacity);
    detachAnimationDrivenOpacity(widget.animationDrivenOpacity);
  }

  @override
  void didUpdateWidget(_AnimatedModalExprollableRouteBarrier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userDragDrivenOpacity != oldWidget.userDragDrivenOpacity) {
      detachUserDrivenOpacity(oldWidget.userDragDrivenOpacity);
      attachUserDrivenOpacity(widget.userDragDrivenOpacity);
    }
    if (widget.animationDrivenOpacity != oldWidget.animationDrivenOpacity) {
      detachAnimationDrivenOpacity(oldWidget.animationDrivenOpacity);
      attachAnimationDrivenOpacity(widget.animationDrivenOpacity);
    }
  }

  void attachUserDrivenOpacity(ValueListenable<double?> opacity) =>
      opacity.addListener(handleUserDragDrivenOpacityUpdate);

  void detachUserDrivenOpacity(ValueListenable<double?> opacity) =>
      opacity.removeListener(handleUserDragDrivenOpacityUpdate);

  void attachAnimationDrivenOpacity(Animation<double> opacity) =>
      opacity.addListener(handleAnimationDrivenOpacityUpdate);

  void detachAnimationDrivenOpacity(Animation<double> opacity) =>
      opacity.removeListener(handleAnimationDrivenOpacityUpdate);

  void handleAnimationDrivenOpacityUpdate() => setState(() {});

  void handleUserDragDrivenOpacityUpdate() {
    if (!isAnimationRunning()) setState(() {});
  }

  bool isAnimationRunning() =>
      widget.animationDrivenOpacity.status == AnimationStatus.forward ||
      widget.animationDrivenOpacity.status == AnimationStatus.reverse;

  double currentOpacity() {
    switch (widget.animationDrivenOpacity.status) {
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        return widget.animationDrivenOpacity.value;
      case AnimationStatus.completed:
        return widget.userDragDrivenOpacity.value ?? widget.color.opacity;
      case AnimationStatus.dismissed:
        return widget.userDragDrivenOpacity.value ?? 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalBarrier(
      color: widget.color.withOpacity(currentOpacity()),
      semanticsLabel: widget.semanticsLabel,
      dismissible: widget.dismissible,
      barrierSemanticsDismissible: widget.barrierSemanticsDismissible,
      onDismiss: widget.onDismiss,
    );
  }
}

// TODO: Improve the logic
class _ModalExprollableDismissible extends StatefulWidget {
  const _ModalExprollableDismissible({
    required this.dismissThresholdInset,
    required this.onDismiss,
    required this.child,
  });

  final Widget child;
  final DismissThresholdInset dismissThresholdInset;
  final VoidCallback? onDismiss;

  @override
  State<_ModalExprollableDismissible> createState() =>
      _ModalExprollableDismissibleState();
}

class _ModalExprollableDismissibleState
    extends State<_ModalExprollableDismissible> {
  ViewportMetrics? _lastReportedViewportMetrics;

  bool _handleViewportMetricsUpdate(ViewportUpdateNotification notification) {
    _lastReportedViewportMetrics = notification.metrics;
    return false;
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (shouldDismiss()) _handleDismiss();
  }

  void _handleDismiss() {
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else {
      Navigator.maybePop(context);
    }
  }

  bool shouldDismiss() {
    final metrics = _lastReportedViewportMetrics;
    if (metrics != null && metrics.hasDimensions) {
      final threshold = widget.dismissThresholdInset.toConcreteValue(metrics);
      if (metrics.inset > threshold) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerUp: _handlePointerUp,
      child: ScrollConfiguration(
        behavior: const _ModalExprollableScrollBehavior(),
        child: NotificationListener<ViewportUpdateNotification>(
          onNotification: _handleViewportMetricsUpdate,
          child: widget.child,
        ),
      ),
    );
  }
}
