import 'package:example/src/common.dart';
import 'package:exprollable_page_view/exprollable_page_view.dart';
import 'package:flutter/material.dart';

class AnimationExample extends StatefulWidget {
  const AnimationExample({super.key});

  @override
  State<AnimationExample> createState() => _AnimationExampleState();
}

class _AnimationExampleState extends State<AnimationExample> {
  late final ExprollablePageController controller;
  bool isPageShrunk = true;

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
    return Scaffold(
      bottomNavigationBar: const ExampleBottomAppBar(),
      body: ExprollablePageView(
        controller: controller,
        onViewportChanged: (metrics) {
          if (metrics.isPageShrunk != isPageShrunk) {
            setState(() {
              isPageShrunk = metrics.isPageShrunk;
            });
          }
        },
        itemBuilder: (context, page) {
          return ExampleListView(
            controller: PageContentScrollController.of(context),
            page: page,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.animateViewportInsetTo(
            isPageShrunk ? ViewportInset.expanded : ViewportInset.shrunk,
            curve: Curves.easeInOutCubic,
            duration: const Duration(milliseconds: 600),
          );
        },
        label: Text(isPageShrunk ? 'Expand' : 'Shrink'),
      ),
    );
  }
}
