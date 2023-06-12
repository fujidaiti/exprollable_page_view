import 'package:example/src/common.dart';
import 'package:exprollable_page_view/exprollable_page_view.dart';
import 'package:flutter/material.dart';

class ModalDialogExample extends StatefulWidget {
  const ModalDialogExample({super.key});

  @override
  State<ModalDialogExample> createState() => _ModalDialogExampleState();
}

class _ModalDialogExampleState extends State<ModalDialogExample> {
  bool enableOvershootEffect = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const ExampleBottomAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _MyDialog.show(
                context: context,
                enableOvershootEffect: enableOvershootEffect,
              ),
              child: const Text("Click on me!"),
            ),
            SizedBox(height: 82),
            Text(
              'Overshoot Effect is ${enableOvershootEffect ? 'enabled' : 'disabled'}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Switch(
              value: enableOvershootEffect,
              onChanged: (enabled) => setState(() {
                enableOvershootEffect = enabled;
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyDialog extends StatefulWidget {
  const _MyDialog(this.enableOvershootEffect);

  final bool enableOvershootEffect;

  @override
  State<_MyDialog> createState() => __MyDialogState();

  static void show({
    required BuildContext context,
    required bool enableOvershootEffect,
  }) =>
      Navigator.of(context).push(
        ModalExprollableRouteBuilder(
          pageBuilder: (context, _, __) => _MyDialog(enableOvershootEffect),
        ),
      );
}

class __MyDialogState extends State<_MyDialog> {
  late final ExprollablePageController controller;

  @override
  void initState() {
    super.initState();
    controller = ExprollablePageController(
      viewportConfiguration: ViewportConfiguration(
        extendPage: true,
        overshootEffect: widget.enableOvershootEffect,
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
    return ExprollablePageView(
      controller: controller,
      itemCount: 5,
      itemBuilder: (context, page) {
        return ExampleListView(
          controller: PageContentScrollController.of(context),
          page: page,
        );
      },
    );
  }
}
