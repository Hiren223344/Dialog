using UnityEngine;
using UnityEngine.Events;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace StarStudio
{
    /// Builds the on-screen UI at runtime, same as
    /// StudioSceneBootstrapper builds the 3D scene: an "in range" prompt,
    /// a building menu (Gigs/Hire/Shop placeholders -- these don't do
    /// anything real yet, since there's no Flutter bridge), and a
    /// character customization panel wired to CharacterCustomization.
    /// No prefabs/scene assets means nothing here can be a broken
    /// reference from a missing editor step.
    public class StudioUIBootstrapper : MonoBehaviour
    {
        private static readonly Color[] SkinTones =
        {
            new Color(0.94f, 0.80f, 0.68f),
            new Color(0.86f, 0.68f, 0.55f),
            new Color(0.65f, 0.48f, 0.36f),
            new Color(0.40f, 0.28f, 0.20f),
        };

        private static readonly Color[] OutfitColors =
        {
            new Color(0.2f, 0.45f, 0.5f),
            new Color(0.75f, 0.2f, 0.25f),
            new Color(0.85f, 0.65f, 0.15f),
            new Color(0.25f, 0.25f, 0.28f),
        };

        private static readonly PrimitiveType?[] AccessoryOptions =
        {
            null, PrimitiveType.Sphere, PrimitiveType.Cube, PrimitiveType.Capsule,
        };

        private CharacterCustomization _customization;
        private int _accessoryIndex;

        private GameObject _promptRoot;
        private Text _promptText;
        private GameObject _menuPanel;
        private Text _menuTitle;
        private Text _statusText;
        private string _currentBuildingId;

        public void Initialize(CharacterCustomization customization)
        {
            _customization = customization;

            EnsureEventSystem();
            Canvas canvas = BuildCanvas();
            BuildInteractionPrompt(canvas);
            BuildBuildingMenu(canvas);
            BuildCustomizationPanel(canvas);

            BuildingInteractable.BuildingEntered += OnBuildingEntered;
            BuildingInteractable.BuildingExited += OnBuildingExited;
            BuildingInteractable.BuildingInteracted += OnBuildingInteracted;
        }

        private void OnDestroy()
        {
            BuildingInteractable.BuildingEntered -= OnBuildingEntered;
            BuildingInteractable.BuildingExited -= OnBuildingExited;
            BuildingInteractable.BuildingInteracted -= OnBuildingInteracted;
        }

        private static void EnsureEventSystem()
        {
            if (FindObjectOfType<EventSystem>() != null) return;
            var eventSystemObject = new GameObject("EventSystem");
            eventSystemObject.AddComponent<EventSystem>();
            eventSystemObject.AddComponent<StandaloneInputModule>();
        }

        /// Unity 2022.1 renamed the built-in "Arial.ttf" resource to
        /// "LegacyRuntime.ttf"; trying both keeps this working on either
        /// side of that change instead of silently rendering blank text.
        private static Font GetDefaultFont()
        {
            Font font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            if (font == null)
            {
                font = Resources.GetBuiltinResource<Font>("Arial.ttf");
            }
            return font;
        }

        private static Canvas BuildCanvas()
        {
            var canvasObject = new GameObject("StudioCanvas");
            var canvas = canvasObject.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;

            var scaler = canvasObject.AddComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1280f, 720f);

            canvasObject.AddComponent<GraphicRaycaster>();
            return canvas;
        }

        private static RectTransform CreatePanel(Transform parent, string name, Color color)
        {
            var panel = new GameObject(name);
            panel.transform.SetParent(parent, false);
            var rect = panel.AddComponent<RectTransform>();
            // A sane baseline (positioned by anchoredPosition relative to
            // the parent's center) -- callers override anchorMin/Max/
            // pivot explicitly wherever they need a different anchor
            // (e.g. stretched or corner-pinned), so nothing here depends
            // on RectTransform's own implicit defaults.
            rect.anchorMin = new Vector2(0.5f, 0.5f);
            rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = Vector2.zero;
            var image = panel.AddComponent<Image>();
            image.color = color;
            return rect;
        }

        private static Text CreateLabel(Transform parent, string text, int fontSize, TextAnchor alignment)
        {
            var textObject = new GameObject("Text");
            textObject.transform.SetParent(parent, false);
            var rect = textObject.AddComponent<RectTransform>();
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;

            var label = textObject.AddComponent<Text>();
            label.font = GetDefaultFont();
            label.text = text;
            label.fontSize = fontSize;
            label.alignment = alignment;
            label.color = Color.white;
            return label;
        }

        private static Button CreateButton(
            Transform parent, string name, Vector2 anchoredPosition, Vector2 size, Color color, string label, UnityAction onClick)
        {
            var buttonObject = new GameObject(name);
            buttonObject.transform.SetParent(parent, false);
            var rect = buttonObject.AddComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.5f, 0.5f);
            rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.sizeDelta = size;
            rect.anchoredPosition = anchoredPosition;

            var image = buttonObject.AddComponent<Image>();
            image.color = color;

            var button = buttonObject.AddComponent<Button>();
            // Selectable.Reset() (which normally auto-wires this) only
            // runs when a component is added via the Editor, not via
            // AddComponent() at runtime -- so it's set explicitly here.
            // Clicks work either way; this just restores hover/press
            // color feedback.
            button.targetGraphic = image;
            button.onClick.AddListener(onClick);

            if (!string.IsNullOrEmpty(label))
            {
                CreateLabel(buttonObject.transform, label, 16, TextAnchor.MiddleCenter);
            }
            return button;
        }

        private void BuildInteractionPrompt(Canvas canvas)
        {
            var rect = CreatePanel(canvas.transform, "InteractionPrompt", new Color(0f, 0f, 0f, 0.6f));
            rect.anchorMin = new Vector2(0.5f, 0f);
            rect.anchorMax = new Vector2(0.5f, 0f);
            rect.pivot = new Vector2(0.5f, 0f);
            rect.anchoredPosition = new Vector2(0f, 80f);
            rect.sizeDelta = new Vector2(520f, 50f);

            _promptRoot = rect.gameObject;
            _promptText = CreateLabel(rect, string.Empty, 22, TextAnchor.MiddleCenter);
            _promptRoot.SetActive(false);
        }

        /// Every element below is center-anchored (CreatePanel's default)
        /// with a fixed y offset from the panel's own center, and the
        /// panel size is picked to fit them -- laid out and verified by
        /// hand (title/status/4 buttons at y = 150/-150/90/30/-30/-90,
        /// each 40-46 tall with >=14px gaps, inside a 380-tall panel)
        /// since there's no editor here to see an overlap and fix it.
        private void BuildBuildingMenu(Canvas canvas)
        {
            var rect = CreatePanel(canvas.transform, "BuildingMenu", new Color(0.08f, 0.06f, 0.05f, 0.92f));
            rect.sizeDelta = new Vector2(420f, 380f);

            _menuPanel = rect.gameObject;

            var titleRect = CreatePanel(rect, "Title", Color.clear);
            titleRect.anchoredPosition = new Vector2(0f, 150f);
            titleRect.sizeDelta = new Vector2(380f, 40f);
            _menuTitle = CreateLabel(titleRect, string.Empty, 24, TextAnchor.MiddleCenter);

            CreateButton(rect, "GigsButton", new Vector2(0f, 90f), new Vector2(320f, 46f),
                new Color(1f, 0.78f, 0.34f), "Gigs",
                () => SendMenuAction("gigs"));

            CreateButton(rect, "HireButton", new Vector2(0f, 30f), new Vector2(320f, 46f),
                new Color(0.31f, 0.80f, 0.77f), "Hire Staff",
                () => SendMenuAction("hire"));

            CreateButton(rect, "ShopButton", new Vector2(0f, -30f), new Vector2(320f, 46f),
                new Color(1f, 0.42f, 0.42f), "Shop",
                () => SendMenuAction("shop"));

            CreateButton(rect, "LeaveButton", new Vector2(0f, -90f), new Vector2(320f, 46f),
                new Color(0.35f, 0.32f, 0.28f), "Leave",
                () => _menuPanel.SetActive(false));

            var statusRect = CreatePanel(rect, "Status", Color.clear);
            statusRect.anchoredPosition = new Vector2(0f, -150f);
            statusRect.sizeDelta = new Vector2(380f, 40f);
            _statusText = CreateLabel(statusRect, string.Empty, 13, TextAnchor.MiddleCenter);
            _statusText.color = new Color(0.9f, 0.7f, 0.4f);

            _menuPanel.SetActive(false);
        }

        /// Same hand-verified approach as BuildBuildingMenu: everything
        /// center-anchored at a fixed y (header 85, skin-tone row 30,
        /// outfit row -25, accessory button -75), panel sized to
        /// actually contain the lowest element (-75, half-height 46)
        /// with margin, anchored to the screen's top-left corner.
        private void BuildCustomizationPanel(Canvas canvas)
        {
            var rect = CreatePanel(canvas.transform, "CustomizationPanel", new Color(0.08f, 0.06f, 0.05f, 0.85f));
            rect.anchorMin = new Vector2(0f, 1f);
            rect.anchorMax = new Vector2(0f, 1f);
            rect.pivot = new Vector2(0f, 1f);
            rect.anchoredPosition = new Vector2(20f, -20f);
            rect.sizeDelta = new Vector2(260f, 240f);

            var headerRect = CreatePanel(rect, "Header", Color.clear);
            headerRect.anchoredPosition = new Vector2(0f, 85f);
            headerRect.sizeDelta = new Vector2(240f, 30f);
            CreateLabel(headerRect, "Customize", 18, TextAnchor.MiddleCenter);

            const float swatchSize = 36f;
            const float swatchGap = 10f;
            float rowStartX = -((SkinTones.Length - 1) * (swatchSize + swatchGap)) / 2f;

            for (int i = 0; i < SkinTones.Length; i++)
            {
                Color color = SkinTones[i];
                CreateButton(rect, $"SkinTone{i}",
                    new Vector2(rowStartX + i * (swatchSize + swatchGap), 30f),
                    new Vector2(swatchSize, swatchSize), color, string.Empty,
                    () => _customization?.SetSkinTone(color));
            }

            for (int i = 0; i < OutfitColors.Length; i++)
            {
                Color color = OutfitColors[i];
                CreateButton(rect, $"Outfit{i}",
                    new Vector2(rowStartX + i * (swatchSize + swatchGap), -25f),
                    new Vector2(swatchSize, swatchSize), color, string.Empty,
                    () => _customization?.SetOutfitColor(color));
            }

            CreateButton(rect, "AccessoryButton", new Vector2(0f, -75f), new Vector2(220f, 40f),
                new Color(0.5f, 0.45f, 0.35f), "Cycle Accessory",
                CycleAccessory);
        }

        private void CycleAccessory()
        {
            _accessoryIndex = (_accessoryIndex + 1) % AccessoryOptions.Length;
            _customization?.SetAccessory(AccessoryOptions[_accessoryIndex]);
        }

        private void ShowStatus(string message)
        {
            if (_statusText != null)
            {
                _statusText.text = message;
            }
            Debug.Log($"[StarStudio] {message}");
        }

        /// Forwards a Gigs/Hire/Shop click for whichever building's menu
        /// is currently open to FlutterBridge, if one exists in the
        /// scene (only true once the Flutter bridge has been wired up --
        /// see unity/README.md). Either way, shows a status line so
        /// testing this menu standalone in the Editor still gives
        /// visible feedback.
        private void SendMenuAction(string action)
        {
#if STAR_STUDIO_FLUTTER_BRIDGE
            var bridge = FindObjectOfType<FlutterBridge>();
            if (bridge != null)
            {
                bridge.SendMenuAction(_currentBuildingId, action);
                ShowStatus($"Sent \"{action}\" to Flutter for {_menuTitle?.text}.");
                return;
            }
#endif
            ShowStatus($"\"{action}\" needs the Flutter bridge -- not wired up yet.");
        }

        private void OnBuildingEntered(string id, string displayName)
        {
            if (_promptText != null)
            {
                _promptText.text = $"Press E to enter {displayName}";
            }
            _promptRoot?.SetActive(true);
        }

        private void OnBuildingExited(string id)
        {
            _promptRoot?.SetActive(false);
        }

        private void OnBuildingInteracted(string id, string displayName)
        {
            _currentBuildingId = id;
            _promptRoot?.SetActive(false);
            if (_menuTitle != null)
            {
                _menuTitle.text = displayName;
            }
            if (_statusText != null)
            {
                _statusText.text = string.Empty;
            }
            _menuPanel?.SetActive(true);
        }
    }
}
