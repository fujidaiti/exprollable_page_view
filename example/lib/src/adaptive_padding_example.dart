import 'package:example/src/common.dart';
import 'package:exprollable_page_view/exprollable_page_view.dart';
import 'package:flutter/material.dart';

class AdaptivePaddingExample extends StatefulWidget {
  const AdaptivePaddingExample({super.key});

  @override
  State<AdaptivePaddingExample> createState() =>
      _AdaptivePaddingExampleState();
}

class _AdaptivePaddingExampleState extends State<AdaptivePaddingExample> {
  late final ExprollablePageController controller;

  @override
  void initState() {
    super.initState();
    controller = ExprollablePageController(overshootEffect: true);
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
        itemBuilder: buildPage,
      ),
    );
  }
}

Widget buildPage(BuildContext context, int page) {
  const headerHeight = 68.0;
  return Stack(
    children: [
      ExampleListView(
        controller: PageContentScrollController.of(context),
        page: page,
        padding: const EdgeInsets.only(top: headerHeight),
      ),
      Positioned(
        top: 0.0,
        child: buildHeader(headerHeight),
      ),
    ],
  );
}

Widget buildHeader(double height) {
  return Container(
    color: Colors.lightBlue,
    child: AdaptivePagePadding(
      child: SizedBox(
        height: height,
        child: const Placeholder(),
      ),
    ),
  );
}
