import 'package:exprollable_page_view/exprollable_page_view.dart';
import 'package:flutter/material.dart';

class SlideInOutAppBar extends StatefulWidget {
  const SlideInOutAppBar({
    super.key,
    required this.title,
    required this.thresholdScrollOffset,
  });

  final String title;
  final double thresholdScrollOffset;

  @override
  State<SlideInOutAppBar> createState() => _SlideInOutAppBarState();
}

class _SlideInOutAppBarState extends State<SlideInOutAppBar> {
  bool isShown = false;
  ScrollController? controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = PageContentScrollController.of(context);
    assert(
      newController != null,
      '$SlideInOutAppBar can only be used in a subtree of $ExprollablePageView.',
    );
    if (newController != controller) {
      controller?.removeListener(invalidateState);
      controller = newController!..addListener(invalidateState);
      correctState();
    }
  }

  @override
  void dispose() {
    super.dispose();
    controller?.removeListener(invalidateState);
  }

  void invalidateState() {
    final isShown = this.isShown;
    correctState();
    if (isShown != this.isShown) setState(() {});
  }

  void correctState() {
    isShown = controller!.offset > widget.thresholdScrollOffset;
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      elevation: isShown ? null : 0,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.grey[200],
      title: Text(
        widget.title,
        style: const TextStyle(color: Colors.black),
      ),
    );

    final appBarHeight =
        appBar.preferredSize.height + MediaQuery.of(context).padding.top;

    return AnimatedPositioned(
      top: isShown ? 0.0 : -1 * (appBarHeight),
      left: 0.0,
      right: 0.0,
      duration: const Duration(milliseconds: 150),
      child: AdaptivePagePadding(
        useSafeArea: false,
        child: appBar,
      ),
    );
  }
}
