import 'dart:math';

import 'package:exprollable_page_view/src/core/controller.dart';
import 'package:exprollable_page_view/src/core/view.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

class AdaptivePagePadding extends StatefulWidget {
  const AdaptivePagePadding({
    super.key,
    required this.child,
    this.useSafeArea = true,
  });

  final Widget child;
  final bool useSafeArea;

  @override
  State<AdaptivePagePadding> createState() => _AdaptivePagePaddingState();
}

class _AdaptivePagePaddingState extends State<AdaptivePagePadding> {
  ViewportController? viewport;
  double? padding;

  @override
  void dispose() {
    super.dispose();
    viewport?.removeListener(invalidateState);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewport = ViewportController.of(context);
    assert(
      viewport != null,
      "$AdaptivePagePadding can only be placed in a subtree of $ExprollablePageView.",
    );

    if (!identical(viewport, this.viewport)) {
      this.viewport?.removeListener(invalidateState);
      this.viewport = viewport!..addListener(invalidateState);
      correctState();
    }
  }

  @override
  void didUpdateWidget(covariant AdaptivePagePadding oldWidget) {
    super.didUpdateWidget(oldWidget);
    correctState();
  }

  void invalidateState() {
    final oldPadding = padding;
    correctState();
    if (!nearEqual(
      oldPadding,
      padding,
      Tolerance.defaultTolerance.distance,
    )) {
      setState(() {});
    }
  }

  void correctState() {
    assert(viewport != null);
    final vp = viewport!;
    padding = widget.useSafeArea
        ? max(0.0, vp.dimensions.padding.top - vp.offset)
        : max(0.0, -1 * vp.offset);
  }

  @override
  Widget build(BuildContext context) {
    assert(padding != null);
    return Padding(
      padding: EdgeInsets.only(top: padding!),
      child: widget.child,
    );
  }
}
