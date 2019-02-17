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
    public TMP_Text EndScreenScoreText;

    public Material RenderMaterial;
    public InputHandler input;

    private string[] m_quantun_machine_slurs = { 
        "Quantum Socket wins.", 
        "Yet another casualty.",
        "There's no right way.",
        "Trying makes it harder.",
        "Did you try it the other way?",
        "Fits perfectly into ethernet socket",
        "Was it even the correct cable?",
        "Try to blow into it.",
        "Use another socket.",
        "I meant the other left.",
        "Princess in another castle.",
        "Was that HDMI socket?"
    };
    public AudioClip AudioStart;
    public AudioClip AudioFlipCable;
    public AudioClip AudioInsertCable;
    public AudioClip AudioFail;
    private AudioSource m_audio_source;

    public int QuantumTimeSteps = 400;
    public int GrowthBufferSize = 10;

    public float GameTime = 10.9f;

    private float m_time = 0.0f;
    private int m_frame_count = 0;

    private const float PlugInsertAnimLength = 0.5f;

    private float m_wheel_rot = 0.0f;
    private float m_wheel_rot_dest = 0.0f;
    private float m_wheel_explosion = -1.0f;
    private float m_plug_insert_anim = PlugInsertAnimLength;
    private float m_plug_rot = 0.0f;
    private float m_plug_rot_dest = 0.0f;

    private float m_wheel_rot_anim = 0.0f;

    private RingBuffer m_growth_left;
    private RingBuffer m_growth_middle;
    private RingBuffer m_growth_right;

    private StirapEnv m_env;
    private float m_gametime;
    private int m_gamescore;

    private float m_endscreen_timer;
    private int m_step;

    private float m_left;
    private float m_right;

    private float m_right_result;
    private float m_left_result;

    private bool m_plug_up;

    private float m_vibratime;
    private bool m_fails;

    private float m_plug_anim_timer;

    private enum GameStateType {
        Menu,
        InGame,
        InGamePlug,
        InGameExplosion,
        InGameRotation,
        GameOver
    }

    private GameStateType m_game_state;

    void Start()
    {
        m_audio_source = GetComponent<AudioSource>();
    }

    void Awake()
    {
        m_game_state = GameStateType.Menu;
        m_step = 0;
        m_plug_up = false;
        GameScreen.SetActive(false);
        EndScreen.SetActive(false);
        MenuScreen.SetActive(true);

        ResetGrowthMeasures();
    }

    private void UpdateMenu()
    {

        if (input.EscPressed) {
            Application.Quit();
        }

        if (input.StartPressed || input.FlipPressed) {
            m_audio_source.PlayOneShot(AudioStart);

            InitQuantumEnvironment(UnityEngine.Random.value);

            MenuScreen.SetActive(false);
            EndScreen.SetActive(false);
            GameScreen.SetActive(true);
            m_gametime = GameTime;
            m_gamescore = 0;
            UpdateGameScore(m_gamescore);
            m_game_state = GameStateType.InGame;
        }
    }

    private void UpdateIngameExplosion()
    {
        UpdateGameTime();

        if (m_wheel_explosion > 1.0f) {
            m_wheel_explosion = -1.0f;

            GameScreen.SetActive(false);
            MenuScreen.SetActive(false);
            EndScreen.SetActive(true);
            EndScreenScoreText.text = "You plugged " + m_gamescore + " holes.\n" + m_quantun_machine_slurs[(int)Math.Floor(m_quantun_machine_slurs.Length * UnityEngine.Random.value)];
            m_endscreen_timer = 2.0f;
            m_game_state = GameStateType.GameOver;

        }
    }

    private void UpdateIngameRotation()
    {
        UpdateGameTime();

        if (m_wheel_rot_anim <= 0.0f) {
            m_game_state = GameStateType.InGame;
        }

        m_wheel_rot_anim -= Time.deltaTime;
    }

    private void UpdateGameTime()
    {
        m_gametime -= Time.deltaTime;

        float t = m_gametime >= 0.0f ? m_gametime : 0.0f;
        GameTimeText.text = "Time left: " + (int)Math.Floor(t);
    }

    private void UpdateGameScore(int score)
    {
        GameScoreText.text = "Score: " + score;
    }

    private void UpdateInGame()
    {
        UpdateGameTime();

        if (m_gametime < 0 || input.EscPressed) {
            GameScreen.SetActive(false);
            MenuScreen.SetActive(false);
            EndScreen.SetActive(true);
            EndScreenScoreText.text = "You plugged " + m_gamescore + " holes.\n" + m_quantun_machine_slurs[(int)Math.Floor(m_quantun_machine_slurs.Length * UnityEngine.Random.value)];
            m_endscreen_timer = 2.0f;
            m_game_state = GameStateType.GameOver;
            return;
        }

        if (input.FlipPressed) {
            m_audio_source.PlayOneShot(AudioFlipCable);
            m_plug_rot_dest = 1.0f - m_plug_rot_dest;
            m_plug_up = !m_plug_up;
        }

        float result = m_left_result + m_right_result;

        m_vibratime += (Time.deltaTime * 10.0f);

        if (m_plug_up) {
            if (result > 0.5f) {
                input.SetVibration(0, 1.0f, 1/60f);
            } else {
                if (((int)m_vibratime % 2) == 0) {
                    input.SetVibration(0, 0.0f, 1/60f);
                } else {
                    input.SetVibration(0, 1.0f, 1/60f);
                }
            }
        } else {
            if (result <= 0.5f) {
                input.SetVibration(0, 1.0f, 1/60f);
            } else {
                if (((int)m_vibratime % 2) == 0) {
                    input.SetVibration(0, 0.0f, 1/60f);
                } else {
                    input.SetVibration(0, 1.0f, 1/60f);
                }
            }
        }


        if (input.PlugPressed) {

            if (m_plug_up) {
    
                if (result > 0.5f) {
                    m_fails = true;
                } else {
                    m_fails = false;
                }

            } else {
    
                if (result <= 0.5f) {
                    m_fails = true;
                } else {
                    m_fails = false;
                }

            }

            m_plug_insert_anim = 0.0f;
            m_plug_anim_timer = 0.0f;
            m_game_state = GameStateType.InGamePlug;

            if (!m_fails)
                m_audio_source.PlayOneShot(AudioStart);
        }


        RunStep(m_step++, Time.deltaTime);
    }

    private void UpdateIngamePlug()
    {
        UpdateGameTime();

        m_plug_anim_timer += Time.deltaTime;

        if (m_plug_anim_timer > 0.3f) {
            m_plug_anim_timer = 0.0f;

            if (m_fails) {
                m_wheel_explosion = 0.0f;
                m_game_state = GameStateType.InGameExplosion;
                m_audio_source.PlayOneShot(AudioFail);
            } else {
                UpdateGameScore(++m_gamescore);
                m_gametime += Mathf.Max(4.0f - (float)m_gamescore * 0.3f, 1.5f);
                m_wheel_rot_dest++;
                m_game_state = GameStateType.InGameRotation;
                InitQuantumEnvironment(UnityEngine.Random.value);
                ResetGrowthMeasures();
                m_audio_source.PlayOneShot(AudioInsertCable);
                m_step = 0;

                if (UnityEngine.Random.value > 0.5f) {
                    m_plug_up = !m_plug_up;
                }

                for (int i = 0; i<20; i++) {
                    RunStep(m_step++, Time.deltaTime);
                }
            }
        }
    }

    private void UpdateGameOver()
    {
        m_endscreen_timer -= Time.deltaTime;

        if (m_endscreen_timer > 0.0) {
            return;
        }

        if (input.FlipPressed || input.EscPressed) {
            EndScreen.SetActive(false);
            GameScreen.SetActive(false);
            MenuScreen.SetActive(true);

            m_game_state = GameStateType.Menu;
        }
    }

    private void ResetGrowthMeasures()
    {
        m_growth_right = new RingBuffer(0, GrowthBufferSize);
        m_growth_left = new RingBuffer(0, GrowthBufferSize);
        m_growth_middle = new RingBuffer(0, GrowthBufferSize);

        m_left = UnityEngine.Random.value;
        m_right = UnityEngine.Random.value;
    }

    private void RunStep(int step, float deltaTime)
    {
        StirapEnv.StepResult result;
        
        // Add a using Py.GIL() block whenever interacting with Python wrapper classes such as StirapEnv
        using (Py.GIL())
        {
            result = m_env.Step(m_left, m_right);
        }

        float leftPop = result.LeftPopulation;
        float rightPop = result.RightPopulation;
        float midPop = 1f - (leftPop + rightPop);

        m_left_result = result.LeftPopulation;
        m_right_result = result.RightPopulation;
        
        UpdateWell(result.RightPopulation, result.RightWellPosition, m_growth_right);
        UpdateWell(result.LeftPopulation, result.LeftWellPosition, m_growth_left);
        UpdateWell(1f - (leftPop + rightPop), 0, m_growth_middle);
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

            case GameStateType.InGamePlug:
                UpdateIngamePlug();
                break;

            case GameStateType.InGameRotation:
                UpdateIngameRotation();
                break;

            case GameStateType.GameOver:
                UpdateGameOver();
                break;

            case GameStateType.InGameExplosion:
                UpdateIngameExplosion();
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
