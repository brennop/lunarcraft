uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;
uniform mat4 modelMatrix;

uniform vec3 lightPos;
uniform Image shadowMap;
uniform mat4 shadowProjectionMatrix;
uniform mat4 shadowViewMatrix;

uniform float time;

varying vec4 fragPosShadowSpace;

varying vec3 vertexNormal;
varying vec4 worldPosition;
varying float distance;

#ifdef VERTEX
attribute vec3 VertexNormal;

const float TIMESCALE = 1.5;

vec4 position( mat4 transform_projection, vec4 vertexPosition )
{
    worldPosition = modelMatrix * vertexPosition;

    float alpha = VertexColor.a;

    if (alpha < 1.0) {
      float y = worldPosition.y 
          + sin(time * TIMESCALE + worldPosition.x) * 0.1
          + cos(time * TIMESCALE + worldPosition.z) * 0.08;

      float z = worldPosition.z 
          + sin(time * TIMESCALE + worldPosition.x) * 0.04
          + cos(time * TIMESCALE + worldPosition.y) * 0.02;

      float x = worldPosition.x 
          + sin(time * TIMESCALE + worldPosition.y) * 0.02
          + cos(time * TIMESCALE + worldPosition.z) * 0.01;

      worldPosition.y = y;
      worldPosition.z = z;
      worldPosition.x = x;
    }

    vertexNormal = VertexNormal;

    fragPosShadowSpace = shadowProjectionMatrix * shadowViewMatrix * worldPosition;

    distance = length((viewMatrix * worldPosition).xyz);
    
    return projectionMatrix * viewMatrix * worldPosition;
}
#endif

#ifdef PIXEL
float calculateShadow(vec4 fragPosLightSpace, float lightDot)
{
    // perform perspective divide
    vec3 projCoords = fragPosLightSpace.xyz / fragPosLightSpace.w;

    // transform to [0,1] range
    projCoords = projCoords * 0.5 + 0.5;

    float closestDepth = Texel(shadowMap, projCoords.xy).r;
    // get depth of current fragment from light's perspective
    float currentDepth = projCoords.z;

    // check whether current frag pos is in shadow
    float bias = 0;
    float shadow = 0;

     // TODO: use textureSize instead of hardcode resolution
    vec2 texelSize = vec2(1.0 / 2048.0, 1.0 / 2048.0);

    for(int x = -2; x <= 2; ++x)
    {
      for(int y = -2; y <= 2; ++y)
      {
        float pcfDepth = Texel(shadowMap, projCoords.xy + vec2(x, y) * texelSize).r;
        shadow += currentDepth - bias > pcfDepth ? 1.0 : 0.0;
      }
    }

    shadow /= 25.0;

    if (projCoords.z > 1.0)
      shadow = 0.0;

    return shadow;
}


uniform Image bayer;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec3 lightDir = normalize(lightPos - worldPosition.xyz);
    float lightDot = dot(vertexNormal, lightDir);

    float diff = max(lightDot, 0.0) + 0.5;
    float shadow = 1.0 - calculateShadow(fragPosShadowSpace, lightDot);

    vec3 lightColor = vec3(0.85, 0.95, 0.55);

    vec3 ambient = 0.6 * lightColor;
    vec3 diffuse = diff * lightColor;

    vec4 light = vec4(ambient + diffuse * shadow, 1.0);

    vec4 texturecolor = Texel(tex, texture_coords);
    vec4 f = texturecolor * color * light;
    float alpha = f.a;

    vec2 ditherIndex = vec2(mod(screen_coords.x, 8.0), mod(screen_coords.y, 8.0));
    float dither = Texel(bayer, ditherIndex / 8.0).r;

    if (dither > alpha)
      discard;

    f.a = 1.0;

    float fogAmount = 1.0 - exp(-distance * 0.01);
    vec4 fogColor = vec4(0.4, 0.45, 0.5, 1.0);
    f = mix(f, fogColor, fogAmount);

    return f;
}
#endif
