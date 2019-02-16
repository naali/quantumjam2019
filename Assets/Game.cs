using System;
using System.Collections;
using System.Collections.Generic;
using System.Numerics;
using UnityEngine;
using Python.Runtime;
using UnityEngine.Serialization;
using Vector3 = UnityEngine.Vector3;
using TMPro;

[ExecuteInEditMode]
public class Game : MonoBehaviour
{
    public GameObject MenuScreen;
    public GameObject GameScreen;
    public GameObject EndScreen;

    public TMP_Text GameTimeText;
    public TMP_Text GameScoreText;

    public Material RenderMaterial;
    public InputHandler input;

    public int QuantumTimeSteps = 400;
    public int GrowthBufferSize = 10;

    public float GameTime = 10.0f;

    private float m_time = 0.0f;
    private int m_frame_count = 0;

    private const float PlugInsertAnimLength = 0.5f;

    private float m_wheel_rot = 0.0f;
    private float m_wheel_rot_dest = 0.0f;
    private float m_wheel_explosion = -1.0f;
    private float m_plug_insert_anim = PlugInsertAnimLength;
    private float m_plug_rot = 0.0f;
    private float m_plug_rot_dest = 0.0f;

    private RingBuffer m_growth_left;
    private RingBuffer m_growth_middle;
    private RingBuffer m_growth_right;

    private StirapEnv m_env;
    private float m_gametime;
    private int m_gamescore;

    private int m_step;

    private double RandomTry {
        get {
            double noise = m_env.Noise;
            return noise;
        }
    }

    private enum GameStateType {
        Menu,
        InGame,
        GameOver
    }

    private GameStateType m_game_state;

    void Awake()
    {
        m_game_state = GameStateType.Menu;
        m_step = 0;
        GameScreen.SetActive(false);
        EndScreen.SetActive(false);
        MenuScreen.SetActive(true);

        ResetGrowthMeasures();
    }

    private void UpdateMenu()
    {
        if (input.StartPressed || input.FlipPressed) {
            InitQuantumEnvironment(UnityEngine.Random.value);

            MenuScreen.SetActive(false);
            EndScreen.SetActive(false);
            GameScreen.SetActive(true);
            m_gametime = GameTime;
            m_gamescore = 0;
            m_game_state = GameStateType.InGame;
        }
    }

    private void UpdateInGame()
    {
        m_gametime -= Time.deltaTime;

        if (m_gametime < 0) {
            m_game_state = GameStateType.GameOver;
            return;
        }

        if (input.FlipPressed) {
            m_plug_rot_dest = 1.0f - m_plug_rot_dest;
        }

        if (input.PlugPressed) {
            m_plug_insert_anim = 0.0f;
            Debug.Log("TRY: " + RandomTry);
        }

        GameTimeText.text = "Time left: " + m_gametime;

        RunStep(m_step, Time.deltaTime);
    }

    private void UpdateGameOver()
    {
        GameScreen.SetActive(false);
        MenuScreen.SetActive(false);
        EndScreen.SetActive(true);

        if (input.FlipPressed) {

        }
    }

    private void ResetGrowthMeasures()
    {
        m_growth_right = new RingBuffer(0, GrowthBufferSize);
        m_growth_left = new RingBuffer(0, GrowthBufferSize);
        m_growth_middle = new RingBuffer(0, GrowthBufferSize);
    }

    private void RunStep(int step, float deltaTime)
    {
        StirapEnv.StepResult result;
        
        // Add a using Py.GIL() block whenever interacting with Python wrapper classes such as StirapEnv
        using (Py.GIL())
        {
            float left = (float)Math.Sin(deltaTime * 17.0);
            float right = (float)Math.Cos(deltaTime * 23.0);
            result = m_env.Step(left, right);
        }

        float leftPop = result.LeftPopulation;
        float rightPop = result.RightPopulation;
        float midPop = 1f - (leftPop + rightPop);
        
        UpdateWell(result.RightPopulation, result.RightWellPosition, m_growth_right);
        UpdateWell(result.LeftPopulation, result.LeftWellPosition, m_growth_left);
        UpdateWell(1f - (leftPop + rightPop), 0, m_growth_middle);
        
//        RenderPlot(result);
//        SetScore(result.RightPopulation, step);
    }


    private void UpdateWell(float height, float pos, RingBuffer growthMeasure)
    {
        growthMeasure.Update(height * 5f - growthMeasure.Last);
    }

    void Update()
    {
        float delta_t = Time.deltaTime;

        m_time += delta_t * 1.0f; // Multiply based on feeling; the shadertoy seems to run at a faster timerate
        ++m_frame_count;

        switch (m_game_state) {
            case GameStateType.InGame:
                UpdateInGame();
                break;

            case GameStateType.GameOver:
                UpdateGameOver();
                break;            

            case GameStateType.Menu:
            default:
                UpdateMenu();
                break;
        }

        // Update the animations
        m_wheel_rot += (m_wheel_rot_dest - m_wheel_rot) * delta_t * 5.0f;
        if (m_wheel_explosion >= 0.0f)
            m_wheel_explosion += delta_t;
        m_plug_rot += (m_plug_rot_dest - m_plug_rot) * delta_t * 5.0f;
        m_plug_insert_anim = Mathf.Min(m_plug_insert_anim + delta_t, PlugInsertAnimLength);
    }

    private void InitQuantumEnvironment(double displacement) {
        using (Python.Runtime.Py.GIL())
        {
            
            m_env = new StirapEnv(QuantumTimeSteps, displacement);
            Debug.Log("Noise: "+m_env.Noise);
        }
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
