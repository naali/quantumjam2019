using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Game : MonoBehaviour
{
    public Material RenderMaterial;
    private float m_time = 0.0f;
    private int m_frame_count = 0;

    private const float PlugInsertAnimLength = 0.5f;

    private float m_wheel_rot = 0.0f;
    private float m_wheel_rot_dest = 0.0f;
    private float m_wheel_explosion = -1.0f;
    private float m_plug_insert_anim = PlugInsertAnimLength;
    private float m_plug_rot = 0.0f;
    private float m_plug_rot_dest = 0.0f;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        m_time += Time.deltaTime;
        ++m_frame_count;

        m_time += Input.GetAxis("Horizontal") * 5.0f;

        // Test controls
        if (Input.GetKeyDown(KeyCode.Q))
            m_wheel_rot_dest += 1.0f;
        if (Input.GetKeyDown(KeyCode.W))
            m_plug_rot_dest = 1.0f - m_plug_rot_dest;
        if (Input.GetKeyDown(KeyCode.E))
            m_plug_insert_anim = 0.0f;
        if (Input.GetKeyDown(KeyCode.R))
            m_wheel_explosion = (m_wheel_explosion < 0.0f) ? 0.0f : -1.0f;

        // Update the animations
        m_wheel_rot += (m_wheel_rot_dest - m_wheel_rot) * Time.deltaTime * 5.0f;
        if (m_wheel_explosion >= 0.0f)
            m_wheel_explosion += Time.deltaTime;
        m_plug_rot += (m_plug_rot_dest - m_plug_rot) * Time.deltaTime * 5.0f;
        m_plug_insert_anim = Mathf.Min(m_plug_insert_anim + Time.deltaTime, PlugInsertAnimLength);
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (RenderMaterial == null)
            return;

        int xres = 320;
        int yres = (xres * Screen.height) / Screen.width;

        float plug_offset = Mathf.Clamp01(m_plug_insert_anim / PlugInsertAnimLength);

        RenderMaterial.SetFloat("_MyTime", m_time);
        RenderMaterial.SetFloat("_ResX", xres);
        RenderMaterial.SetFloat("_ResY", yres);
        RenderMaterial.SetInt("_Frame", m_frame_count);
        RenderMaterial.SetFloat("_WheelPos", m_wheel_rot);
        RenderMaterial.SetFloat("_WheelExplosion", m_wheel_explosion);
        RenderMaterial.SetFloat("_PlugOffset", plug_offset);
        RenderMaterial.SetFloat("_PlugOrientation", m_plug_rot);

        RenderTexture scaled = RenderTexture.GetTemporary(xres, yres);
        Graphics.Blit(source, scaled, RenderMaterial);
        Graphics.Blit(scaled, destination);
        RenderTexture.ReleaseTemporary(scaled);
    }
}
