import 'dart:math';

import 'package:flutter/material.dart';

class ExampleListView extends StatefulWidget {
  const ExampleListView({
    super.key,
    required this.controller,
    required this.page,
    this.padding,
  });

  final ScrollController? controller;
  final int page;
  final EdgeInsets? padding;

  @override
  State<ExampleListView> createState() => _ExampleListViewState();
}

class _ExampleListViewState extends State<ExampleListView> {
  final Color color = Color.fromARGB(
    220,
    Random().nextInt(155) + 100,
    Random().nextInt(155) + 100,
    Random().nextInt(155) + 100,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: ListView.builder(
        padding: widget.padding ?? EdgeInsets.zero,
        controller: widget.controller,
        itemCount: 50,
        itemBuilder: (_, index) {
          return ListTile(
            onTap: () => debugPrint("onTap(index=$index, page=${widget.page})"),
            title: Text("Item#$index"),
            subtitle: Text("Page#${widget.page}"),
          );
        },
      ),
    );
  }
}

class ExampleBottomAppBar extends StatelessWidget {
  const ExampleBottomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ],
      ),
    );
  }
}
