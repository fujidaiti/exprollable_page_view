import 'package:example/src/common.dart';
import 'package:exprollable_page_view/exprollable_page_view.dart';
import 'package:flutter/material.dart';

class ModalDialogExample extends StatelessWidget {
  const ModalDialogExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const ExampleBottomAppBar(),
      body: Center(
        child: ElevatedButton(
          onPressed: () => showModalDialog(context),
          child: const Text("Press Me"),
        ),
      ),
    );
  }
}

void showModalDialog(BuildContext context) {
  showModalExprollable(
    context,
    useSafeArea: false,
    builder: (context) {
      return ExprollablePageView(
        itemCount: 5,
        itemBuilder: (context, page) {
          return ExampleListView(
            controller: PageContentScrollController.of(context),
            page: page,
          );
        },
      );
    },
  );
}
