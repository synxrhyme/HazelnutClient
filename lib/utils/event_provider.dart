import 'package:flutter/foundation.dart';

typedef EventCallback = void Function(dynamic data);

class EventProvider extends ChangeNotifier {
  final Map<String, List<EventCallback>> _listeners = {};

  // Registriert einen Listener für ein benanntes Event
  void on(String eventName, EventCallback callback) {
    _listeners.putIfAbsent(eventName, () => []).add(callback);
  }

  // Entfernt einen Listener
  void off(String eventName, EventCallback callback) {
    _listeners[eventName]?.remove(callback);
  }

  // Löst ein Event mit optionalem Daten-Objekt aus
  void emit(String eventName, [dynamic data]) {
    final callbacks = _listeners[eventName];
    if (callbacks == null) return;

    for (final cb in List.of(callbacks)) {
      cb(data);
    }
  }
}