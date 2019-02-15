using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Game : MonoBehaviour
{
    public Material RenderMaterial;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (RenderMaterial == null)
            return;

        int xres = 320;
        int yres = (xres * Screen.height) / Screen.width;

        RenderMaterial.SetFloat("_ResX", xres);
        RenderMaterial.SetFloat("_ResY", yres);

        RenderTexture scaled = RenderTexture.GetTemporary(xres, yres);
        Graphics.Blit(source, scaled, RenderMaterial);
        Graphics.Blit(scaled, destination);
        RenderTexture.ReleaseTemporary(scaled);
    }
}
