using UnityEngine;

namespace StarStudio
{
    /// Placeholder customization hooks for the capsule stand-in ("uska
    /// dress, accessories, looks, sab change kr sakte"). The method
    /// signatures here are the real API surface: once a rigged character
    /// with real clothing meshes replaces the capsule, only the *bodies*
    /// of these methods change (swap meshes/materials instead of tinting
    /// a primitive) -- calling code (UI, Flutter bridge) never has to.
    public class CharacterCustomization : MonoBehaviour
    {
        public Renderer bodyRenderer;
        public Renderer outfitRenderer;
        public Transform accessoryAnchor;

        private GameObject _currentAccessory;

        public void SetSkinTone(Color color)
        {
            if (bodyRenderer != null)
            {
                bodyRenderer.material.color = color;
            }
        }

        public void SetOutfitColor(Color color)
        {
            if (outfitRenderer != null)
            {
                outfitRenderer.material.color = color;
            }
        }

        /// Pass null to remove the accessory. A real asset pipeline would
        /// swap this for equipping a prefab by id instead of a primitive
        /// shape.
        public void SetAccessory(PrimitiveType? shape)
        {
            if (_currentAccessory != null)
            {
                Destroy(_currentAccessory);
                _currentAccessory = null;
            }
            if (shape.HasValue && accessoryAnchor != null)
            {
                _currentAccessory = GameObject.CreatePrimitive(shape.Value);
                _currentAccessory.name = "Accessory";
                _currentAccessory.transform.SetParent(accessoryAnchor, false);
                _currentAccessory.transform.localScale = Vector3.one * 0.3f;
                _currentAccessory.transform.localPosition = Vector3.zero;
                Destroy(_currentAccessory.GetComponent<Collider>());
            }
        }
    }
}
