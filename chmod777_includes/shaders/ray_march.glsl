layout (local_size_x=1, local_size_y=1, local_size_z=1) in;
layout(rgba32f, binding = 0) uniform image2D imgOutput;

// file: raymarch.glsl
// author: chmod777
// license: GNU AGPL v3

layout(std140, binding = 5) buffer Spheres {
	vec4 pallet_a;
	vec4 pallet_b;
	vec4 pallet_c;
	vec4 pallet_d;
	vec4 sp_pos[SPHERE_COUNT];
	vec4 sp_speed[SPHERE_COUNT];
	float sp_radius[SPHERE_COUNT]; // alignment [float, pad, pad, pad]
};

layout(std430, binding = 7) buffer Camera {
	vec4 cam_pos;
	vec4 cam_front;
	vec4 cam_xAxis;
	vec4 cam_yAxis;
	float cam_fov;
};
uniform float time;

// Resources
// https://iquilezles.org/articles/palettes/
vec4 palette_impl(float t, vec4 a, vec4 b, vec4 c, vec4 d) {
	// return a + b*cos( 6.28312 * (c*t+d) )
	return fma(b, cos(6.28312 * fma(c, vec4(t), d)), a);
}
vec4 palette(float t) {
	return palette_impl(t, pallet_a, pallet_b, pallet_c, pallet_d);
}

struct Sphere {
	vec3 pos;     // 4
	float radius; // 8
};
Sphere localSpheres[SPHERE_COUNT];

struct RayHit {
	float dist;
	int id;
	vec3 normal;
};

float op_union(float a, float b) {
	return (a < b) ? a : b;
}
float op_smooth_union(float a, float b, float k) {
	float diff = a - b;
	float h_raw = fma(diff/k, 0.5, 0.5);
	float h = clamp(h_raw, 0.0, 1.0);
	float d = fma(-k, h*(1.0 - h), mix(a, b, h));
	return d;
}

float signDistanceSphere(vec3 point, Sphere sphere) {
	return length(point - sphere.pos) - sphere.radius;
}

float sdf(vec3 point) {
	float a = signDistanceSphere(point, localSpheres[0]);
	for (int i = 1; i < SPHERE_COUNT; i++) {
		float b = signDistanceSphere(point, localSpheres[i]);
		a = op_smooth_union(a, b, float(SMOOTHING_FACTOR));
	}
	return a;
}

vec3 normal(vec3 p) {
	vec2 e = vec2(0.0001, 0.0);
	float d = sdf(p);
	vec3 n = d - vec3(
		sdf(p - e.xyy),
		sdf(p - e.yxy),
		sdf(p - e.yyx)
	);
	return normalize(n);
}
RayHit rayMarch(vec3 origin, vec3 dir) {
	RayHit dummy = RayHit(-1.0, -1, vec3(0.0, 1.0, 0.0));
	float t = 0.0;
	for (int i = 0; i < MAX_STEPS; i++) {
		vec3 p = fma(dir, vec3(t), origin);
		float res = sdf(p);
		if (res < (MIN_DISTANCE))
			return RayHit(t, 0, normal(p));
		if (res > MAX_DISTANCE)
			return dummy;
		t += res;
	}

	return dummy;
}
float map(float value, float min1, float max1, float min2, float max2) {
	return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

void main() {
	ivec2 pixelCoord = ivec2(gl_GlobalInvocationID.xy);

	vec2 pixelCoordF = vec2(pixelCoord);
	vec2 dims = vec2(float(WIDTH), float(HEIGHT));
	vec2 uv = pixelCoordF / dims * 2.0;
	uv.x = uv.x - 1.0;
	uv.y = 1.0 - uv.y;

	vec3 origin = cam_pos.xyz;
	vec3 dir = normalize(
		fma(vec3(cam_xAxis), vec3(uv.x),
			fma(vec3(cam_yAxis), vec3(uv.y),
				vec3(cam_front) * radians(cam_fov)
			)
		)
	);

	float t = time * TIMESCALE;
	for (int i = 0; i < SPHERE_COUNT; i++) {
		Sphere sp = Sphere(
			fma(sin(sp_speed[i].xyz * t), vec3(MOVESCALE), sp_pos[i].xyz),
			sp_radius[i]
		);
		localSpheres[i] = sp;
	}

	vec4 pixel = vec4(0.0);

	RayHit hit = rayMarch(origin, dir);
	if (hit.dist != -1.0) {
		pixel = vec4(hit.normal, 1.0);
		float t = dot(hit.normal, dir)
			+ time * TIMESCALE * 0.05;
		float a = 1.0; // map(hit.dist, 4.0, 12.0, 1.0, 0.5);
		pixel = vec4(palette(t).xyz, a);
	}

	imageStore(imgOutput, pixelCoord, pixel);
}
