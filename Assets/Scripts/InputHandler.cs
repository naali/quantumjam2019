using UnityEngine;
using System.Collections;
using Rewired;

public class InputHandler : MonoBehaviour {
    public int playerId = 0;
    private Player player;

    public bool FlipPressed {
        get {
            if (player == null) { return false; }
            return player.GetButtonDown("Flip");
        }
    }

    public bool PlugPressed {
        get {
            if (player == null) { return false; }
            return player.GetButtonDown("Plug");
        }
    }

    public bool EscPressed {
        get {
            if (player == null) { return false; }
            return player.GetButtonDown("Exit");
        }
    }
    public bool StartPressed {
        get {
            if (player == null) { return false; }
            return player.GetButtonDown("Start");
        }
    }

    void Awake() {
        player = ReInput.players.GetPlayer(playerId);
    }
}
