using UnityEngine;

namespace StarStudio
{
    /// A building's interaction zone (design doc §7: buildings stay
    /// tappable/enterable objects that open Flutter overlay panels for
    /// gigs/hiring/shopping -- never full walkable 3D interiors). Detects
    /// the player capsule and reports enter/exit/interact via static
    /// events; for now that just logs, since the Flutter embedding
    /// package hasn't been chosen yet. Once it is, a bridge script
    /// subscribes to these same events and forwards them to Flutter
    /// instead of (or alongside) the Debug.Log calls.
    [RequireComponent(typeof(BoxCollider))]
    public class BuildingInteractable : MonoBehaviour
    {
        public string buildingId;
        public string displayName;
        public KeyCode interactKey = KeyCode.E;

        /// (buildingId, displayName) -- the display name rides along so
        /// UI code (StudioUIBootstrapper) doesn't need its own lookup
        /// table just to show "Press E to enter <name>".
        public static event System.Action<string, string> BuildingEntered;
        public static event System.Action<string> BuildingExited;
        public static event System.Action<string, string> BuildingInteracted;

        private bool _playerInRange;

        private void Awake()
        {
            GetComponent<BoxCollider>().isTrigger = true;
        }

        private void OnTriggerEnter(Collider other)
        {
            if (!other.CompareTag("Player")) return;
            _playerInRange = true;
            BuildingEntered?.Invoke(buildingId, displayName);
            Debug.Log($"[StarStudio] In range of {displayName} ({buildingId}) -- press {interactKey} to enter.");
        }

        private void OnTriggerExit(Collider other)
        {
            if (!other.CompareTag("Player")) return;
            _playerInRange = false;
            BuildingExited?.Invoke(buildingId);
        }

        private void Update()
        {
            if (_playerInRange && Input.GetKeyDown(interactKey))
            {
                BuildingInteracted?.Invoke(buildingId, displayName);
                Debug.Log($"[StarStudio] Interacted with {displayName} ({buildingId})");
            }
        }
    }
}
