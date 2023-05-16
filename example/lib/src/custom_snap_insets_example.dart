import 'package:example/src/common.dart';
import 'package:exprollable_page_view/exprollable_page_view.dart';
import 'package:flutter/material.dart';

class CustomSnapInsetsExample extends StatefulWidget {
  const CustomSnapInsetsExample({super.key});

  @override
  State<CustomSnapInsetsExample> createState() =>
      _CustomSnapInsetsExampleState();
}

class _CustomSnapInsetsExampleState extends State<CustomSnapInsetsExample> {
  late final ExprollablePageController controller;

  @override
  void initState() {
    super.initState();
    controller = ExprollablePageController(
      viewportConfiguration: ViewportConfiguration(
        extraSnapInsets: [
          ViewportInset.fractional(0.5),
        ],
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
    final mainContent = ListView.builder(
      itemBuilder: (_, index) {
        return ListTile(
          onTap: () {},
          title: Text("Item#$index"),
        );
      },
    );

    final pageView = ExprollablePageView(
      controller: controller,
      itemCount: 5,
      itemBuilder: (context, page) {
        return ExampleListView(
          controller: PageContentScrollController.of(context),
          page: page,
        );
      },
    );

    return Scaffold(
      bottomNavigationBar: const ExampleBottomAppBar(),
      body: Stack(
        children: [mainContent, pageView],
      ),
    );
  }
}
