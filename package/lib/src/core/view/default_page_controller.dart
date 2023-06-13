import 'package:exprollable_page_view/src/core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

@internal
class InheritedDefaultPageConfiguration extends InheritedWidget {
  const InheritedDefaultPageConfiguration({
    super.key,
    required this.controller,
    required super.child,
  });

  final ExprollablePageController controller;

  @override
  bool updateShouldNotify(InheritedDefaultPageConfiguration oldWidget) =>
      controller != oldWidget.controller;
}

class DefaultPageConfiguration extends StatefulWidget {
  const DefaultPageConfiguration({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<DefaultPageConfiguration> createState() =>
      _DefaultPageConfigurationState();
}

class _DefaultPageConfigurationState extends State<DefaultPageConfiguration> {
  late final ExprollablePageController controller;

  @override
  void initState() {
    super.initState();
    controller = ExprollablePageController();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedDefaultPageConfiguration(
      controller: controller,
      child: widget.child,
    );
  }
}
