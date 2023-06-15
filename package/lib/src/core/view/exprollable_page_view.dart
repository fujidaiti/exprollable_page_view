import 'dart:math';

import 'package:exprollable_page_view/src/core/controller.dart';
import 'package:exprollable_page_view/src/core/view/default_page_configuration.dart';
import 'package:exprollable_page_view/src/core/view/page_configuration.dart';
import 'package:exprollable_page_view/src/internal/paging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// A page view that expands the viewport of the current page while scrolling it.
class ExprollablePageView extends StatelessWidget {
  /// Creates a page view.
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
    this.onPageChanged,
  });

  /// A builder that creates a scrollable page for a given index.
  ///
  /// Note that **[ExprollablePageView] will not works as expected
  /// if a [ScrollController] obtained by [PageContentScrollController.of]
  /// is not attached to the scrollable widget that is returned**.
  final IndexedWidgetBuilder itemBuilder;

  /// The number of pages.
  ///
  /// Providing null makes the [ExprollablePageView] to scroll infinitely.
  final int? itemCount;

  /// A controller for the page view.
  final ExprollablePageController? controller;

  /// Whether the page view scrolls in the reading direction.
  ///
  /// See [PageView.reverse] for more details.
  final bool reverse;

  /// How the page view should respond to user input.
  ///
  /// See [PageView.physics] for more details.
  final ScrollPhysics? physics;

  /// Determines the way that drag start behavior is handled.
  ///
  /// See [PageView.dragStartBehavior] for more details.
  final DragStartBehavior dragStartBehavior;

  /// Controls whether the widget's pages will respond to [RenderObject.showOnScreen],
  /// which will allow for implicit accessibility scrolling.
  ///
  /// See [PageView.allowImplicitScrolling] for more detials.
  final bool allowImplicitScrolling;

  /// Restoration ID to save and restore the scroll offset of the scrollable.
  ///
  /// See [PageView.restorationId] for more details.
  final String? restorationId;

  /// The content will be clipped (or not) according to this option.
  ///
  /// See [PageView.clipBehavior] for more details.
  final Clip clipBehavior;

  /// A [ScrollBehavior] that will be applied to this widget individually.
  ///
  /// See [PageView.scrollBehavior] for more detials.
  final ScrollBehavior? scrollBehavior;

  /// Whether to add padding to both ends of the list.
  ///
  /// See [PageView.padEnds] for more details.
  final bool padEnds;

  /// Called whnever the viewport fraction or inset changes.
  ///
  /// Providing this callback is equivalent to subscribing to [ExprollablePageController.viewport].
  final void Function(ViewportMetrics metrics)? onViewportChanged;

  /// Called whenever the focused page changes.
  ///
  /// Providing this callback is equivalent to subscribing to [ExprollablePageController.currentPage].
  final void Function(int page)? onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return _build(controller!);
    }

    final inheritedController =
        InheritedPageConfiguration.of(context)?.controller;
    if (inheritedController != null) {
      return _build(inheritedController);
    }

    return DefaultPageConfiguration(
      child: Builder(
        builder: (context) {
          final defaultController =
              InheritedDefaultPageConfiguration.of(context)?.controller;
          return _build(defaultController!);
        },
      ),
    );
  }

  Widget _build(ExprollablePageController controller) {
    return _ExprollablePageViewImpl(
      controller: controller,
      itemBuilder: itemBuilder,
      itemCount: itemCount,
      reverse: reverse,
      physics: physics,
      dragStartBehavior: dragStartBehavior,
      allowImplicitScrolling: allowImplicitScrolling,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      scrollBehavior: scrollBehavior,
      padEnds: padEnds,
      onViewportChanged: onViewportChanged,
      onPageChanged: onPageChanged,
    );
  }
}

class _ExprollablePageViewImpl extends StatefulWidget {
  const _ExprollablePageViewImpl({
    required this.itemBuilder,
    required this.itemCount,
    required this.controller,
    required this.reverse,
    required this.physics,
    required this.dragStartBehavior,
    required this.allowImplicitScrolling,
    required this.restorationId,
    required this.clipBehavior,
    required this.scrollBehavior,
    required this.padEnds,
    required this.onViewportChanged,
    required this.onPageChanged,
  });

  final IndexedWidgetBuilder itemBuilder;
  final int? itemCount;
  final ExprollablePageController controller;
  final bool reverse;
  final ScrollPhysics? physics;
  final DragStartBehavior dragStartBehavior;
  final bool allowImplicitScrolling;
  final String? restorationId;
  final Clip clipBehavior;
  final ScrollBehavior? scrollBehavior;
  final bool padEnds;
  final void Function(ViewportMetrics metrics)? onViewportChanged;
  final void Function(int page)? onPageChanged;

  @override
  State<_ExprollablePageViewImpl> createState() =>
      _ExprollablePageViewImplState();
}

class _ExprollablePageViewImplState extends State<_ExprollablePageViewImpl> {
  final ValueNotifier<bool?> allowPaging = ValueNotifier(null);

  ExprollablePageController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    attach(widget.controller);
  }

  @override
  void dispose() {
    super.dispose();
    allowPaging.dispose();
    detach(widget.controller);
  }

  @override
  void didUpdateWidget(_ExprollablePageViewImpl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      detach(oldWidget.controller);
      attach(widget.controller);
    }
  }

  void detach(ExprollablePageController controller) {
    controller
      ..viewport.removeListener(onViewportChanged)
      ..currentPage.removeListener(onPageChanged);
  }

  void attach(ExprollablePageController controller) {
    controller
      ..viewport.addListener(onViewportChanged)
      ..currentPage.addListener(onPageChanged);
  }

  void onViewportChanged() {
    allowPaging.value = checkIfPagingIsAllowed();
    widget.onViewportChanged?.call(controller.viewport);
    ViewportUpdateNotification(
      StaticViewportMetrics.from(controller.viewport),
    ).dispatch(context);
  }

  void onPageChanged() {
    widget.onPageChanged?.call(controller.currentPage.value);
  }

  // bool checkIfPagingIsAllowed() => controller.viewport.isPageShrunk;
  bool checkIfPagingIsAllowed() => true;

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

          final pageDimensions = controller.viewport.pageDimensions;
          final pageConstraints = BoxConstraints(
            minWidth: pageDimensions.maxWidth,
            maxWidth: pageDimensions.maxWidth,
            minHeight: pageDimensions.maxHeight,
            maxHeight: pageDimensions.maxHeight,
          );

          return ValueListenableBuilder(
            valueListenable: allowPaging,
            builder: (context, allowPaging, _) {
              return ValueListenableBuilder(
                valueListenable: controller.viewport,
                builder: (context, viewport, child) {
                  return Transform.translate(
                    offset: Offset(0, max(0.0, viewport.inset)),
                    child: child,
                  );
                },
                child: OverflowPageView.builder(
                  childConstraints: pageConstraints,
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
  late PageViewport viewport;
  late ValueNotifier<bool> isActive;

  @override
  void initState() {
    super.initState();
    viewport = PageViewport(
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
      viewport = PageViewport(
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
    return InheritedPageViewport(
      pageView: viewport,
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
  final PageViewport viewport;
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
