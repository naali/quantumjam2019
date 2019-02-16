using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Rewired;

public class QuantumPlugPlayer : MonoBehaviour
{
    public int playerId = 0;

    private Player player; // The Rewired Player
    private bool plug;
    private bool flip;

    void Awake()
    {
        Debug.Log("QuantumPlugPlayer::Awake");
        player = ReInput.players.GetPlayer(playerId);
    }

    void Start()
    {
        Debug.Log("QuantumPlugPlayer::Start");
    }

    // Update is called once per frame
    void Update()
    {
        GetInput();
        ProcessInput();
        int motorIndex = 0; // the first motor
        float motorLevel = 1.0f; // full motor speed
        float duration = 2.0f; // 2 seconds

        player.SetVibration(motorIndex, motorLevel, duration);

    }

    private void GetInput()
    {
        bool current_flip = player.GetButton("Flip");
        bool current_plug = player.GetButton("Plug");

        if (current_plug != this.plug) {
            this.plug = current_plug;
            Debug.Log("QuantumPlugPlayer::GetInput: plug: " + plug);
        }

        if (current_flip != this.flip) {
            this.flip = current_flip;
            Debug.Log("QuantumPlugPlayer::GetInput: flip: " + flip);
        }
    }
    private void ProcessInput()
    {

    }

}
