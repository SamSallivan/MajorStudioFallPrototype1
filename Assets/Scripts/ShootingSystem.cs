using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using DG.Tweening;

public class ShootingSystem : MonoBehaviour
{

    [SerializeField] ParticleSystem inkParticle;
    [SerializeField] Transform parentController;
    [SerializeField] Transform splatGunNozzle;
    public float capTimer = 0;
    public float temp;
    public GameObject cap;

    public AudioClip splatSound;

    void Start()
    {
        this.AddComponent<AudioSource>();
        GetComponent<AudioSource>().volume = 0.5f;
    }

    void Update()
    {
        Vector3 angle = parentController.localEulerAngles;
        bool pressing = Input.GetMouseButton(0);

        if (capTimer>0){
            capTimer--;
            // float yy = 0;
            // if (capTimer > 30)
            //     yy =  Mathf.Lerp(temp, temp - 0.3f, (capTimer-30)/30);
            // else if (capTimer < 30)
            //     yy =  Mathf.Lerp(temp - 0.3f, temp, capTimer/30);
            // cap.transform.position = new Vector3(cap.transform.position.x, yy, cap.transform.position.z);
        }

        if (Input.GetMouseButton(0))
        {
            //VisualPolish();
        }

        if (Input.GetMouseButtonDown(0) && capTimer == 0)
        {
            inkParticle.Play();
            GetComponent<AudioSource>().PlayOneShot(splatSound);
            capTimer = 60;
            temp = cap.transform.localPosition.y;
            cap.transform.DOLocalJump(new Vector3(0.1272426f, 3.949137f, 0), -0.5f, 1, 0.5f, false);
        }


    }
    
    void VisualPolish()
    {
        if (!DOTween.IsTweening(parentController))
        {
            parentController.DOComplete();
            Vector3 forward = -parentController.forward;
            Vector3 localPos = parentController.localPosition;
            parentController.DOLocalMove(localPos - new Vector3(0, 0, .2f), .03f)
                .OnComplete(() => parentController.DOLocalMove(localPos, .1f).SetEase(Ease.OutSine));

        }

        if (!DOTween.IsTweening(splatGunNozzle))
        {
            splatGunNozzle.DOComplete();
            splatGunNozzle.DOPunchScale(new Vector3(0, 1, 1) / 1.5f, .15f, 10, 1);
        }
    }
}
