import 'dart:math';

import 'package:exprollable_page_view/src/core/controller.dart';
import 'package:exprollable_page_view/src/internal/paging.dart';
import 'package:exprollable_page_view/src/internal/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class ExprollablePageView extends StatefulWidget {
  const ExprollablePageView({
    super.key,
    required this.itemBuilder,
    this.itemCount,
    this.controller,
    this.reverse = false,
    this.physics,
    this.dragStartBehavior = DragStartBehavior.start,
    this.allowImplicitScrolling = false,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.scrollBehavior,
    this.padEnds = true,
    this.onViewportChanged,
  });

  final IndexedWidgetBuilder itemBuilder;

  final int? itemCount;
  final ExprollablePageController? controller;

  /// Whether the page view scrolls in the reading direction.
  /// See [PageView.reverse] for more details.
  final bool reverse;

  /// How the page view should respond to user input.
  /// See [PageView.physics] for more details.
  final ScrollPhysics? physics;

  final DragStartBehavior dragStartBehavior;
  final bool allowImplicitScrolling;
  final String? restorationId;
  final Clip clipBehavior;
  final ScrollBehavior? scrollBehavior;
  final bool padEnds;
  final void Function(PageViewportMetrics metrics)? onViewportChanged;

  @override
  State<ExprollablePageView> createState() => _ExprollablePageViewState();
}

class _ExprollablePageViewState extends State<ExprollablePageView> {
  final ValueNotifier<bool?> allowPaging = ValueNotifier(null);
  late ExprollablePageController controller;

  @override
  void initState() {
    super.initState();
    attach(widget.controller ?? _DefaultPageController());
  }

  @override
  void dispose() {
    super.dispose();
    allowPaging.dispose();
    detach(controller);
  }

  @override
  void didUpdateWidget(covariant ExprollablePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!(controller is _DefaultPageController && widget.controller == null)) {
      detach(controller);
      attach(oldWidget.controller ?? _DefaultPageController());
    }
  }

  void detach(ExprollablePageController controller) {
    controller.viewport.removeListener(onViewportChanged);
    if (controller is _DefaultPageController) {
      controller.dispose();
    }
  }

  void attach(ExprollablePageController controller) {
    this.controller = controller..viewport.addListener(onViewportChanged);
  }

  void onViewportChanged() {
    allowPaging.value = checkIfPagingIsAllowed();
    widget.onViewportChanged?.call(controller.viewport);
    PageViewportUpdateNotification(
      StaticPageViewportMetrics.from(controller.viewport),
    ).dispatch(context);
  }

  bool checkIfPagingIsAllowed() => controller.viewport.fraction
      .almostEqualTo(controller.viewport.minFraction);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return InheritedExprollablePageController(
      controller: controller,
      child: LayoutBuilder(
        builder: (context, constraints) {
          controller.viewport.correctForNewDimensions(
            ViewportDimensions(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              padding: mediaQuery.padding,
            ),
          );

          return ValueListenableBuilder(
            valueListenable: allowPaging,
            builder: (context, allowPaging, _) {
              return ValueListenableBuilder(
                valueListenable: controller.viewport,
                builder: (context, viewport, child) {
                  return Transform.translate(
                    offset: Offset(0, max(0.0, viewport.offset)),
                    child: child,
                  );
                },
                child: AlwaysFillViewportPageView.builder(
                  reverse: widget.reverse,
                  dragStartBehavior: widget.dragStartBehavior,
                  allowImplicitScrolling: widget.allowImplicitScrolling,
                  scrollBehavior: widget.scrollBehavior,
                  padEnds: widget.padEnds,
                  restorationId: widget.restorationId,
                  physics: allowPaging ?? checkIfPagingIsAllowed()
                      ? widget.physics
                      : const NeverScrollableScrollPhysics(),
                  controller: controller,
                  itemCount: widget.itemCount,
                  itemBuilder: (context, page) {
                    return _PageItemContainer(
                      page: page,
                      controller: controller,
                      builder: (context) => widget.itemBuilder(context, page),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DefaultPageController extends ExprollablePageController {
  _DefaultPageController();
}

class _PageItemContainer extends StatefulWidget {
  const _PageItemContainer({
    required this.page,
    required this.controller,
    required this.builder,
  });

  final int page;
  final ExprollablePageController controller;

  final WidgetBuilder builder;

  @override
  State<_PageItemContainer> createState() => _PageItemContainerState();
}

class _PageItemContainerState extends State<_PageItemContainer> {
  late PageContentScrollController scrollController;
  late ViewportController viewport;
  late ValueNotifier<bool> isActive;

  @override
  void initState() {
    super.initState();
    viewport = ViewportController(
      page: widget.page,
      pageController: widget.controller,
    );
    scrollController = widget.controller.createScrollController(widget.page);
    isActive = ValueNotifier(checkActiveness());
    widget.controller.currentPage.addListener(invalidateActiveness);
  }

  @override
  void dispose() {
    super.dispose();
    viewport.dispose();
    isActive.dispose();
    widget.controller
      ..disposeScrollController(widget.page)
      ..currentPage.removeListener(invalidateActiveness);
  }

  void invalidateActiveness() => isActive.value = checkActiveness();

  bool checkActiveness() => widget.page == widget.controller.currentPage.value;

  @override
  void didUpdateWidget(_PageItemContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller
        ..disposeScrollController(oldWidget.page)
        ..currentPage.removeListener(invalidateActiveness);
      scrollController = widget.controller.createScrollController(widget.page);
      widget.controller.currentPage.removeListener(invalidateActiveness);
    }

    if (oldWidget.controller != widget.controller ||
        oldWidget.page != widget.page) {
      viewport.dispose();
      viewport = ViewportController(
        page: widget.page,
        pageController: widget.controller,
      );
    }

    if (oldWidget.page != widget.page) {
      invalidateActiveness();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InheritedViewportController(
      controller: viewport,
      child: InheritedPageContentScrollController(
        controller: scrollController,
        child: _PageItem(
          isActive: isActive,
          viewport: viewport,
          builder: widget.builder,
        ),
      ),
    );
  }
}

class _PageItem extends StatelessWidget {
  const _PageItem({
    required this.isActive,
    required this.viewport,
    required this.builder,
  });

  final ValueListenable<bool> isActive;
  final ViewportController viewport;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isActive,
      child: builder(context),
      builder: (_, isActive, child) {
        return IgnorePointer(
          ignoring: !isActive,
          child: AnimatedBuilder(
            animation: viewport,
            builder: (_, __) {
              return Transform(
                transform: Matrix4.identity()
                  ..translate(
                    viewport.translation.dx,
                    viewport.translation.dy,
                  )
                  ..scale(viewport.fraction),
                child: child,
              );
            },
          ),
        );
      },
    );
  }
}
