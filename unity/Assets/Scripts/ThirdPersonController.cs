using UnityEngine;

namespace StarStudio
{
    /// Camera-relative WASD movement for the placeholder capsule
    /// character. Reads Unity's default Input Manager axes, so it works
    /// in a fresh project with no extra input setup.
    [RequireComponent(typeof(CharacterController))]
    public class ThirdPersonController : MonoBehaviour
    {
        public float moveSpeed = 4.5f;
        public float rotationSpeed = 12f;
        public float gravity = -9.81f;
        public Transform cameraTransform;

        private CharacterController _controller;
        private Vector3 _verticalVelocity;

        public bool IsMoving { get; private set; }

        private void Awake()
        {
            _controller = GetComponent<CharacterController>();
            if (cameraTransform == null && Camera.main != null)
            {
                cameraTransform = Camera.main.transform;
            }
        }

        private void Update()
        {
            float horizontal = Input.GetAxisRaw("Horizontal");
            float vertical = Input.GetAxisRaw("Vertical");
            Vector3 input = new Vector3(horizontal, 0f, vertical);
            if (input.sqrMagnitude > 1f)
            {
                input.Normalize();
            }

            Vector3 moveDirection = ResolveMoveDirection(input);
            IsMoving = moveDirection.sqrMagnitude > 0.0001f;

            if (IsMoving)
            {
                transform.rotation = Quaternion.Slerp(
                    transform.rotation,
                    Quaternion.LookRotation(moveDirection, Vector3.up),
                    rotationSpeed * Time.deltaTime);
            }

            if (_controller.isGrounded && _verticalVelocity.y < 0f)
            {
                _verticalVelocity.y = 0f;
            }
            _verticalVelocity.y += gravity * Time.deltaTime;

            Vector3 motion = moveDirection * moveSpeed + _verticalVelocity;
            _controller.Move(motion * Time.deltaTime);
        }

        /// Movement is relative to the camera's flattened forward/right
        /// so pushing "up" always means "away from camera," matching how
        /// third-person controls are expected to feel.
        private Vector3 ResolveMoveDirection(Vector3 input)
        {
            if (input.sqrMagnitude <= 0.0001f)
            {
                return Vector3.zero;
            }
            if (cameraTransform == null)
            {
                return input;
            }

            Vector3 camForward = cameraTransform.forward;
            camForward.y = 0f;
            camForward.Normalize();
            Vector3 camRight = cameraTransform.right;
            camRight.y = 0f;
            camRight.Normalize();

            return camForward * input.z + camRight * input.x;
        }
    }
}
