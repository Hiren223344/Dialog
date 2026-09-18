using System.Collections.Generic;
using UnityEngine;

namespace StarStudio
{
    /// Applies a building's real game status (synced from Flutter's
    /// GameState -- design doc §7: "Unity requests mutations through
    /// Flutter and re-renders from the returned snapshot") to the
    /// placeholder cube: dims and disables interaction when locked,
    /// otherwise shows its normal color. Self-registers by building id
    /// so FlutterBridge can look it up without GameObject.Find.
    public class BuildingVisualState : MonoBehaviour
    {
        public static readonly Dictionary<string, BuildingVisualState> Registry = new();

        public string buildingId;
        public Renderer visualRenderer;
        public BuildingInteractable interactable;
        public Color baseColor;

        private void Awake()
        {
            Registry[buildingId] = this;
        }

        private void OnDestroy()
        {
            if (Registry.TryGetValue(buildingId, out var current) && current == this)
            {
                Registry.Remove(buildingId);
            }
        }

        public void ApplyStatus(string status)
        {
            bool locked = status == "locked";
            if (interactable != null)
            {
                interactable.enabled = !locked;
            }
            if (visualRenderer != null)
            {
                visualRenderer.material.color = locked ? Color.Lerp(baseColor, Color.gray, 0.7f) : baseColor;
            }
        }
    }
}
