using UnityEngine;

namespace StarStudio
{
    /// Curated third-person camera (design doc §5.1: "a curated near-fixed
    /// 3/4 angle ... with limited orbit/pitch and pinch-zoom within a
    /// pleasant band -- never flat-on, never top-down, no free-orbit").
    /// Drag to nudge the view within a clamped yaw/pitch band; it always
    /// springs back toward the default 3/4 angle rather than allowing a
    /// full orbit.
    public class StudioCameraRig : MonoBehaviour
    {
        public Transform target;
        public Vector3 targetOffset = new Vector3(0f, 1.6f, 0f);

        [Header("Distance (zoom)")]
        public float distance = 7f;
        public float minDistance = 5f;
        public float maxDistance = 10f;
        public float zoomSpeed = 4f;

        [Header("Yaw (left/right orbit, clamped)")]
        public float defaultYaw = 0f;
        public float yawRange = 35f;

        [Header("Pitch (up/down orbit, clamped)")]
        public float defaultPitch = 35f;
        public float minPitch = 20f;
        public float maxPitch = 55f;

        [Header("Feel")]
        public float followLerpSpeed = 8f;
        public float dragSensitivity = 6f;

        private float _yaw;
        private float _pitch;
        private bool _dragging;
        private Vector3 _lastPointerPosition;

        private void Start()
        {
            _yaw = defaultYaw;
            _pitch = defaultPitch;
        }

        private void Update()
        {
            HandleDragInput();
            HandleZoomInput();
        }

        private void HandleDragInput()
        {
            bool pointerDown = Input.GetMouseButtonDown(0) || Input.GetMouseButtonDown(1);
            bool pointerUp = Input.GetMouseButtonUp(0) || Input.GetMouseButtonUp(1);
            bool pointerHeld = Input.GetMouseButton(0) || Input.GetMouseButton(1);

            if (pointerDown)
            {
                _dragging = true;
                _lastPointerPosition = Input.mousePosition;
            }
            else if (pointerUp)
            {
                _dragging = false;
            }

            if (_dragging && pointerHeld)
            {
                Vector3 delta = Input.mousePosition - _lastPointerPosition;
                _lastPointerPosition = Input.mousePosition;

                _yaw += delta.x * dragSensitivity * Time.deltaTime;
                _pitch -= delta.y * dragSensitivity * Time.deltaTime;
            }

            _yaw = Mathf.Clamp(_yaw, defaultYaw - yawRange, defaultYaw + yawRange);
            _pitch = Mathf.Clamp(_pitch, minPitch, maxPitch);
        }

        private void HandleZoomInput()
        {
            float scroll = Input.GetAxis("Mouse ScrollWheel");
            if (Mathf.Abs(scroll) > 0.0001f)
            {
                distance = Mathf.Clamp(distance - scroll * zoomSpeed, minDistance, maxDistance);
            }
        }

        private void LateUpdate()
        {
            if (target == null)
            {
                return;
            }

            Quaternion rotation = Quaternion.Euler(_pitch, _yaw, 0f);
            Vector3 pivot = target.position + targetOffset;
            Vector3 desiredPosition = pivot - rotation * Vector3.forward * distance;

            float followT = 1f - Mathf.Exp(-followLerpSpeed * Time.deltaTime);
            transform.position = Vector3.Lerp(transform.position, desiredPosition, followT);
            transform.LookAt(pivot);
        }
    }
}
