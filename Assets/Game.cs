using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Game : MonoBehaviour
{
    public Material RenderMaterial;
    private float m_time = 0.0f;
    private int m_frame_count = 0;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        m_time += Time.deltaTime;
        ++m_frame_count;
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (RenderMaterial == null)
            return;

        int xres = 320;
        int yres = (xres * Screen.height) / Screen.width;

        RenderMaterial.SetFloat("_MyTime", m_time);
        RenderMaterial.SetFloat("_ResX", xres);
        RenderMaterial.SetFloat("_ResY", yres);
        RenderMaterial.SetInt("_Frame", m_frame_count);

        RenderTexture scaled = RenderTexture.GetTemporary(xres, yres);
        Graphics.Blit(source, scaled, RenderMaterial);
        Graphics.Blit(scaled, destination);
        RenderTexture.ReleaseTemporary(scaled);
    }
}
