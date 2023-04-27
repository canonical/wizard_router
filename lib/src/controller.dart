import 'dart:async';

import 'package:flow_builder/flow_builder.dart';
import 'package:flutter/material.dart';

import 'route.dart';
import 'settings.dart';

/// Allows widgets such as the AppBar to invoke functionality on the Wizard
/// This is useful for widgets that are defined above the Wizard, such as a mobile
/// app's AppBar.
class WizardController extends ChangeNotifier {
  WizardController({required this.routes, this.initialRoute})
      : currentRoute = initialRoute ?? routes.keys.first {
    flowController = FlowController([WizardRouteSettings(name: currentRoute)]);
    flowController.addListener(notifyListeners);
  }
  String? initialRoute;
  String currentRoute;
  final Map<String, WizardRoute> routes;
  late final FlowController<List<WizardRouteSettings>> flowController;

  List<WizardRouteSettings> _getRoutes() => flowController.state;

  void _updateRoutes(
    List<WizardRouteSettings> Function(List<WizardRouteSettings>) callback,
  ) {
    flowController.update(callback);
  }

  @override
  void dispose() {
    flowController.removeListener(notifyListeners);
    flowController.dispose();
    super.dispose();
  }

  /// Requests the wizard to show the first page.
  ///
  /// ```dart
  /// onPressed: Wizard.of(context).home
  /// ```
  void home() {
    final stack = _getRoutes();
    assert(stack.length > 1,
        '`Wizard.home()` called from the first route ${stack.last.name}');

    _updateRoutes((state) {
      final copy = List<WizardRouteSettings>.of(state);
      final newStack = copy..replaceRange(1, stack.length, []);
      currentRoute = newStack.last.name!;
      return newStack;
    });
  }

  /// Requests the wizard to show the previous page. Optionally, `result` can be
  /// returned to the previous page.
  ///
  /// ```dart
  /// onPressed: Wizard.of(context).back
  /// ```
  void back<T extends Object?>({T? arguments}) {
    final stack = _getRoutes();
    assert(stack.length > 1,
        '`Wizard.back()` called from the first route ${stack.last.name}');

    // go back to a specific route, or pick the previous route on the list
    final previous = routes[currentRoute]!.onBack?.call(stack.last);
    if (previous != null) {
      assert(routes.keys.contains(previous),
          '`Wizard.routes` is missing route \'$previous\'.');
    }

    final start = previous != null
        ? stack.lastIndexWhere((settings) => settings.name == previous) + 1
        : stack.length - 1;

    _updateRoutes((state) {
      final copy = List<WizardRouteSettings>.of(state);
      copy[start].completer.complete(arguments);
      final newStack = copy..replaceRange(start, stack.length, []);
      currentRoute = newStack.last.name!;
      return newStack;
    });
  }

  /// Requests the wizard to show the next page. Optionally, `arguments` can be
  /// passed to the next page.
  ///
  /// ```dart
  /// onPressed: Wizard.of(context).next
  /// ```
  Future<T?> next<T extends Object?>({T? arguments}) {
    final next = _getNextRoute<T>(arguments, routes[currentRoute]!.onNext);

    _updateRoutes((state) {
      final copy = List<WizardRouteSettings>.of(state);
      final newStack = copy..add(next);
      currentRoute = newStack.last.name!;
      return newStack;
    });

    return next.completer.future;
  }

  WizardRouteSettings<T?> _getNextRoute<T extends Object?>(
    T? arguments,
    WizardRouteCallback? advance,
  ) {
    final stack = _getRoutes();
    assert(stack.isNotEmpty, stack.length.toString());

    final previous = WizardRouteSettings(
      name: stack.last.name,
      arguments: arguments,
    );

    // advance to a specific route
    String? onNext() => advance?.call(previous);

    // pick the next route on the list
    String nextRoute() {
      final index = routes.keys.toList().indexOf(previous.name!);
      assert(index < routes.length - 1,
          '`Wizard.next()` called from the last route ${previous.name}.');
      return routes.keys.toList()[index + 1];
    }

    final name = onNext() ?? nextRoute();
    assert(routes.keys.contains(name),
        '`Wizard.routes` is missing route \'$name\'.');

    return WizardRouteSettings<T?>(name: name, arguments: arguments);
  }

  /// Requests the wizard to replace the current page with the next one.
  /// Optionally, `arguments` can be passed to the next page.
  ///
  /// ```dart
  /// onPressed: () => Wizard.of(context).replace(arguments: something),
  /// ```
  void replace({Object? arguments}) async {
    final next = _getNextRoute(arguments, routes[currentRoute]!.onReplace);

    _updateRoutes((state) {
      final copy = List<WizardRouteSettings>.of(state);
      copy[copy.length - 1] = next;
      currentRoute = copy.last.name!;
      return copy;
    });
  }

  /// Requests the wizard to jump to a specific page. Optionally, `arguments`
  /// can be passed to the page.
  void jump(String route, {Object? arguments}) async {
    assert(routes.keys.contains(route),
        '`Wizard.jump()` called with an unknown route $route.');
    final settings = WizardRouteSettings(name: route, arguments: arguments);

    _updateRoutes((state) {
      final copy = List<WizardRouteSettings>.of(state);
      final newStack = copy..add(settings);
      currentRoute = newStack.last.name!;
      return newStack;
    });
  }
}
