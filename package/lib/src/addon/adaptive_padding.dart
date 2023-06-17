import 'dart:math';

import 'package:exprollable_page_view/src/core/controller.dart';
import 'package:exprollable_page_view/src/core/view/view.dart';
import 'package:exprollable_page_view/src/internal/utils.dart';
import 'package:flutter/widgets.dart' hide Viewport;

/// Inserts appropriate padding into the child widget according to the current viewpor inset.
class AdaptivePagePadding extends StatefulWidget {
  /// Creates a widget that inserts appropriate padding into
  /// the top of the child widget according to the current viewport inset.
  /// It also adds extra padding if [useSafeArea] is enabled to prevents
  /// the child from being obscured by the system UI such as the status bar.
  const AdaptivePagePadding({
    super.key,
    required this.child,
    this.useSafeArea = true,
  });

  /// The child widget which [AdaptivePagePadding] will add padding to.
  final Widget child;

  /// Indicates whether the widget should add extra padding
  /// to prevent the child from being obscured by the system UI.
  final bool useSafeArea;

  @override
  State<AdaptivePagePadding> createState() => _AdaptivePagePaddingState();
}

class _AdaptivePagePaddingState extends State<AdaptivePagePadding> {
  Viewport? viewport;
  PageViewport? pageViewport;
  double? padding;

  @override
  void dispose() {
    super.dispose();
    pageViewport?.removeListener(invalidateState);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewport = ExprollablePageController.of(context)?.viewport;
    final pageViewport = PageViewport.of(context);
    assert(
      pageViewport != null && viewport != null,
      "$AdaptivePagePadding can only be placed in a subtree of $ExprollablePageView.",
    );

    if (!identical(pageViewport, this.pageViewport)) {
      this.pageViewport?.removeListener(invalidateState);
      this.pageViewport = pageViewport!..addListener(invalidateState);
    }
    this.viewport = viewport!;
    correctState();
  }

  @override
  void didUpdateWidget(covariant AdaptivePagePadding oldWidget) {
    super.didUpdateWidget(oldWidget);
    correctState();
  }

  void invalidateState() {
    final oldPadding = padding;
    correctState();
    assert(padding != null);
    if (oldPadding?.almostEqualTo(padding!) != true) {
      setState(() {});
    }
  }

  void correctState() {
    assert(viewport != null);
    assert(pageViewport != null);
    final offset = pageViewport!.offset;
    final topPadding = viewport!.dimensions.padding.top;
    padding = widget.useSafeArea
        ? max(0.0, topPadding - offset)
        : max(0.0, -1 * offset);
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
