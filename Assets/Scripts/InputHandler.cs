using UnityEngine;
using System.Collections;
using Rewired;

public class InputHandler : MonoBehaviour {
    public int playerId = 0;

    public bool FlipPressed;
    public bool PlugPressed;
    public bool EscPressed;
    private Player player;

    void Awake() {
        Debug.Log("ASDASD: InputHandler::Awake");
        player = ReInput.players.GetPlayer(playerId);
        Debug.Log(player);
    }

    void Update () {
        GetInput();
    }

    private void GetInput() {
        FlipPressed = player.GetButton("Flip");
        PlugPressed = player.GetButton("Plug");
        EscPressed = player.GetButton("Quit");
    }

}
