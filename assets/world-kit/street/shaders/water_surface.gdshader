shader_type canvas_item;

uniform vec4 deep_color : source_color = vec4(0.15, 0.34, 0.45, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.30, 0.64, 0.59, 1.0);
uniform vec4 foam_color : source_color = vec4(0.76, 0.89, 0.76, 1.0);
uniform float shore_width : hint_range(1.0, 64.0, 1.0) = 14.0;
uniform float wave_speed : hint_range(0.0, 2.0, 0.05) = 1.0;

varying float distance_to_shore;
varying vec2 world_pixel;

void vertex() {
	// The rectangle's local top edge is the shoreline.
	distance_to_shore = VERTEX.y;
	// Demo levels scale the whole pixel grid up together with the player.
	float pixel_scale = length(MODEL_MATRIX[0].xy);
	world_pixel = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy / pixel_scale;
}

float hash_pixel(vec2 point) {
	vec3 mixed = fract(vec3(point.xyx) * 0.1031);
	mixed += dot(mixed, mixed.yzx + 33.33);
	return fract((mixed.x + mixed.y) * mixed.z);
}

float ripples(vec2 pixel, float frame) {
	vec2 cell_size = vec2(26.0, 10.0);
	vec2 cell = floor(pixel / cell_size);
	vec2 position_in_cell = mod(pixel, cell_size);
	float phase = mod(frame + floor(hash_pixel(cell) * 29.0), 29.0);
	float start = 3.0 + floor(hash_pixel(cell + 7.0) * 9.0) + floor(phase / 7.0);
	float width = 3.0 + floor(hash_pixel(cell + 12.0) * 7.0);
	float row = 2.0 + floor(hash_pixel(cell + 19.0) * 6.0);
	float crest = step(start, position_in_cell.x) * (1.0 - step(start + width, position_in_cell.x));
	float second_crest = step(start + 2.0, position_in_cell.x) * (1.0 - step(start + width - 1.0, position_in_cell.x));
	float visible = step(3.0, phase) * (1.0 - step(24.0, phase));
	float strength = mix(0.07, 0.21, step(7.0, phase) * (1.0 - step(17.0, phase)));
	return visible * strength * (crest * float(position_in_cell.y == row)
		+ second_crest * float(position_in_cell.y == row + 1.0) * 0.42);
}

void fragment() {
	vec2 pixel = floor(world_pixel);
	float frame = floor(TIME * 8.0 * wave_speed);
	float shore_distance = floor(distance_to_shore) + 0.5;
	float depth = floor(clamp(shore_distance / shore_width, 0.0, 1.0) * 5.0) / 5.0;
	vec3 color = mix(shallow_color.rgb, deep_color.rgb, depth);
	color = mix(color, foam_color.rgb, ripples(pixel, frame));

	float patch = hash_pixel(floor(pixel / 8.0));
	float phase = mod(frame + floor(pixel.x / 23.0) + floor(pixel.y / 43.0), 28.0);
	float runup = 1.0 + floor((16.0 - min(phase, 16.0)) * min(shore_width * 0.024, 0.36));
	float foam = step(runup, shore_distance) * (1.0 - step(runup + 1.1, shore_distance));
	float pulse = step(3.0, phase) * (1.0 - step(16.0, phase));
	float contrast = mix(0.36, 0.73, smoothstep(10.0, 24.0, shore_width));
	color = mix(color, foam_color.rgb, foam * pulse * step(0.24, patch) * contrast);
	COLOR *= vec4(color, 1.0);
}
