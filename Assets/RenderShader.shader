// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/RenderShader"
{
	SubShader
	{
		Pass
		{
CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			// Incoming args:
			float _MyTime;
			float _ResX, _ResY;
			int _Frame;

			float _WheelPos; // Every integer is at "position"
			float _WheelExplosion; // 0 (intact) -> ...
			float _PlugOffset; // 0-1, 1 is attached
			float _PlugOrientation; // 0-1

			struct v2f {
				float4 position : SV_POSITION;
			};

			v2f vert(float4 v:POSITION) : SV_POSITION {
				v2f o;
				o.position = UnityObjectToClipPos(v);
				return o;
			}

// GLSL -> HLSL definitions
#define UNITY_MODE
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define mat2 float2x2
#define mat3 float3x3
//#define mod fmod
float mod(float a, float b) { return a - b * floor(a / b); }
#define fract frac
#define mix lerp
vec2 mul2x2(mat2 m, vec2 p) { return mul(p, m); }
vec3 mul3x3(mat3 m, vec3 p) { return mul(p, m); }
float _atan(float x, float y) { return atan2(y, x); }
// Shadertoy definitions
vec2 iResolution;
float iTime;
int iFrame;
vec2 iMouse = vec2(0, 0);
/////////////////////////
// SHADERTOY CODE:
#ifndef UNITY_MODE
vec2 mul2x2(mat2 m, vec2 p) { return m * p; }
vec3 mul3x3(mat3 m, vec3 p) { return m * p; }
float _atan(float x, float y) { return atan(x, y); }
#endif

// Uses code (MIT) from Inigo Quilez -- https://www.shadertoy.com/view/Xds3zN

#define AA 2   // make this 2 or 3 for antialiasing


//------------------------------------------------------------------

#define PI (3.1415926535897932384626433832795)
#define PI2 (2.0 * PI)

float sdPlane(vec3 p)
{
	return p.y;
}

float sdSphere(vec3 p, float s)
{
	return length(p) - s;
}

float sdBox(vec3 p, vec3 b)
{
	vec3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdEllipsoid(in vec3 p, in vec3 r) // approximated
{
	float k0 = length(p / r);
	float k1 = length(p / (r*r));
	return k0 * (k0 - 1.0) / k1;

}

float sdRoundBox(in vec3 p, in vec3 b, in float r)
{
	vec3 q = abs(p) - b;
	return min(max(q.x, max(q.y, q.z)), 0.0) + length(max(q, 0.0)) - r;
}

float sdTorus(vec3 p, vec2 t)
{
	return length(vec2(length(p.xz) - t.x, p.y)) - t.y;
}

float sdHexPrism(vec3 p, vec2 h)
{
	vec3 q = abs(p);

	const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
	p = abs(p);
	p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
	vec2 d = vec2(
		length(p.xy - vec2(clamp(p.x, -k.z*h.x, k.z*h.x), h.x))*sign(p.y - h.x),
		p.z - h.y);
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r)
{
	vec3 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h) - r;
}

float sdRoundCone(in vec3 p, in float r1, float r2, float h)
{
	vec2 q = vec2(length(p.xz), p.y);

	float b = (r1 - r2) / h;
	float a = sqrt(1.0 - b * b);
	float k = dot(q, vec2(-b, a));

	if (k < 0.0) return length(q) - r1;
	if (k > a*h) return length(q - vec2(0.0, h)) - r2;

	return dot(q, vec2(a, b)) - r1;
}

float dot2(in vec3 v) { return dot(v, v); }
float sdRoundCone(vec3 p, vec3 a, vec3 b, float r1, float r2)
{
	// sampling independent computations (only depend on shape)
	vec3  ba = b - a;
	float l2 = dot(ba, ba);
	float rr = r1 - r2;
	float a2 = l2 - rr * rr;
	float il2 = 1.0 / l2;

	// sampling dependant computations
	vec3 pa = p - a;
	float y = dot(pa, ba);
	float z = y - l2;
	float x2 = dot2(pa*l2 - ba * y);
	float y2 = y * y*l2;
	float z2 = z * z*l2;

	// single square root!
	float k = sign(rr)*rr*rr*x2;
	if (sign(z)*a2*z2 > k) return  sqrt(x2 + z2)        *il2 - r2;
	if (sign(y)*a2*y2 < k) return  sqrt(x2 + y2)        *il2 - r1;
	return (sqrt(x2*a2*il2) + y * rr)*il2 - r1;
}

float sdEquilateralTriangle(in vec2 p)
{
	const float k = 1.73205;//sqrt(3.0);
	p.x = abs(p.x) - 1.0;
	p.y = p.y + 1.0 / k;
	if (p.x + k * p.y > 0.0) p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
	p.x += 2.0 - 2.0*clamp((p.x + 2.0) / 2.0, 0.0, 1.0);
	return -length(p)*sign(p.y);
}

float sdTriPrism(vec3 p, vec2 h)
{
	vec3 q = abs(p);
	float d1 = q.z - h.y;
	h.x *= 0.866025;
	float d2 = sdEquilateralTriangle(p.xy / h.x)*h.x;
	return length(max(vec2(d1, d2), 0.0)) + min(max(d1, d2), 0.);
}

// vertical
float sdCylinder(vec3 p, vec2 h)
{
	vec2 d = abs(vec2(length(p.xz), p.y)) - h;
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdCylinder_xy(vec3 p, vec2 h)
{
	vec2 d = abs(vec2(length(p.xy), p.z)) - h;
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// arbitrary orientation
float sdCylinder(vec3 p, vec3 a, vec3 b, float r)
{
	vec3 pa = p - a;
	vec3 ba = b - a;
	float baba = dot(ba, ba);
	float paba = dot(pa, ba);

	float x = length(pa*baba - ba * paba) - r * baba;
	float y = abs(paba - baba * 0.5) - baba * 0.5;
	float x2 = x * x;
	float y2 = y * y*baba;
	float d = (max(x, y) < 0.0) ? -min(x2, y2) : (((x > 0.0) ? x2 : 0.0) + ((y > 0.0) ? y2 : 0.0));
	return sign(d)*sqrt(abs(d)) / baba;
}

float sdCone(in vec3 p, in vec3 c)
{
	vec2 q = vec2(length(p.xz), p.y);
	float d1 = -q.y - c.z;
	float d2 = max(dot(q, c.xy), q.y);
	return length(max(vec2(d1, d2), 0.0)) + min(max(d1, d2), 0.);
}

float dot2(in vec2 v) { return dot(v, v); }
float sdCappedCone(in vec3 p, in float h, in float r1, in float r2)
{
	vec2 q = vec2(length(p.xz), p.y);

	vec2 k1 = vec2(r2, h);
	vec2 k2 = vec2(r2 - r1, 2.0*h);
	vec2 ca = vec2(q.x - min(q.x, (q.y < 0.0) ? r1 : r2), abs(q.y) - h);
	vec2 cb = q - k1 + k2 * clamp(dot(k1 - q, k2) / dot2(k2), 0.0, 1.0);
	float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
	return s * sqrt(min(dot2(ca), dot2(cb)));
}

#if 0
// bound, not exact
float sdOctahedron(vec3 p, float s)
{
	p = abs(p);
	return (p.x + p.y + p.z - s)*0.57735027;
}
#else
// exacy distance
float sdOctahedron(vec3 p, float s)
{
	p = abs(p);

	float m = p.x + p.y + p.z - s;

	vec3 q;
	if (3.0*p.x < m) q = p.xyz;
	else if (3.0*p.y < m) q = p.yzx;
	else if (3.0*p.z < m) q = p.zxy;
	else return m * 0.57735027;

	float k = clamp(0.5*(q.z - q.y + s), 0.0, s);
	return length(vec3(q.x, q.y - s + k, q.z - k));
}
#endif


float length2(vec2 p)
{
	return sqrt(p.x*p.x + p.y*p.y);
}

float length6(vec2 p)
{
	p = p * p*p; p = p * p;
	return pow(p.x + p.y, 1.0 / 6.0);
}

float length8(vec2 p)
{
	p = p * p; p = p * p; p = p * p;
	return pow(p.x + p.y, 1.0 / 8.0);
}

float sdTorus82(vec3 p, vec2 t)
{
	vec2 q = vec2(length2(p.xz) - t.x, p.y);
	return length8(q) - t.y;
}

float sdTorus88(vec3 p, vec2 t)
{
	vec2 q = vec2(length8(p.xz) - t.x, p.y);
	return length8(q) - t.y;
}

float sdCylinder6(vec3 p, vec2 h)
{
	return max(length6(p.xz) - h.x, abs(p.y) - h.y);
}

//------------------------------------------------------------------

float opS(float d1, float d2)
{
	return max(-d2, d1);
}

vec2 opS(vec2 d1, vec2 d2)
{
	return vec2(max(-d2.x, d1.x), d1.y);
}

float opU(float d1, float d2)
{
	return min(d1, d2);
}

vec2 opU(vec2 d1, vec2 d2)
{
	return (d1.x < d2.x) ? d1 : d2;
}

vec3 opRep(vec3 p, vec3 c)
{
	return mod(p, c) - 0.5*c;
}

vec3 opTwist(vec3 p)
{
	float  c = cos(10.0*p.y + 10.0);
	float  s = sin(10.0*p.y + 10.0);
	mat2   m = mat2(c, -s, s, c);
	return vec3(mul2x2(m, p.xz), p.y);
}

//------------------------------------------------------------------

#define ZERO (min(iFrame,0))

//------------------------------------------------------------------

float s2dCircle(in vec2 p, float r)
{
	return length(p) - r;
}

float s2dBox(in vec2 p, in vec2 b)
{
	vec2 d = abs(p) - b;
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float s2dCapsule(vec2 p, vec2 a, vec2 b, float r)
{
	vec2 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h) - r;
}

float s2dTri(in vec2 p)
{
	vec2 slope1 = normalize(vec2(0.6, 1));
	vec2 slope2 = vec2(slope1.x, -slope1.y);
	float slope_ofs = 0.065;

	float d = dot(p, vec2(-1, 0));
	d = max(d, dot(p - vec2(0, slope_ofs), slope1));
	d = max(d, dot(p - vec2(0, -slope_ofs), slope2));

	return d;
}

float s2dUsbLogo(in vec2 p)
{
	float d = 1e10;

	// Center
	p.y -= 0.5;

	d = opU(d, s2dCircle(p - vec2(0.11, 0.0), 0.1));
	d = opU(d, s2dBox(p - vec2(0.5, 0.0), vec2(0.39, 0.02)));
	d = opU(d, s2dTri(p - vec2(0.88, 0.0)));

	d = opU(d, s2dCircle(p - vec2(0.56, 0.15), 0.052));
	d = opU(d, s2dCapsule(p, vec2(0.56, 0.15), vec2(0.4, 0.15), 0.02));
	d = opU(d, s2dCapsule(p, vec2(0.25, 0.0), vec2(0.4, 0.15), 0.02));

	d = opU(d, s2dBox(p - vec2(0.74, -0.15), vec2(0.052, 0.052)));
	d = opU(d, s2dCapsule(p, vec2(0.74, -0.15), vec2(0.58, -0.15), 0.02));
	d = opU(d, s2dCapsule(p, vec2(0.38, 0.0), vec2(0.58, -0.15), 0.02));

	return d;
}

vec3 rot_xy(vec3 p, float ang)
{
	float c = cos(ang);
	float s = sin(ang);
	return vec3(p.x * c + p.y * s, p.x * s - p.y * c, p.z);
}


#define usb_plug_ratio (12.0 / 4.5)

vec2 sdUsbHole(in vec3 pos)
{
	vec2 res = vec2(1e10, 0.0);

	float shell_mat = 46.0 - length(pos.xy) * 10.0;

	// Shell
	float d = sdCylinder_xy(pos - vec3(0, 0, 0.5), vec2(1.0, 0.5));
	d = opS(d, sdCylinder_xy(pos - vec3(0, 0, -0.1), vec2(0.9, 0.2)));
	d -= 0.03; // Roundness

	// Side supports
	d = opU(d, sdCapsule(pos - vec3(0, 0, 0.7), vec3(-0.9, 0, 0), vec3(0.9, 0, 0), 0.3));

	// USB hole
	d = opS(d, sdRoundBox(pos, vec3(0.1 * usb_plug_ratio, 0.1, 0.5), 0.05));
	res = opU(res, vec2(d, shell_mat));

	res = opU(res, vec2(sdBox(pos - vec3(0, 0.05, 0.43), vec3(0.1 * usb_plug_ratio, 0.05, 0.3)), 333.0));

	return res;
}

vec2 sdUsbPlug(in vec3 pos)
{
	vec2 res = vec2(1e10, 0.0);

	pos.z = -pos.z; // Flip to face the wheel

	float d = 99999.0;

	// The head
	res = opU(res, vec2(sdBox(pos, vec3(0.1 * usb_plug_ratio, 0.1, 0.6)), 123.0));
	res = opU(res, vec2(sdBox(pos - vec3(0.1, 0, -0.35), vec3(0.06, 0.105, 0.1)), 85.0));
	res = opU(res, vec2(sdBox(pos - vec3(-0.1, 0, -0.35), vec3(0.06, 0.105, 0.1)), 85.0));
	// The body
	float body_mat = 55.0 - abs(fract(pos.z / 0.4)) * 3.0;
	res = opU(res, vec2(sdRoundBox(pos - vec3(0, 0, 0.5), vec3(0.1 * usb_plug_ratio, 0.1, 0.5), 0.1), body_mat));
	res = opU(res, vec2(sdCylinder_xy(pos - vec3(0, 0, 1.0), vec2(0.3, 0.3)) - 0.03, 56.0));
	// The wire "cap"
	res = opU(res, vec2(sdCylinder_xy(pos - vec3(0, 0, 1.2), vec2(0.2, 0.3)) - 0.03, 6.0));
	// The wire
	res = opU(res, vec2(sdCylinder_xy(pos - vec3(0, 0, 5.2), vec2(0.11, 5.0)), 10.0));

	//res = opU(res, vec2(d, 123.0));

	//res = opU(res, sdWheel(pos));

	return res;
}

vec2 sdWheel(in vec3 pos)
{
	vec2 res = vec2(1e10, 0.0);

	float segment_ang = PI2 / 6.0; // One segments "pi" angle

#ifndef UNITY_MODE
	float rot_ang = iTime;
#else
	float rot_ang = _WheelPos;
#endif

	rot_ang *= segment_ang; // Every integer step addvances one segment
	rot_ang -= segment_ang / 2.0; // Align the angle so that every integer has a slot at the bottom

	float d = 0.0;


	// Add the wheel
	float wheel_mat = 15.0 + length(pos.xy) * 10.0;
	float center_mat = 5486.0 + length(pos.xy) * 5.0;

	vec3 wpos = rot_xy(pos, rot_ang);

	float logo_scale = 4.0f;
	float logo = s2dUsbLogo((wpos.xy / logo_scale + vec2(0.5, 0.5))) * logo_scale;
	if (logo <= 0.0f) center_mat = 1000.0;

	d = sdCylinder_xy(wpos - vec3(0, 0, 1), vec2(5.2, 0.5));
	d = opU(d, sdCylinder_xy(wpos - vec3(0, 0, 0.8), vec2(5.7, 0.1)));
	//res = opU(res, vec2(d, 15.0));
	res = opU(res, vec2(d, wheel_mat));
	res = opU(res, vec2(sdRoundBox(wpos - vec3(0, 0, 0.6), vec3(1.8, 1.8, 0.1), 0.1), center_mat));
	res = opU(res, vec2(sdRoundBox(rot_xy(wpos, PI / 4.0) - vec3(0, 0, 0.6), vec3(1.8, 1.8, 0.1), 0.1), center_mat));


	// Pick the segment
#ifndef UNITY_MODE
	float seg_ang = _atan(pos.y, pos.x) - rot_ang;
#else
	float seg_ang = atan2(pos.y, pos.x) - rot_ang;
#endif
	seg_ang += segment_ang / 2.0;
	seg_ang -= mod(seg_ang, segment_ang);
	seg_ang += rot_ang;

	// Insert the hole
	vec3 hole_pos = vec3(cos(seg_ang), sin(seg_ang), 0.0) * 4.0;

	//float d = sdBox(pos - hole_pos, vec3(0.1, 0.1, 0.1));

	res = opS(res, vec2(sdCylinder_xy(pos - hole_pos, vec2(1.1, 5.0)), 1.0)); // Small hole around the plug
	res = opU(res, sdUsbHole(pos - hole_pos));

	return res;
}

vec2 sdWheelExplosion(in vec3 pos)
{
	vec2 res = vec2(1e10, 0.0);

	float expl_time = 1.0;
	float expl = mod(iTime, expl_time);

#ifndef UNITY_MODE
	expl = 0.0;
#else
	expl = clamp(_WheelExplosion, 0.0, expl_time);
#endif
	expl = expl * cos(expl * pos.x * pos.y * pos.z);

	res = opU(res, sdWheel(pos));
	res.x += expl * 3.0;

	return res;
}

vec2 sdSurrounds(in vec3 pos)
{
	float rep = 5.0;
	vec3 rep3 = vec3(rep, rep, rep);

	float manh_dist = max(abs(pos.x), max(abs(pos.y), abs(pos.z)));
	if (manh_dist < 6.5)
		return vec2(sdSphere(pos, -5000.0), 0.0);

	pos += rep3 * 0.5;

	vec3 pos_rep = mod(pos, rep3) - 0.5*rep;
	vec3 cell = floor(pos / rep3);

	return sdUsbHole(pos_rep);
}

vec2 map(in vec3 pos)
{
	vec2 res = vec2(1e10, 0.0);

#ifndef UNITY_MODE
	float usb_plug_offset = pow(abs(cos(iTime*3.0)), 5.0);
	float usb_plug_orientation = smoothstep(0.0, 1.0, abs(cos(iTime*1.1235)));
#else
	float usb_plug_offset = _PlugOffset;
	float usb_plug_orientation = _PlugOrientation;
#endif

	usb_plug_offset *= 1.5;
	float usb_plug_ang = usb_plug_orientation * PI;

	//res = opU(res, sdWheel(pos));
	res = opU(res, sdWheelExplosion(pos));

	res = opU(res, sdUsbPlug(rot_xy(pos - vec3(0, -4.0, -0.15 - usb_plug_offset), usb_plug_ang)));

	//res = opU(res, sdSurrounds(pos));
	//res = sdSurrounds(pos);

	return res;
}

// http://iquilezles.org/www/articles/boxfunctions/boxfunctions.htm
vec2 iBox(in vec3 ro, in vec3 rd, in vec3 rad)
{
	vec3 m = 1.0 / rd;
	vec3 n = m * ro;
	vec3 k = abs(m)*rad;
	vec3 t1 = -n - k;
	vec3 t2 = -n + k;
	return vec2(max(max(t1.x, t1.y), t1.z),
		min(min(t2.x, t2.y), t2.z));
}

const float maxHei = 0.8;

vec2 castRay(in vec3 ro, in vec3 rd)
{
	vec2 res = vec2(-1.0, -1.0);

	float tmin = 1.0;
	float tmax = 50.0;
	/*
		// raytrace floor plane
		float tp1 = (0.0-ro.y)/rd.y;
		if( tp1>0.0 )
		{
			tmax = min( tmax, tp1 );
			res = vec2( tp1, 1.0 );
		}
		//else return res;
	*/

	// raymarch primitives   
	//vec2 tb = iBox( ro-vec3(0.0,0.4,0.0), rd, vec3(2.5,0.41,2.5) );
	//if( tb.x<tb.y && tb.y>0.0 && tb.x<tmax)
	{
		//tmin = max(tb.x,tmin);
		//tmax = min(tb.y,tmax);

		float t = tmin;
		for (int i = 0; i < 130 && t < tmax; i++)
		{
			vec2 h = map(ro + rd * t);
			if (abs(h.x) < (0.0001*t))
			{
				res = vec2(t, h.y);
				break;
			}
			t += h.x;
		}
	}

	return res;
}


// http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float calcSoftshadow(in vec3 ro, in vec3 rd, in float mint, in float tmax)
{
	// bounding volume
//    float tp = (maxHei-ro.y)/rd.y; if( tp>0.0 ) tmax = min( tmax, tp );

	float res = 1.0;
	float t = mint;
	for (int i = ZERO; i < 16; i++)
	{
		float h = map(ro + rd * t).x;
		res = min(res, 8.0*h / t);
		t += clamp(h, 0.02, 0.10);
		if (res<0.005 || t>tmax) break;
	}
	return clamp(res, 0.0, 1.0);
}

// http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal(in vec3 pos)
{
#if 1
	vec2 e = vec2(1.0, -1.0)*0.5773*0.0005;
	return normalize(e.xyy*map(pos + e.xyy).x +
		e.yyx*map(pos + e.yyx).x +
		e.yxy*map(pos + e.yxy).x +
		e.xxx*map(pos + e.xxx).x);
#else
	// inspired by klems - a way to prevent the compiler from inlining map() 4 times
	vec3 n = vec3(0.0);
	for (int i = ZERO; i < 4; i++)
	{
		vec3 e = 0.5773*(2.0*vec3((((i + 3) >> 1) & 1), ((i >> 1) & 1), (i & 1)) - 1.0);
		n += e * map(pos + 0.0005*e).x;
	}
	return normalize(n);
#endif    
}

float calcAO(in vec3 pos, in vec3 nor)
{
	float occ = 0.0;
	float sca = 1.0;
	for (int i = ZERO; i < 5; i++)
	{
		float hr = 0.01 + 0.12*float(i) / 4.0;
		vec3 aopos = nor * hr + pos;
		float dd = map(aopos).x;
		occ += -(dd - hr)*sca;
		sca *= 0.95;
	}
	return clamp(1.0 - 3.0*occ, 0.0, 1.0) * (0.5 + 0.5*nor.y);
}

// http://iquilezles.org/www/articles/checkerfiltering/checkerfiltering.htm
float checkersGradBox(in vec2 p)
{
	// filter kernel
	vec2 w = fwidth(p) + 0.001;
	// analytical integral (box filter)
	vec2 i = 2.0*(abs(fract((p - 0.5*w)*0.5) - 0.5) - abs(fract((p + 0.5*w)*0.5) - 0.5)) / w;
	// xor pattern
	return 0.5 - 0.5*i.x*i.y;
}

vec3 render(in vec3 ro, in vec3 rd)
{
	vec3 col = vec3(0.7, 0.9, 1.0) + rd.y*0.8;
	col *= 0.1; // Make sky darker
	vec2 res = castRay(ro, rd);
	float t = res.x;
	float m = res.y;
	if (m > -0.5)
	{
		vec3 pos = ro + t * rd;
		vec3 nor = (m < 1.5) ? vec3(0.0, 1.0, 0.0) : calcNormal(pos);
		vec3 ref = reflect(rd, nor);

		// material        
		col = 0.45 + 0.35*sin(vec3(0.05, 0.08, 0.10)*(m - 1.0));
		if (m < 1.5)
		{

			float f = checkersGradBox(5.0*pos.xz);
			col = 0.3 + f * vec3(0.1, 0.1, 0.1);
		}

		// lighting
		float occ = calcAO(pos, nor);
		vec3  lig = normalize(vec3(-0.4, 0.7, -0.6));
		vec3  hal = normalize(lig - rd);
		float amb = clamp(0.5 + 0.5*nor.y, 0.0, 1.0);
		float dif = clamp(dot(nor, lig), 0.0, 1.0);
		float bac = clamp(dot(nor, normalize(vec3(-lig.x, 0.0, -lig.z))), 0.0, 1.0)*clamp(1.0 - pos.y, 0.0, 1.0);
		float dom = smoothstep(-0.2, 0.2, ref.y);
		float fre = pow(clamp(1.0 + dot(nor, rd), 0.0, 1.0), 2.0);

		dif *= calcSoftshadow(pos, lig, 0.02, 2.5);
		dom *= calcSoftshadow(pos, ref, 0.02, 2.5);

		float spe = pow(clamp(dot(nor, hal), 0.0, 1.0), 16.0)*
			dif *
			(0.04 + 0.96*pow(clamp(1.0 + dot(hal, rd), 0.0, 1.0), 5.0));

		vec3 lin = vec3(0.0, 0.0, 0.0);
		lin += 1.30*dif*vec3(1.00, 0.80, 0.55);
		lin += 0.30*amb*vec3(0.40, 0.60, 1.00)*occ;
		lin += 0.40*dom*vec3(0.40, 0.60, 1.00)*occ;
		lin += 0.50*bac*vec3(0.25, 0.25, 0.25)*occ;
		lin += 0.25*fre*vec3(1.00, 1.00, 1.00)*occ;
		col = col * lin;
		col += 9.00*spe*vec3(1.00, 0.90, 0.70);

		//col = mix( col, vec3(0.8,0.9,1.0), 1.0-exp( -0.0002*t*t*t ) );
		col = mix(col, vec3(0.2, 0.2, 0.3), 1.0 - exp(-0.0001*t*t*t));

		// Logo
		if (m == 1000.0) col = vec3(0, 0, 0);
	}

	return vec3(clamp(col, 0.0, 1.0));
}

mat3 setCamera(in vec3 ro, in vec3 ta, float cr)
{
	vec3 cw = normalize(ta - ro);
	vec3 cp = vec3(sin(cr), cos(cr), 0.0);
	vec3 cu = normalize(cross(cw, cp));
	vec3 cv = (cross(cu, cw));
	return mat3(cu, cv, cw);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec2 mo = iMouse.xy / iResolution.xy;
	float time = 0.0 + iTime;

	// camera	
	vec3 ro = vec3(2.6*cos(0.5*time + 6.0*mo.x), -3.5 + 2.0*mo.y, -6.5 + 1.6*sin(0.5*time + 6.0*mo.x));
	//ro.z = -abs(ro.z);
	vec3 ta = vec3(0, -2.5, 0);
	// camera-to-world transformation
	mat3 ca = setCamera(ro, ta, 0.0);

	vec3 tot = vec3(0.0, 0.0, 0.0);
#if AA>1
	for (int m = ZERO; m < AA; m++)
		for (int n = ZERO; n < AA; n++)
		{
			// pixel coordinates
			vec2 o = vec2(float(m), float(n)) / float(AA) - 0.5;
			vec2 p = (-iResolution.xy + 2.0*(fragCoord + o)) / iResolution.y;
#else    
	vec2 p = (-iResolution.xy + 2.0*fragCoord) / iResolution.y;
#endif

	// ray direction
	vec3 rd = mul3x3(ca, normalize(vec3(p.xy, 2.0)));

	// render	
	vec3 col = render(ro, rd);

	// gamma
	col = pow(col, vec3(0.4545, 0.4545, 0.4545));

	tot += col;
#if AA>1
		}
tot /= float(AA*AA);
#endif


fragColor = vec4(tot, 1.0);
}
/////////////////////////


			float4 frag(v2f i) : SV_Target
			{
				float2 resolution = _ScreenParams.xy;
				resolution = float2(_ResX, _ResY);
				float2 uv = -1.0 + 2.0*i.position.xy / resolution.xy;
				uv.x *= resolution.x / resolution.y;

				float4 output;
				iResolution = float2(_ResX, _ResY);
				iTime = _MyTime;
				iFrame = _Frame;
				mainImage(output, i.position.xy);
				return output;
			}

			ENDCG
		}
    }
}
