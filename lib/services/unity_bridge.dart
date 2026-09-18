import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_unity_widget_2/flutter_unity_widget_2.dart';

/// Typed events Unity reports back (design doc §7: "Unity requests
/// mutations through Flutter and re-renders from the returned
/// snapshot" -- Unity never decides game state on its own, it just
/// tells Flutter what the player did).
sealed class UnityBridgeEvent {
  const UnityBridgeEvent();
}

class UnityBuildingInteractedEvent extends UnityBridgeEvent {
  final String buildingId;
  final String displayName;
  const UnityBuildingInteractedEvent(this.buildingId, this.displayName);
}

class UnityMenuActionEvent extends UnityBridgeEvent {
  final String buildingId;
  final String action; // "gigs" | "hire" | "shop"
  const UnityMenuActionEvent(this.buildingId, this.action);
}

/// Wraps a [UnityWidgetController] with the message protocol shared
/// with unity/Assets/Scripts/FlutterBridge.cs -- every `send*`/`sync*`
/// method here has a same-named public method on that C# script taking
/// the same JSON shape (documented on each method there).
///
/// Unverified: flutter_unity_widget_2 needs a Unity-exported native
/// module this repo doesn't have, so this has never actually talked to
/// a running Unity player. See unity/README.md.
class UnityBridge {
  UnityWidgetController? _controller;

  static const _gameObjectName = 'FlutterBridge';

  void attach(UnityWidgetController controller) {
    _controller = controller;
  }

  void detach() {
    _controller = null;
  }

  bool get isReady => _controller != null;

  /// [buildingIdToStatus] values are BuildingStatus.name strings (e.g.
  /// "locked", "buildable", "idle") -- see lib/models/building.dart.
  void syncBuildings(Map<String, String> buildingIdToStatus) {
    final payload = jsonEncode({
      'buildings': buildingIdToStatus.entries
          .map((entry) => {'id': entry.key, 'status': entry.value})
          .toList(),
    });
    _send('SyncBuildings', payload);
  }

  void setSkinTone(Color color) => _send('SetSkinTone', _colorJson(color));

  void setOutfitColor(Color color) => _send('SetOutfitColor', _colorJson(color));

  /// [shape] is one of "none", "sphere", "cube", "capsule".
  void setAccessory(String shape) => _send('SetAccessory', jsonEncode({'shape': shape}));

  String _colorJson(Color color) {
    // int (0-255) channels rather than the newer .r/.g/.b float
    // accessors, which don't exist before Flutter 3.27 -- see the same
    // tradeoff noted on withOpacity elsewhere in this app.
    return jsonEncode({
      'r': color.red / 255,
      'g': color.green / 255,
      'b': color.blue / 255,
    });
  }

  void _send(String method, String jsonMessage) {
    _controller?.postMessage(_gameObjectName, method, jsonMessage);
  }

  /// Parses a raw onUnityMessage payload into a typed event, or null if
  /// it isn't recognized (e.g. malformed JSON, or a message type this
  /// app doesn't handle yet).
  static UnityBridgeEvent? parseEvent(dynamic rawMessage) {
    if (rawMessage is! String) return null;

    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(rawMessage);
      if (decoded is! Map<String, dynamic>) return null;
      json = decoded;
    } catch (_) {
      return null;
    }

    final id = json['id'];
    if (id is! String) return null;

    switch (json['type']) {
      case 'buildingInteracted':
        final name = json['name'];
        if (name is! String) return null;
        return UnityBuildingInteractedEvent(id, name);
      case 'menuAction':
        final action = json['action'];
        if (action is! String) return null;
        return UnityMenuActionEvent(id, action);
      default:
        return null;
    }
  }
}
