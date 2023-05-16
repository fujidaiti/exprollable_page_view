import 'package:example/src/adaptive_padding_example.dart';
import 'package:example/src/complex_example/complex_example.dart';
import 'package:example/src/custom_snap_insets_example.dart';
import 'package:example/src/gutter_example.dart';
import 'package:example/src/modal_dialog_example.dart';
import 'package:example/src/overshoot_effect_example.dart';
import 'package:example/src/simple_example.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: Exampbles()));
}

class Exampbles extends StatelessWidget {
  const Exampbles({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExprollablePageView Examples',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const Scaffold(
        body: Home(),
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    void pushRoute(Widget widget) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => widget));

    return ListView(
      children: [
        ListTile(
          title: const Text("Simple Example"),
          onTap: () => pushRoute(const SimpleExample()),
        ),
        ListTile(
          title: const Text("Overshoot Effect Example"),
          onTap: () => pushRoute(const OvershootEffectExample()),
        ),
        ListTile(
          title: const Text("Custom Snap Insets Example"),
          onTap: () => pushRoute(const CustomSnapInsetsExample()),
        ),
        ListTile(
          title: const Text("Gutter Example"),
          onTap: () => pushRoute(const GutterExample()),
        ),
        ListTile(
          title: const Text("Adaptive Padding Example"),
          onTap: () => pushRoute(const AdaptivePaddingExample()),
        ),
        ListTile(
          title: const Text("Modal Dialog Example"),
          onTap: () => pushRoute(const ModalDialogExample()),
        ),
        ListTile(
          title: const Text("Complex Example"),
          onTap: () => pushRoute(const ComplexExample()),
        ),
      ],
    );
  }
}
