#ifdef GL_ES
precision highp float;
#endif

#if __VERSION__ >= 140
	in vec4 Color0;
	in vec2 TexCoord0;
	in vec4 ColorizeOut;
	in vec3 ColorOffsetOut;
	in vec2 TextureSizeOut;
	in float PixelationAmountOut;
	in vec3 ClipPlaneOut;
	out vec4 fragColor;
#else
	varying vec4 Color0;
	varying vec2 TexCoord0;
	varying vec4 ColorizeOut;
	varying vec3 ColorOffsetOut;
	varying vec2 TextureSizeOut;
	varying float PixelationAmountOut;
	varying vec3 ClipPlaneOut;
	#define fragColor gl_FragColor
	#define texture texture2D
#endif

uniform sampler2D Texture0;
const vec3 _lum = vec3(0.212671, 0.715160, 0.072169);

void main(void)
{
	if(dot(gl_FragCoord.xy, ClipPlaneOut.xy) < ClipPlaneOut.z)
		discard;
	
	vec2 pa = vec2(1.0+PixelationAmountOut, 1.0+PixelationAmountOut) / TextureSizeOut;
	vec4 textureColor = texture(Texture0, PixelationAmountOut > 0.0 ? TexCoord0 - mod(TexCoord0, pa) + pa * 0.5 : TexCoord0);
	
	// APPEND CODE HERE
	vec4 Color = Color0 * textureColor;
	vec3 Colorized = mix(Color.rgb, dot(Color.rgb, _lum) * ColorizeOut.rgb, ColorizeOut.a);
	fragColor = vec4(Colorized + ColorOffsetOut * Color.a, Color.a);
	fragColor.rgb = mix(fragColor.rgb, fragColor.rgb - mod(fragColor.rgb, 1.0/16.0) + 1.0/32.0, clamp(PixelationAmountOut, 0.0, 1.0));
}