import 'package:example/src/common.dart';
import 'package:exprollable_page_view/exprollable_page_view.dart';
import 'package:flutter/material.dart';

class ViewportConfigurationExample extends StatefulWidget {
  const ViewportConfigurationExample({super.key});

  @override
  State<ViewportConfigurationExample> createState() =>
      _ViewportConfigurationExampleState();
}

class _ViewportConfigurationExampleState
    extends State<ViewportConfigurationExample> {
  late final ExprollablePageController controller;

  @override
  void initState() {
    super.initState();
    const fullscreenInset = ViewportInset.fixed(0);
    const expandedSheetInset = ViewportInset.fractional(0.2);
    const sheetInset = ViewportInset.fractional(0.5);
    const peekInset = ViewportInset.fractional(0.9);
    controller = ExprollablePageController(
      viewportConfiguration: ViewportConfiguration.raw(
        minInset: fullscreenInset,
        expandedInset: expandedSheetInset,
        shrunkInset: sheetInset,
        maxInset: peekInset,
        initialInset: peekInset,
        snapInsets: [
          fullscreenInset,
          expandedSheetInset,
          sheetInset,
          peekInset,
        ],
      ),
    );
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
