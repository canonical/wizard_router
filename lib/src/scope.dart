import 'dart:async';

import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'settings.dart';

/// The scope of a wizard page.
///
/// Each page is enclosed by a `WizardScope` widget.
class WizardScope extends StatefulWidget {
  const WizardScope({
    super.key,
    required int index,
    Object? userData,
    required WizardController controller,
  })  : _index = index,
        _userData = userData,
        _controller = controller;

  final int _index;
  final Object? _userData;
  final WizardController _controller;

  @override
  State<WizardScope> createState() => WizardScopeState();
}

/// The state of a `WizardScope`, accessed via `Wizard.of(context)`.
class WizardScopeState extends State<WizardScope> {
  /// Arguments passed from the previous page.
  ///
  /// ```dart
  /// final something = Wizard.of(context).arguments as Something;
  /// ```
  Object? get arguments => ModalRoute.of(context)?.settings.arguments;

  void home() => widget._controller.home();

  void back<T extends Object?>({T? arguments}) =>
      widget._controller.back(arguments: arguments);

  Future<T?> next<T extends Object?>({T? arguments}) =>
      widget._controller.next(arguments: arguments);

  void replace({Object? arguments}) =>
      widget._controller.replace(arguments: arguments);

  void jump(String route, {Object? arguments}) =>
      widget._controller.jump(route, arguments: arguments);

  List<WizardRouteSettings> _getRoutes() =>
      widget._controller.flowController.state;

  /// Returns `false` if the wizard page is the first page.
  bool get hasPrevious => widget._index > 0;

  /// Returns `false` if the wizard page is the last page.
  bool get hasNext {
    if (widget._controller.routes.isEmpty) return false;
    final previous = _getRoutes().last.name!;
    final previousIndex =
        widget._controller.routes.keys.toList().indexOf(previous);
    return previousIndex < widget._controller.routes.length - 1;
  }

  Object? get routeData =>
      widget._controller.routes[widget._controller.currentRoute]!.userData;
  Object? get wizardData => widget._userData;

  @override
  Widget build(BuildContext context) => Builder(
      builder:
          widget._controller.routes[widget._controller.currentRoute]!.builder);
}
