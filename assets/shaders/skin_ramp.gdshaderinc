// The same skin ramp is baked into the body, sleeves, and swim atlases.
uniform vec4 skin_color : source_color = vec4(0.92549, 0.76078, 0.58431, 1.0);

vec3 dye_skin(vec3 pixel) {
	const vec3 base = vec3(236.0, 194.0, 149.0) / 255.0;
	const vec3 middle = vec3(220.0, 174.0, 129.0) / 255.0;
	const vec3 shadow = vec3(200.0, 155.0, 110.0) / 255.0;
	if (distance(pixel, base) < 0.002 || distance(pixel, middle) < 0.002 || distance(pixel, shadow) < 0.002) {
		return pixel * (skin_color.rgb / base);
	}
	return pixel;
}
