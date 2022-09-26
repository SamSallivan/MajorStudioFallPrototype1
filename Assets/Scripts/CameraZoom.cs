using UnityEngine;

[RequireComponent(typeof(Camera))]
public class CameraZoom : MonoBehaviour
{
	public float zoomFOV = 30f;

	public float zoomSpeed = 9f;

	private float targetFOV;

	private float baseFOV;

	private void Start()
	{
		SetBaseFOV(GetComponent<Camera>().fieldOfView);
	}

	private void Update()
	{
		if (Input.GetButton("Fire2"))
		{
			targetFOV = zoomFOV;
		}
		else
		{
			targetFOV = baseFOV;
		}
		UpdateZoom();
	}

	private void UpdateZoom()
	{
		GetComponent<Camera>().fieldOfView = Mathf.Lerp(GetComponent<Camera>().fieldOfView, targetFOV, zoomSpeed * Time.deltaTime);
	}

	public void SetBaseFOV(float fov)
	{
		baseFOV = fov;
	}
}
