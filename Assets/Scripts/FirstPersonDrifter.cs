using UnityEngine;

[RequireComponent(typeof(CharacterController))]
public class FirstPersonDrifter : MonoBehaviour
{
	public float walkSpeed = 6f;

	public float runSpeed = 10f;

	private bool limitDiagonalSpeed = true;

	public bool enableRunning;

	public float jumpSpeed = 4f;

	public float gravity = 10f;

	private float fallingDamageThreshold = 10f;

	public bool slideWhenOverSlopeLimit;

	public bool slideOnTaggedObjects;

	public float slideSpeed = 5f;

	public bool airControl = true;

	public float antiBumpFactor = 0.75f;

	public int antiBunnyHopFactor = 1;

	private Vector3 moveDirection = Vector3.zero;

	private bool grounded;

	private CharacterController controller;

	private Transform myTransform;

	private float speed;

	private RaycastHit hit;

	private float fallStartLevel;

	private bool falling;

	private float slideLimit;

	private float rayDistance;

	private Vector3 contactPoint;

	private bool playerControl;

	private int jumpTimer;

	private void Start()
	{
		controller = GetComponent<CharacterController>();
		myTransform = base.transform;
		speed = walkSpeed;
		rayDistance = controller.height * 0.5f + controller.radius;
		slideLimit = controller.slopeLimit - 0.1f;
		jumpTimer = antiBunnyHopFactor;
	}

	private void FixedUpdate()
	{
		float axis = Input.GetAxis("Horizontal");
		float axis2 = Input.GetAxis("Vertical");
		float num = ((axis != 0f && axis2 != 0f && limitDiagonalSpeed) ? 0.7071f : 1f);
		if (grounded)
		{
			bool flag = false;
			if (Physics.Raycast(myTransform.position, -Vector3.up, out hit, rayDistance))
			{
				if (Vector3.Angle(hit.normal, Vector3.up) > slideLimit)
				{
					flag = true;
				}
			}
			else
			{
				Physics.Raycast(contactPoint + Vector3.up, -Vector3.up, out hit);
				if (Vector3.Angle(hit.normal, Vector3.up) > slideLimit)
				{
					flag = true;
				}
			}
			if (falling)
			{
				falling = false;
				if (myTransform.position.y < fallStartLevel - fallingDamageThreshold)
				{
					FallingDamageAlert(fallStartLevel - myTransform.position.y);
				}
			}
			if (enableRunning)
			{
				speed = (Input.GetButton("Run") ? runSpeed : walkSpeed);
			}
			if ((flag && slideWhenOverSlopeLimit) || (slideOnTaggedObjects && hit.collider.tag == "Slide"))
			{
				Vector3 normal = hit.normal;
				moveDirection = new Vector3(normal.x, 0f - normal.y, normal.z);
				Vector3.OrthoNormalize(ref normal, ref moveDirection);
				moveDirection *= slideSpeed;
				playerControl = false;
			}
			else
			{
				moveDirection = new Vector3(axis * num, 0f - antiBumpFactor, axis2 * num);
				moveDirection = myTransform.TransformDirection(moveDirection) * speed;
				playerControl = true;
			}
			if (!Input.GetButton("Jump"))
			{
				jumpTimer++;
			}
			else if (jumpTimer >= antiBunnyHopFactor)
			{
				moveDirection.y = jumpSpeed;
				jumpTimer = 0;
			}
		}
		else
		{
			if (!falling)
			{
				falling = true;
				fallStartLevel = myTransform.position.y;
			}
			if (airControl && playerControl)
			{
				moveDirection.x = axis * speed * num;
				moveDirection.z = axis2 * speed * num;
				moveDirection = myTransform.TransformDirection(moveDirection);
			}
		}
		moveDirection.y -= gravity * Time.deltaTime;
		grounded = (controller.Move(moveDirection * Time.deltaTime) & CollisionFlags.Below) != 0;
	}

	private void OnControllerColliderHit(ControllerColliderHit hit)
	{
		contactPoint = hit.point;
	}

	private void FallingDamageAlert(float fallDistance)
	{
	}
}
