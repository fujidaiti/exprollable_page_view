import 'package:example/src/common.dart';
import 'package:exprollable_page_view/exprollable_page_view.dart';
import 'package:flutter/material.dart';

class GutterExample extends StatelessWidget {
  const GutterExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const ExampleBottomAppBar(),
      body: ExprollablePageView(
        itemCount: 5,
        itemBuilder: (context, page) {
          return PageGutter(
            gutterWidth: 12,
            child: ExampleListView(
              controller: PageContentScrollController.of(context),
              page: page,
            ),
          );
        },
      ),
    );
  }
}
