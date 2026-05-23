import 'package:flutter/material.dart';

/// Top inset for shell tab pages that do not use [SliverAppBar].
abstract final class ShellPagePadding {
  ShellPagePadding._();

  static EdgeInsets page(BuildContext context) {
    return const EdgeInsets.fromLTRB(16, 8, 16, 16);
  }

  static EdgeInsets horizontal(BuildContext context) {
    return const EdgeInsets.symmetric(horizontal: 16);
  }
}
