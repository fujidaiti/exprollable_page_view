import 'package:exprollable_page_view/src/core/controller.dart';
import 'package:exprollable_page_view/src/core/view/exprollable_page_view.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

@internal
class InheritedPageConfiguration extends InheritedWidget {
  const InheritedPageConfiguration({
    super.key,
    required this.controller,
    required super.child,
  });

  final ExprollablePageController controller;

  @override
  bool updateShouldNotify(InheritedPageConfiguration oldWidget) =>
      controller != oldWidget.controller;

  static InheritedPageConfiguration? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedPageConfiguration>();
}

/// A widget that provides an [ExprollablePageController]
/// configured with the given parameters to the descendants in the tree.
///
/// This is useful if you want to use an [ExprollablePageView]
/// with a custom configuration in a [StatelessWidget] without
/// explicitly creating a controller.
/// The controller given by this widget and attached to the descendant
/// page view can be obtained by using [ExprollablePageController.of]
/// from anywhere in the subtree of the page view.
class PageConfiguration extends StatefulWidget {
  /// Creates a provider of a page controller configured with the given parameters.
  const PageConfiguration({
    super.key,
    this.viewportConfiguration = ViewportConfiguration.defaultConfiguration,
    this.viewportFractionBehavior = const DefaultViewportFractionBehavior(),
    this.keepPage = true,
    this.initialPage = 0,
    required this.child,
  });

  /// A configuration object that is passed to [ExprollablePageController.new].
  final ViewportConfiguration viewportConfiguration;

  /// A behavior object that is passed to [ExprollablePageController.new].
  final ViewportFractionBehavior viewportFractionBehavior;

  /// The `keepPage` flag that is passed to [ExprollablePageController.new].
  final bool keepPage;

  /// The `initialPage` value that is passed to [ExprollablePageController.new].
  final int initialPage;

  /// The widget below this widget in the tree.
  /// 
  /// Typically, this will be an [ExprollablePageView] or
  /// a widget that contains an [ExprollablePageView] in its descendants.
  final Widget child;

  @override
  State<PageConfiguration> createState() => _PageConfigurationState();
}

class _PageConfigurationState extends State<PageConfiguration> {
  late ExprollablePageController controller;

  @override
  void initState() {
    super.initState();
    controller = createController();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  void didUpdateWidget(PageConfiguration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.keepPage != oldWidget.keepPage ||
        widget.initialPage != oldWidget.initialPage ||
        widget.viewportConfiguration != oldWidget.viewportConfiguration ||
        widget.viewportFractionBehavior != oldWidget.viewportFractionBehavior) {
      controller.dispose();
      controller = createController();
    }
  }

  ExprollablePageController createController() {
    return ExprollablePageController(
      initialPage: widget.initialPage,
      keepPage: widget.keepPage,
      viewportConfiguration: widget.viewportConfiguration,
      viewportFractionBehavior: widget.viewportFractionBehavior,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InheritedPageConfiguration(
      controller: controller,
      child: widget.child,
    );
  }
}
