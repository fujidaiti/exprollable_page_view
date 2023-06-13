import 'package:exprollable_page_view/src/core/controller.dart';
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

class PageConfiguration extends StatefulWidget {
  const PageConfiguration({
    super.key,
    this.viewportConfiguration = ViewportConfiguration.defaultConfiguration,
    this.viewportFractionBehavior = const DefaultViewportFractionBehavior(),
    this.keepPage = true,
    this.initialPage = 0,
    required this.child,
  });

  final ViewportConfiguration viewportConfiguration;
  final ViewportFractionBehavior viewportFractionBehavior;
  final bool keepPage;
  final int initialPage;
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
