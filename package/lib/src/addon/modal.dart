import 'dart:math';

import 'package:exprollable_page_view/src/core/controller.dart';
import 'package:exprollable_page_view/src/core/view.dart';
import 'package:flutter/material.dart' hide Viewport;

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
