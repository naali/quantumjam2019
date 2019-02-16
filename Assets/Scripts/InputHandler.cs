using UnityEngine;
using System.Collections;
using Rewired;

public class InputHandler : MonoBehaviour {
    public int playerId = 0;

    private bool m_flip_pressed;
    public bool FlipPressed {
        get {
            if (m_flip_pressed) {
                m_flip_pressed = false;
                return true;
            }

            return false;
        }
    }

    private bool m_plug_pressed;
    public bool PlugPressed {
        get {
            if (m_plug_pressed) {
                m_plug_pressed = false;
                return true;
            }

            return false;
        }
    }

    private bool m_esc_pressed;
    public bool EscPressed {
        get {
            if (m_esc_pressed) {
                m_esc_pressed = false;
                return true;
            }

            return false;
        }
    }
    private bool m_start_pressed;
    public bool StartPressed {
        get {
            if (m_start_pressed) {
                m_start_pressed = false;
                return true;
            }

            return false;
        }
    }
    private Player player;

    void Awake() {
        player = ReInput.players.GetPlayer(playerId);
    }

    void Update () {
        GetInput();
    }

    private void GetInput() {
        bool startpressed = player.GetButton("Start");

        if (startpressed != m_start_pressed) {
            m_start_pressed = startpressed;
        }

        bool flippressed = player.GetButton("Flip");

        if (flippressed != m_flip_pressed) {
            m_flip_pressed = flippressed;
        }

        bool plugpressed = player.GetButton("Plug");
        
        if (plugpressed != m_plug_pressed) {
            m_plug_pressed = plugpressed;
        }

        bool escpressed = player.GetButton("Exit");

        if (escpressed != m_esc_pressed) {
            m_esc_pressed = escpressed;
        }
    }

}
