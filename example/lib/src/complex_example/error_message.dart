import 'package:flutter/material.dart';

class ErrorMessage extends StatelessWidget {
  const ErrorMessage({
    super.key,
    required this.error,
  });

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      padding: const EdgeInsets.all(18),
      child: Center(
        child: Text(
          error.toString(),
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: Colors.amber),
        ),
      ),
    );
  }
}
