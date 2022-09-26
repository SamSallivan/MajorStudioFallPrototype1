using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class NPCController : MonoBehaviour
{
    public GameObject target;
    public Camera cam;

    public float alert = 0;
    public float alertSensitivity = 1;
    public float maxDistance = 10;
    public float maxAngle = 75;
    public GameObject question;

    public Volume volume;
    public Bloom bloom;
    public ChromaticAberration ca;
    public ColorAdjustments cg;
    public Vignette vg;

    public AudioClip alertSound;
    public bool soundPlayed;


    void Start()
    {
        cam = Camera.main;

        volume = FindObjectOfType<Volume>();
        volume.profile.TryGet(out bloom);
        volume.profile.TryGet(out ca);
        volume.profile.TryGet(out cg);
        volume.profile.TryGet(out vg);

        this.AddComponent<AudioSource>();
        GetComponent<AudioSource>().volume = 0.5f;
    }

    private void Update ()
    {
        transform.parent.GetComponent<Animator>().SetFloat("alert", alert);

        var targetRender = target.GetComponent<Renderer>();
        if (ICanSee(target))
        {
            float dist = Vector3.Distance(Camera.main.transform.position, transform.position);
            float angle = Vector3.Angle(Camera.main.transform.forward, (transform.position - Camera.main.transform.position).normalized);

            if (dist < maxDistance && angle < maxAngle)
            {
                question.GetComponent<Renderer>().material.SetColor("Color_E9C3FC1D", new Vector4(1, 0.4f, 0, 1));
                question.GetComponent<Renderer>().material.SetColor("Color_1B2A4228", new Vector4(0.5f, 0, 0.05f, 1));

                if (alert < 1000)
                {
                    alert += alertSensitivity * ((maxDistance - dist) / maxDistance * 0.5f + (maxAngle - angle) / maxAngle * 1.5f);
                    question.transform.parent.GetComponent<Renderer>().enabled = true;
                }
            }
            else
            {
                question.GetComponent<Renderer>().material.SetColor("Color_E9C3FC1D", new Vector4(0, 1, 1, 1));
                question.GetComponent<Renderer>().material.SetColor("Color_1B2A4228", new Vector4(0, 1, 1, 1));

                if (alert > 0)
                    alert -= 1;
                else
                    question.transform.parent.GetComponent<Renderer>().enabled = false;
            }
        }
        else
        {
            question.GetComponent<Renderer>().material.SetColor("Color_E9C3FC1D", new Vector4(0, 1, 1, 1));
            question.GetComponent<Renderer>().material.SetColor("Color_1B2A4228", new Vector4(0, 1, 1, 1));

            if (alert > 0)
                alert -= 1;
            else
                question.transform.parent.GetComponent<Renderer>().enabled = false;
        }

        if(alert >= 750)
        {
            if (!soundPlayed)
            {
                soundPlayed = true;
                GetComponent<AudioSource>().PlayOneShot(alertSound);
            }
        }
        if (alert < 750)
        {
            soundPlayed = false;
        }


            bloom.intensity.value = Mathf.Lerp(2.5f, 25, alert/1000); 
        ca.intensity.value = Mathf.Lerp(0, 1, alert / 1000);
        vg.intensity.value = Mathf.Lerp(0, 0.3f, alert / 1000);
        question.GetComponent<Renderer>().material.SetFloat("Vector1_86B367DE", 1 - (alert / 1000));
        question.transform.parent.Rotate(0, 0.5f, 0);
        question.transform.parent.localPosition = new Vector3(0f, 1.93f + Mathf.Sin(Time.timeSinceLevelLoad * 0.025f) * 0.025f, 0f);
    }

    private bool IsVisible(Camera c, GameObject target)
    {
        var planes = GeometryUtility.CalculateFrustumPlanes(c);
        var point = target.transform.position;

        foreach (var plane in planes)
        {
            if (plane.GetDistanceToPoint(point) < 0)
            {
                return false;
            }
        }
        return true;
    }

    private bool ICanSee(GameObject o)
    {
        Plane[] planes = GeometryUtility.CalculateFrustumPlanes(Camera.main);
        return GeometryUtility.TestPlanesAABB(planes, o.GetComponent<Collider>().bounds);
    }
}