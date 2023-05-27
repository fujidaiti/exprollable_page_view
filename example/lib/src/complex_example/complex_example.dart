import 'package:example/src/complex_example/album_list.dart';
import 'package:example/src/complex_example/nested_navigator.dart';
import 'package:example/src/common.dart';
import 'package:flutter/material.dart';

class ComplexExample extends StatelessWidget {
  const ComplexExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      bottomNavigationBar: ExampleBottomAppBar(),
      body: NestedNavigator(child: AlbumList()),
    );
  }
}
