import 'dart:math';

import 'package:exprollable_page_view/src/core/controller.dart';
import 'package:flutter/material.dart';

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
  ViewportOffset dismissThresholdOffset =
      const ViewportOffset.fractional(0.15),
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

class ModalExprollable extends StatefulWidget {
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

  final void Function(BuildContext) dismissBehavior;
  final ViewportOffset dismissThresholdOffset;
  final bool barrierDismissible;
  final Color darkestBarrierColor;
  final Color lightestBarrierColor;
  final Color initialBarrierColor;
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
    if (lastViewportMetrics != null &&
        lastViewportMetrics!.hasDimensions) {
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
        widget.dismissThresholdOffset.toConcreteValue(vp) -
            vp.shrunkOffset;
    final overscroll = max(0.0, vp.offset - vp.maxOffset);
    assert(maxOverscroll > 0.0);
    barrierColorFraction.value =
        (overscroll / maxOverscroll).clamp(0.0, 1.0);
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

    return Stack(
      children: [
        Positioned.fill(child: barrier),
        Positioned.fill(child: pageView),
      ],
    );
  }
}
