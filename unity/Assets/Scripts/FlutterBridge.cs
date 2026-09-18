// This whole file is gated behind STAR_STUDIO_FLUTTER_BRIDGE so it
// compiles to nothing -- rather than a hard compile error -- until both
// (a) the flutter_unity_widget_2 Unity package has been imported (it
// provides UnityMessageManager, which this file references) and (b)
// that symbol is added under Project Settings > Player > Scripting
// Define Symbols. See unity/README.md, "Wiring the Flutter bridge".
#if STAR_STUDIO_FLUTTER_BRIDGE
using UnityEngine;

namespace StarStudio
{
    /// <summary>
    /// Bridges this scene to Flutter via flutter_unity_widget_2's
    /// UnityMessageManager. Attach this to a GameObject named exactly
    /// "FlutterBridge" (StudioSceneBootstrapper does this for you); that
    /// name is what Flutter's UnityWidgetController.postMessage targets.
    ///
    /// Unity -> Flutter: BuildingInteractable's events forward here as
    /// JSON (see BridgeEvent). Flutter -> Unity: postMessage calls one of
    /// the public methods below by name, each taking a JSON string.
    /// </summary>
    public class FlutterBridge : MonoBehaviour
    {
        private UnityMessageManager _messageManager;
        private CharacterCustomization _customization;

        private void Awake()
        {
            _messageManager = GetComponent<UnityMessageManager>();
            if (_messageManager == null)
            {
                _messageManager = gameObject.AddComponent<UnityMessageManager>();
            }
        }

        private void Start()
        {
            _customization = FindObjectOfType<CharacterCustomization>();
            BuildingInteractable.BuildingInteracted += OnBuildingInteracted;
        }

        private void OnDestroy()
        {
            BuildingInteractable.BuildingInteracted -= OnBuildingInteracted;
        }

        // ---------------------------------------------------------------
        // Unity -> Flutter
        // ---------------------------------------------------------------

        private void OnBuildingInteracted(string id, string displayName)
        {
            SendToFlutter(new BridgeEvent { type = "buildingInteracted", id = id, name = displayName });
        }

        /// Called by StudioUIBootstrapper's Gigs/Hire/Shop buttons
        /// (action is "gigs", "hire", or "shop") so Flutter can open the
        /// real overlay for whichever building's menu is open.
        public void SendMenuAction(string buildingId, string action)
        {
            SendToFlutter(new BridgeEvent { type = "menuAction", id = buildingId, action = action });
        }

        private void SendToFlutter(BridgeEvent evt)
        {
            _messageManager.SendMessageToFlutter(JsonUtility.ToJson(evt));
        }

        // ---------------------------------------------------------------
        // Flutter -> Unity (targeted via postMessage("FlutterBridge", "<method>", json))
        // ---------------------------------------------------------------

        /// json: {"buildings":[{"id":"shoot_floor","status":"locked"}, ...]}
        /// -- statuses match BuildingStatus.name in lib/models/building.dart.
        public void SyncBuildings(string json)
        {
            var payload = JsonUtility.FromJson<BuildingSyncPayload>(json);
            if (payload?.buildings == null) return;

            foreach (var entry in payload.buildings)
            {
                if (BuildingVisualState.Registry.TryGetValue(entry.id, out var visual))
                {
                    visual.ApplyStatus(entry.status);
                }
            }
        }

        /// json: {"r":0.86,"g":0.68,"b":0.55}
        public void SetSkinTone(string json)
        {
            var color = JsonUtility.FromJson<ColorPayload>(json);
            _customization?.SetSkinTone(new Color(color.r, color.g, color.b));
        }

        /// json: {"r":0.2,"g":0.45,"b":0.5}
        public void SetOutfitColor(string json)
        {
            var color = JsonUtility.FromJson<ColorPayload>(json);
            _customization?.SetOutfitColor(new Color(color.r, color.g, color.b));
        }

        /// json: {"shape":"none"|"sphere"|"cube"|"capsule"}
        public void SetAccessory(string json)
        {
            var payload = JsonUtility.FromJson<AccessoryPayload>(json);
            PrimitiveType? shape = payload.shape switch
            {
                "sphere" => PrimitiveType.Sphere,
                "cube" => PrimitiveType.Cube,
                "capsule" => PrimitiveType.Capsule,
                _ => null,
            };
            _customization?.SetAccessory(shape);
        }
    }

    [System.Serializable]
    public class BridgeEvent
    {
        public string type;
        public string id;
        public string name;
        public string action;
    }

    [System.Serializable]
    public class ColorPayload
    {
        public float r;
        public float g;
        public float b;
    }

    [System.Serializable]
    public class AccessoryPayload
    {
        public string shape;
    }

    [System.Serializable]
    public class BuildingSyncEntry
    {
        public string id;
        public string status;
    }

    [System.Serializable]
    public class BuildingSyncPayload
    {
        public BuildingSyncEntry[] buildings;
    }
}
#endif
