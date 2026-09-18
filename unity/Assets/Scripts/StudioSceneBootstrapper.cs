using UnityEngine;

namespace StarStudio
{
    /// Builds the entire placeholder scene at runtime -- ground, a
    /// capsule character, cube buildings, and the camera rig -- from
    /// pure code, so no hand-authored .unity scene is needed. Create a
    /// new empty scene, add one empty GameObject, attach this script,
    /// and press Play. Swap the primitives for real meshes later without
    /// touching this wiring -- see unity/README.md.
    public class StudioSceneBootstrapper : MonoBehaviour
    {
        [Header("Character")]
        public Color defaultSkinTone = new Color(0.86f, 0.68f, 0.55f);
        public Color defaultOutfitColor = new Color(0.2f, 0.45f, 0.5f);

        private void Awake()
        {
            BuildGround();
            Transform character = BuildCharacter();
            BuildCameraRig(character);
            BuildAllBuildings();

            var ui = gameObject.AddComponent<StudioUIBootstrapper>();
            ui.Initialize(character.GetComponent<CharacterCustomization>());
        }

        private void BuildGround()
        {
            var ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.name = "Ground";
            ground.transform.position = Vector3.zero;
            ground.transform.localScale = new Vector3(10f, 1f, 10f); // A 10x10 Plane primitive -> 100x100 units.
            ground.GetComponent<Renderer>().material.color = new Color(0.29f, 0.24f, 0.19f);
        }

        private Transform BuildCharacter()
        {
            var character = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            character.name = "PlayerCharacter";
            character.tag = "Player";
            character.transform.position = new Vector3(0f, 1f, -8f);

            // CharacterController supplies its own capsule-shaped
            // collision, so the primitive's default CapsuleCollider
            // would just be a redundant, unsynced second collider.
            Destroy(character.GetComponent<CapsuleCollider>());
            var controller = character.AddComponent<CharacterController>();
            controller.height = 2f;
            controller.radius = 0.4f;
            controller.center = new Vector3(0f, 1f, 0f);

            character.AddComponent<ThirdPersonController>();

            var bodyRenderer = character.GetComponent<Renderer>();
            bodyRenderer.material.color = defaultSkinTone;

            // A thin band around the capsule's waist stands in for an
            // "outfit" layer until real clothing meshes exist.
            var outfit = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            outfit.name = "OutfitBand";
            outfit.transform.SetParent(character.transform, false);
            outfit.transform.localPosition = new Vector3(0f, 0.1f, 0f);
            outfit.transform.localScale = new Vector3(0.55f, 0.35f, 0.55f);
            Destroy(outfit.GetComponent<Collider>());
            var outfitRenderer = outfit.GetComponent<Renderer>();
            outfitRenderer.material.color = defaultOutfitColor;

            var accessoryAnchor = new GameObject("AccessoryAnchor").transform;
            accessoryAnchor.SetParent(character.transform, false);
            accessoryAnchor.localPosition = new Vector3(0f, 1.05f, 0f);

            var customization = character.AddComponent<CharacterCustomization>();
            customization.bodyRenderer = bodyRenderer;
            customization.outfitRenderer = outfitRenderer;
            customization.accessoryAnchor = accessoryAnchor;

            return character.transform;
        }

        private void BuildCameraRig(Transform target)
        {
            var cameraObject = new GameObject("StudioCamera");
            cameraObject.tag = "MainCamera";
            cameraObject.AddComponent<Camera>();
            cameraObject.AddComponent<AudioListener>();
            var rig = cameraObject.AddComponent<StudioCameraRig>();
            rig.target = target;
        }

        private void BuildAllBuildings()
        {
            foreach (var info in StudioBuildingData.Buildings)
            {
                BuildBuilding(info);
            }
        }

        /// Each building is a root transform (unscaled, so child sizes
        /// are never distorted by it) holding a scaled visual cube --
        /// whose own default BoxCollider is the solid wall players walk
        /// into -- plus a separate, explicitly-sized trigger zone for
        /// the "in range, press E" interaction.
        private void BuildBuilding(BuildingSpawnInfo info)
        {
            var root = new GameObject(info.displayName);
            root.transform.position = info.position;

            var visual = GameObject.CreatePrimitive(PrimitiveType.Cube);
            visual.name = "Visual";
            visual.transform.SetParent(root.transform, false);
            visual.transform.localPosition = new Vector3(0f, info.size.y / 2f, 0f);
            visual.transform.localScale = info.size;
            visual.GetComponent<Renderer>().material.color = info.color;

            var triggerZone = new GameObject("Trigger");
            triggerZone.transform.SetParent(root.transform, false);
            triggerZone.transform.localPosition = new Vector3(0f, info.size.y / 2f, 0f);
            var triggerCollider = triggerZone.AddComponent<BoxCollider>();
            triggerCollider.isTrigger = true;
            triggerCollider.size = info.size + Vector3.one * 1.6f; // Padding, independent of the visual's own scale.

            var interactable = triggerZone.AddComponent<BuildingInteractable>();
            interactable.buildingId = info.id;
            interactable.displayName = info.displayName;
        }
    }
}
