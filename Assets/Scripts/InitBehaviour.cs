using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Rewired;

public class InitBehaviour : MonoBehaviour
{
    private static InitBehaviour m_instance;

    public static InitBehaviour Instance
    {
        get
        {
            if (m_instance == null)
            {
                m_instance = FindObjectOfType<InitBehaviour>();
            }

            return m_instance;
        }
    }

    public void Awake()
    {

    }

    public void Update()
    {

    }



}
