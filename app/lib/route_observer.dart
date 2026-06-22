import 'package:flutter/material.dart';

class GlobalRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  PageRoute? _currentRoute;
  PageRoute? get currentRoute => _currentRoute;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _currentRoute = route;
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute) {
      _currentRoute = previousRoute;
    } else {
      _currentRoute = null;
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      _currentRoute = newRoute;
    }
  }
}