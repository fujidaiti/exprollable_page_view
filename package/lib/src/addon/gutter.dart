import 'package:exprollable_page_view/src/core/controller.dart';
import 'package:exprollable_page_view/src/core/view.dart';
import 'package:exprollable_page_view/src/internal/utils.dart';
import 'package:flutter/widgets.dart';

/// Insert spaces at both sides of the wrapped page.
class PageGutter extends StatefulWidget {
  /// Creates a widget that inserts spaces of [gutterWidth] at both sides of [child].
  const PageGutter({
    super.key,
    required this.child,
    required this.gutterWidth,
  }) : assert(gutterWidth >= 0.0);

  /// A page to be wrapped.
  final Widget child;

  /// The width in pixels of the gutter to be inserted.
  final double gutterWidth;

  @override
  State<PageGutter> createState() => _PageGutterState();
}

class _PageGutterState extends State<PageGutter> {
  late double deltaX;
  late ExprollablePageController controller;
  late int page;
  bool beforeFirstBuild = true;

  @override
  void didUpdateWidget(covariant PageGutter oldWidget) {
    super.didUpdateWidget(oldWidget);
    correctState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = ExprollablePageController.of(context);
    final page = ViewportController.of(context)?.page;

    assert(
      controller != null && page != null,
      "$PageGutter can only be used in a subtree of $ExprollablePageView.",
    );

    if (beforeFirstBuild) {
      this.controller = controller!..addListener(invalidateState);
    } else if (controller != this.controller) {
      this.controller.removeListener(invalidateState);
      this.controller = controller!..addListener(invalidateState);
    }
    this.page = page!;
    correctState();
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeListener(invalidateState);
  }

  void invalidateState() {
    final oldDeltaX = deltaX;
    correctState();
    if (!oldDeltaX.almostEqualTo(deltaX)) {
      setState(() {});
    }
  }

  void correctState() => deltaX = computeDeltaX();

  double computeDeltaX() {
    if (controller.hasClients && controller.position.hasContentDimensions) {
      final realPage = controller.page!;
      final fraction = (page - realPage).clamp(-1.0, 1.0);
      return widget.gutterWidth * fraction;
    } else if (page == controller.currentPage.value) {
      return 0.0;
    } else if (page < controller.currentPage.value) {
      return -1 * widget.gutterWidth;
    } else {
      return widget.gutterWidth;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (beforeFirstBuild) {
      beforeFirstBuild = false;
    }
    return Transform.translate(
      offset: Offset(deltaX, 0.0),
      child: widget.child,
    );
  }
}
