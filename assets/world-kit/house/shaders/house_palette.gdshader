shader_type canvas_item;

// Mask IDs: 0 fixed details, 1 wood, 2 paint/metal, 3 fabric, 4 plaster, 5 stone, 6 roof tiles.
uniform sampler2D material_mask : filter_nearest, repeat_enable;
uniform vec4 wood_color : source_color = vec4(0.682353, 0.490196, 0.274510, 1.0);
uniform vec4 paint_color : source_color = vec4(0.490196, 0.588235, 0.403922, 1.0);
uniform vec4 fabric_color : source_color = vec4(0.631373, 0.415686, 0.454902, 1.0);
uniform vec4 plaster_color : source_color = vec4(0.866667, 0.803922, 0.670588, 1.0);
uniform vec4 stone_color : source_color = vec4(0.705882, 0.666667, 0.541176, 1.0);
uniform vec4 roof_color : source_color = vec4(0.721569, 0.462745, 0.305882, 1.0);
uniform vec4 opening_a = vec4(0.0);
uniform vec4 opening_b = vec4(0.0);
uniform vec4 opening_c = vec4(0.0);
varying vec2 pixel_position;
varying vec4 item_color;
bool in_opening(vec2 point, vec4 rect) {
 return rect.z > 0.0 && point.x >= rect.x && point.x < rect.x + rect.z && point.y >= rect.y && point.y < rect.y + rect.w;
}

void vertex() {
	item_color = COLOR;
	pixel_position = VERTEX;
}

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	int material_id = int(round(texture(material_mask, UV).r * 255.0));
	vec3 base = pixel.rgb;
	if (material_id == 1) { base = wood_color.rgb; }
	else if (material_id == 2) { base = paint_color.rgb; }
	else if (material_id == 3) { base = fabric_color.rgb; }
	else if (material_id == 4) { base = plaster_color.rgb; }
	else if (material_id == 5) { base = stone_color.rgb; }
	else if (material_id == 6) { base = roof_color.rgb; }
	if (material_id >= 1 && material_id <= 6) {
		// The four neutral shades encode the approved shadows and highlights.
		int shade = int(round((pixel.r * 255.0 - 45.0) / 60.0));
		if (shade <= 0) { base = mix(base, vec3(48.0, 45.0, 43.0) / 255.0, 0.52); }
		else if (shade == 1) { base = mix(base, vec3(68.0, 56.0, 46.0) / 255.0, 0.25); }
		else if (shade >= 3) { base = mix(base, vec3(246.0, 230.0, 192.0) / 255.0, 0.30); }
		pixel.rgb = floor(base * 255.0 + 0.5) / 255.0;
	}
	// Retain CanvasItem opacity, including TransparencyArea and parent modulation.
	if (in_opening(pixel_position, opening_a) || in_opening(pixel_position, opening_b) || in_opening(pixel_position, opening_c)) {
  pixel.a = 0.0;
 }
 COLOR = pixel * item_color;
}
