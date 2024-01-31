shader_type spatial;
// Enable rendering the backside
render_mode cull_disabled;

// Material settings
// Enables changing the material in the inspector
// We'll be interpolating between them based on the mask later
group_uniforms material;
uniform float roughnessInside: hint_range(0.0, 1.0) = 1.00;
uniform float roughnessOutside: hint_range(0.0, 1.0) = 1.00;
uniform float specularInside: hint_range(0.0, 1.0) = 0.00;
uniform float specularOutside: hint_range(0.0, 1.0) = 0.00;
uniform float metallicInside: hint_range(0.0, 1.0) = 0.00;
uniform float metallicOutside: hint_range(0.0, 1.0) = 0.00;

// Base card settings
group_uniforms baseCard;
uniform sampler2D mainTexture:
	hint_default_white,
	source_color;
uniform sampler2D backTexture:
	hint_default_white,
	source_color;
uniform vec2 uvFlip = vec2(-1.0, -1.0);
uniform vec2 aspectRatio = vec2(1.0, 1.0);
uniform float alphaThreshold:
	hint_range(0.0, 1.0) = 0.5;

// Card mask settings
group_uniforms mask;
uniform sampler2D maskTexture:
	hint_default_white,
	source_color;

// Layer 1 settings
group_uniforms layer1;
uniform float depth1: hint_range(0.0, 1.0) = 0.05;
uniform sampler2D texture1:
	hint_default_transparent,
	source_color;

// Layer 2 settings
group_uniforms layer2;
uniform float depth2: hint_range(0.0, 1.0) = 0.1;
uniform sampler2D texture2:
	hint_default_transparent,
	source_color;

// Layer 3 settings
group_uniforms layer3;
uniform float depth3: hint_range(0.0, 1.0) = 0.15;
uniform sampler2D texture3:
	hint_default_black,
	source_color;


// End of the uniforms. Now for the fun stuff.


// We'll use this later to offset the UV
// based on the view direction and depth
// This will achieve our parallax effect
vec2 getParallaxUv(vec2 uv, vec3 viewDir, float depth) {
	viewDir.xy /= (aspectRatio / length(aspectRatio));
	return clamp(
		uv + (viewDir.xy / viewDir.z) * depth,
		vec2(0.0),
		vec2(1.0)
	);
}

// Main shader loop
void fragment() {

	// Check if we need to render the front or the back
	vec4 baseColor;
	vec4 maskColor;
	if (FRONT_FACING) {

		// Get the base card texture and mask
		// We don't need to offset these
		baseColor = texture(mainTexture, UV);
		maskColor = texture(maskTexture, UV);

		// Discard (discontinue everything)
		// When card alpha is below a certain value
		if (baseColor.a < alphaThreshold) {
			discard;
		}

		// Calculate parallax if the mask isn't transparent
		// This will prevent excess texture sampling
		if (maskColor.a > 0.0) {

			// Get the view direction in tangental space
			// Aka "in relation to its normal direction"
			// We account for flipped UVs
			vec3 viewDir = normalize(
				normalize(-VERTEX) * mat3(
					TANGENT * uvFlip.x,
					-BINORMAL * uvFlip.y,
					NORMAL
				)
			);

			// We'll update this to act as the color in the mask
			vec4 insideColor = vec4(0.0);

			// We will be going in reverse layer order
			// This makes it so the background is drawn first
			// And the ones before that on top of it
			// Essentially 'overwriting' it, like a blackboard

			// Get the UV, sample layer 3 and blend
			vec2 uv3 = getParallaxUv(UV, viewDir, depth3);
			vec4 color3 = texture(texture3, uv3);
			insideColor = mix(insideColor, color3, color3.a);

			// Get the UV, sample layer 2 and blend
			vec2 uv2 = getParallaxUv(UV, viewDir, depth2);
			vec4 color2 = texture(texture2, uv2);
			insideColor = mix(insideColor, color2, color2.a);

			// Get the UV, sample layer 1 and blend
			vec2 uv1 = getParallaxUv(UV, viewDir, depth1);
			vec4 color1 = texture(texture1, uv1);
			insideColor = mix(insideColor, color1, color1.a);

			// Apply insideColor onto baseColor based on the mask alpha
			// And the insideColor's alpha too, just in case it's not 1
			baseColor.rgb = mix(
				baseColor.rgb,
				insideColor.rgb,
				maskColor.a * insideColor.a
			);

		}

	} else {

		// Get the back texture and 'mask'
		baseColor = texture(backTexture, UV);
		maskColor = vec4(0.0);

		// Discard (discontinue everything)
		// When card alpha is below a certain value
		if (baseColor.a < alphaThreshold) {
			discard;
		}

	}

    ALBEDO = baseColor.rgb;

	// Mix the inside/outside roughness and specular
	// Based on the mask blend amount (alpha)
	ROUGHNESS = mix(roughnessOutside, roughnessInside, maskColor.a);
	SPECULAR = mix(specularOutside, specularInside, maskColor.a);
	METALLIC = mix(metallicOutside, metallicInside, maskColor.a);


}