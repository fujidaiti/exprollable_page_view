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
        // Make sure that your Scaffold has a bottom navigation bar,
        // and Scaffold.extendBody is set true. You should avoid using
        // SafeArea for the top of the screen for better visual effect.
        overshootEffect: true,
        minViewportOffset: ViewportOffset.overshoot,
        maxViewportOffset: ViewportOffset.fractional(0.6),
        shrunkViewportOffset: ViewportOffset.fractional(0.4),
        expandedViewportOffset: ViewportOffset.fractional(0.2),
        initialViewportOffset: ViewportOffset.fractional(0.6),
        snapViewportOffsets: [
          ViewportOffset.overshoot,
          ViewportOffset.fractional(0.6),
        ]);
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
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
