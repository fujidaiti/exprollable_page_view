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

  static ExprollablePageController? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<InheritedPageConfiguration>()
      ?.controller;
}

class PageConfiguration extends StatefulWidget {
  const PageConfiguration({
    super.key,
    required this.viewportConfiguration,
    required this.child,
  });

  final ViewportConfiguration? viewportConfiguration;
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
    if (widget.viewportConfiguration != oldWidget.viewportConfiguration) {
      controller.dispose();
      controller = createController();
    }
  }

  ExprollablePageController createController() {
    return ExprollablePageController(
      viewportConfiguration: widget.viewportConfiguration ??
          ViewportConfiguration.defaultConfiguration,
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
