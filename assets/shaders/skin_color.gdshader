shader_type canvas_item;

#include "res://assets/shaders/skin_ramp.gdshaderinc"

varying vec4 item_color;

void vertex() {
	item_color = COLOR;
}

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	COLOR = vec4(dye_skin(pixel.rgb), pixel.a) * item_color;
}
