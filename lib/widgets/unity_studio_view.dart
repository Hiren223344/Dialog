import 'package:flutter/material.dart';
import 'package:flutter_unity_widget_2/flutter_unity_widget_2.dart';

import '../services/unity_bridge.dart';

/// Hosts the embedded Unity studio scene full-screen (design doc: "an
/// embedded Unity 3D runtime hosted full-screen inside the Flutter
/// app"). Unverified -- see unity/README.md and [UnityBridge]'s doc
/// comment for why this can't be run from the environment that wrote
/// it. Gated behind `kUnity3DStudioEnabled` (see
/// lib/config/feature_flags.dart) so the working 2D lot stays the
/// default until this has actually been tried on a device.
class UnityStudioView extends StatefulWidget {
  final UnityBridge bridge;
  final void Function(UnityBridgeEvent event) onEvent;

  const UnityStudioView({super.key, required this.bridge, required this.onEvent});

  @override
  State<UnityStudioView> createState() => _UnityStudioViewState();
}

class _UnityStudioViewState extends State<UnityStudioView> {
  @override
  void dispose() {
    widget.bridge.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UnityWidget(
      onUnityCreated: widget.bridge.attach,
      onUnityMessage: (message) {
        final event = UnityBridge.parseEvent(message);
        if (event != null) {
          widget.onEvent(event);
        }
      },
    );
  }
}
