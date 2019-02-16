using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RingBuffer
{
    private List<float> m_buffer = new List<float>();
    private int m_bufferSize = 10;

    public float Average
    {
        get
        {
            float v = 0f;
            foreach (float f in m_buffer)
            {
                v += f;
            }

            return v / m_buffer.Count;
        }
    }

    public float Last
    {
        get
        {
            if (m_buffer.Count > 0)
                return m_buffer[m_buffer.Count - 1];
            return 0f;
        }
    }

    public RingBuffer(float startMeasure, int bufferSize)
    {
        m_buffer.Add(startMeasure);
        m_bufferSize = bufferSize;
    }

    public RingBuffer Update(float measure)
    {
        m_buffer.Add(measure);
        if (m_buffer.Count > m_bufferSize)
            m_buffer.RemoveAt(0);

        return this;
    }

    public RingBuffer Clear()
    {
        m_buffer.Clear();
        return this;
    }


}
