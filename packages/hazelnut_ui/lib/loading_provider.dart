import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

class LoadingService extends ChangeNotifier {
  bool _loading = false;

  bool get isLoading => _loading;

  void show() {
    _loading = true;
    notifyListeners();
  }

  void hide() {
    _loading = false;
    notifyListeners();
  }
}

final loadingServiceProvider = ChangeNotifierProvider<LoadingService>((ref) {
  return LoadingService();
});