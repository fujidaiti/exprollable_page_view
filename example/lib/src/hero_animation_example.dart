import 'package:example/src/common.dart';
import 'package:exprollable_page_view/exprollable_page_view.dart';
import 'package:flutter/material.dart';

const colors = [
  Colors.red,
  Colors.green,
  Colors.blue,
  Colors.amber,
  Colors.black,
  Colors.cyan,
  Colors.blueGrey,
  Colors.deepOrange,
  Colors.purple,
  Colors.indigo,
  Colors.lime,
  ...Colors.accents,
];

class HeroAnimationExample extends StatelessWidget {
  const HeroAnimationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const ExampleBottomAppBar(),
      body: GridView.builder(
        itemCount: colors.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemBuilder: (_, index) => Center(
          child: HeroFlutterLogo(
            color: colors[index],
            tag: index,
            size: 100,
            onTap: () => showDetailsPage(context, index),
          ),
        ),
      ),
    );
  }
}

void showDetailsPage(BuildContext context, int page) =>
    Navigator.of(context, rootNavigator: true).push(
      // You can use `ModalExprollableRouteBuilder` like regular `PageRouteBuilder`.
      // See [https://docs.flutter.dev/ui/animations/hero-animations#radial-hero-animations].
      ModalExprollableRouteBuilder(
        // This is the only required paramter.
        pageBuilder: (context, _, __) {
          return PageConfiguration(
            initialPage: page,
            viewportConfiguration: ViewportConfiguration(
              extendPage: true,
              overshootEffect: true,
            ),
            child: ExprollablePageView(
              itemCount: colors.length,
              itemBuilder: (context, page) {
                return PageGutter(
                  gutterWidth: 12,
                  child: DetailsPage(page: page),
                );
              },
            ),
          );
        },
        // Increase the transition durations and take a closer look at what's going on!
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        // The next two lines are not required, but are recommended for better performance.
        backgroundColor: Colors.white,
        opaque: true,
      ),
    );

class DetailsPage extends StatelessWidget {
  const DetailsPage({
    super.key,
    required this.page,
  });

  final int page;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        controller: PageContentScrollController.of(context),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: HeroFlutterLogo(
            color: colors[page],
            tag: page,
            size: 400,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

class HeroFlutterLogo extends StatelessWidget {
  const HeroFlutterLogo({
    super.key,
    required this.color,
    required this.tag,
    required this.size,
    required this.onTap,
  });

  final int tag;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: Material(
        color: color,
        child: InkWell(
          onTap: onTap,
          child: FlutterLogo(
            size: size,
          ),
        ),
      ),
    );
  }
}
