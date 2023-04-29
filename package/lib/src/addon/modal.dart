import 'dart:math';

import 'package:exprollable_page_view/src/core/controller.dart';
import 'package:exprollable_page_view/src/core/view.dart';
import 'package:flutter/material.dart';

/// Show a [ExprollablePageView] as a modal dialog.
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
  ViewportOffset dismissThresholdOffset = const ViewportOffset.fractional(0.18),
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
          dismissThresholdOffset: dismissThresholdOffset,
        ),
      ),
    );

void _defaultDismissBehavior(BuildContext context) =>
    Navigator.of(context).pop();

/// A widget that makes a [ExprollablePageView] modal dialog style.
///
/// This widget adds a translucent background (barrier) and
/// *swipe down to dismiss* action to the child page view.
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
    this.dismissThresholdOffset = const ViewportOffset.fractional(0.18),
  }) : assert(dismissThresholdOffset > ViewportOffset.shrunk);

  /// Called when the dialog should be dismissed.
  /// The default behavior is to pop the dialog
  /// by calling [Navigator.pop] without result value.
  final void Function(BuildContext) dismissBehavior;

  /// The threshold offset at which the dialog
  /// should be dismissed by *swipe down to dismiss* action.
  final ViewportOffset dismissThresholdOffset;

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
  PageViewportMetrics? lastViewportMetrics;

  @override
  void dispose() {
    super.dispose();
    barrierColorFraction.dispose();
  }

  void onViewportChanged(PageViewportMetrics metrics) {
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
      final threshold = widget.dismissThresholdOffset.toConcreteValue(vp);
      if (vp.offset > threshold) return true;
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
    final maxOverscroll =
        widget.dismissThresholdOffset.toConcreteValue(vp) - vp.shrunkOffset;
    final overscroll = max(0.0, vp.offset - vp.maxOffset);
    assert(maxOverscroll > 0.0);
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
      child: NotificationListener<PageViewportUpdateNotification>(
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

class ModalExprollableScrollPhysics extends ScrollPhysics {
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
