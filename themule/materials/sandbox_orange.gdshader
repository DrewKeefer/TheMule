shader_type spatial;

uniform vec4 base_color : source_color = vec4(1.0, .35, 0.0, 1.0); // Orange color
uniform vec4 grid_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Grid color
uniform float grid_size : hint_range(0.0, 5.0, 0.1) = 0.5; // Grid spacing
uniform float line_width : hint_range(0.0, 0.5, 0.001) = 0.01; // Line thickness
uniform float smoothing_distance : hint_range(0.0, 0.05, 0.001) = 0.005; // Smoothing distance

varying vec3 local_pos;
varying vec3 local_normal;

void vertex() {
	local_pos = VERTEX;
	local_normal = NORMAL;
}

void fragment() {
		// Determine dominant axis to project onto (similar to triplanar mapping)
	vec3 abs_normal = abs(local_normal);
	vec2 uv;

	if (abs_normal.x > abs_normal.y && abs_normal.x > abs_normal.z) {
		uv = local_pos.yz; // X face
	} else if (abs_normal.y > abs_normal.z) {
		uv = local_pos.xz; // Y face (top/bottom)
	} else {
		uv = local_pos.xy; // Z face
	}

	// Grid logic
	vec2 grid = mod(uv, grid_size);

	float softness = 0.1;
	float line_u = 1.0 - smoothstep(line_width - smoothing_distance, line_width, grid.x) * smoothstep(line_width - smoothing_distance, line_width, grid_size - grid.x);
	float line_v = 1.0 - smoothstep(line_width - smoothing_distance, line_width, grid.y) * smoothstep(line_width - smoothing_distance, line_width, grid_size - grid.y);
	float line = max(line_u, line_v);

	vec3 color = mix(base_color.rgb, grid_color.rgb, line);

	ALBEDO = color;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
