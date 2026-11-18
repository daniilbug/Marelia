shader_type canvas_item;

uniform sampler2D material_mask : filter_nearest, repeat_disable;
uniform vec4 body_color : source_color = vec4(0.725490, 0.431373, 0.360784, 1.0);
uniform vec4 support_color : source_color = vec4(0.254902, 0.290196, 0.235294, 1.0);
uniform vec4 source_body_color : source_color;
uniform vec4 source_support_color : source_color;
varying vec4 item_color;

void vertex() {
	item_color = COLOR;
}

vec3 recolor(vec3 pixel, vec3 reference, vec3 color) {
	// Preserve the approved pixels exactly when using their original base color.
	if (distance(reference, color) < 0.000001) {
		return pixel;
	}
	// Map shadows toward black and highlights toward white independently.
	// This keeps contrast even when the selected color is black or white.
	vec3 shadow = color * pixel / max(reference, vec3(0.000001));
	vec3 amount = clamp((pixel - reference) / max(vec3(1.0) - reference, vec3(0.000001)), vec3(0.0), vec3(1.0));
	vec3 highlight = mix(color, vec3(1.0), amount);
	return clamp(mix(shadow, highlight, step(reference, pixel)), vec3(0.0), vec3(1.0));
}

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	int material_id = int(round(texture(material_mask, UV).r * 255.0));
	if (material_id == 1) {
		pixel.rgb = recolor(pixel.rgb, source_body_color.rgb, body_color.rgb);
	} else if (material_id == 2) {
		pixel.rgb = recolor(pixel.rgb, source_support_color.rgb, support_color.rgb);
	}
	COLOR = pixel * item_color;
}
