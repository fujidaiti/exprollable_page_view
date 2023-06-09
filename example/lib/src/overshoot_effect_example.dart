import 'package:example/src/common.dart';
import 'package:exprollable_page_view/exprollable_page_view.dart';
import 'package:flutter/material.dart';

class OvershootEffectExample extends StatefulWidget {
  const OvershootEffectExample({super.key});

  @override
  State<StatefulWidget> createState() => _OvershootEffectExampleState();
}

class _OvershootEffectExampleState extends State<OvershootEffectExample> {
  late final ExprollablePageController controller;

  @override
  void initState() {
    super.initState();
    controller = ExprollablePageController(
      viewportConfiguration: ViewportConfiguration(
        overshootEffect: true,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const ExampleBottomAppBar(),
      body: ExprollablePageView(
        controller: controller,
        itemCount: 5,
        itemBuilder: (context, page) {
          return ExampleListView(
            controller: PageContentScrollController.of(context),
            page: page,
          );
        },
      ),
    );
  }
}
