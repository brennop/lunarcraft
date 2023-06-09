uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;
uniform mat4 modelMatrix;
uniform float time;
uniform bool shouldAnimate;

uniform vec3 lightPos;
uniform Image shadowMap;
uniform mat4 shadowProjectionMatrix;
uniform mat4 shadowViewMatrix;

varying vec4 fragPosShadowSpace;

varying vec3 vertexNormal;
varying vec4 worldPosition;

#ifdef VERTEX
attribute vec3 VertexNormal;

const float TIMESCALE = 1.5;

vec4 position( mat4 transform_projection, vec4 vertexPosition )
{
    worldPosition = modelMatrix * vertexPosition;

    if (shouldAnimate) {
      // use time and sin to animate vertex y
      float y = worldPosition.y 
        + sin(time * TIMESCALE + worldPosition.x) * 0.1
        + cos(time * TIMESCALE + worldPosition.z) * 0.08;

      worldPosition.y = y;
    }


    vertexNormal = VertexNormal;

    fragPosShadowSpace = shadowProjectionMatrix * shadowViewMatrix * worldPosition;

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

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec3 lightDir = normalize(lightPos - worldPosition.xyz);
    float lightDot = dot(vertexNormal, lightDir);

    float diff = max(lightDot, 0.0) + 0.5;
    float shadow = 1.0 - calculateShadow(fragPosShadowSpace, lightDot);

    vec3 lightColor = vec3(0.8, 0.85, 0.65);

    vec3 ambient = 0.7 * lightColor;
    vec3 diffuse = diff * lightColor;

    vec4 light = vec4(ambient + diffuse * shadow, 1.0);

    vec4 texturecolor = Texel(tex, texture_coords);
    return texturecolor * color * light;
}
#endif
