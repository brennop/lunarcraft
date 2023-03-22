uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;
uniform mat4 modelMatrix;

vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    vec4 screenPosition = projectionMatrix * viewMatrix * modelMatrix * vertex_position;
    
    // invert y because we are drawing to a canvas
    /* screenPosition.y *= -1.0; */

    return screenPosition;
}
