//### vert
#version 330

layout(location=0) in vec2 vertex;

out vec2 uv;

void main()
{
    gl_Position = vec4( vertex, 0, 1 );
    uv = vertex / 2.0f + 0.5f;
}

//### frag
#version 330

in vec2 uv;

uniform bool simple;

uniform sampler2D tex;

uniform mat4 p2cs; // projection to camera space

uniform sampler2D depth;
uniform sampler2D diffuse;
uniform sampler2D normal;
uniform sampler2D specular;

out vec4 result;

void main()
{
    if( simple ) result = texture( tex, uv );
    else
    {
        result = ( texture( depth, uv ) +
                   texture( diffuse, uv ) +
                   texture( normal, uv ) +
                   texture( specular, uv ) ) / 4;
    }
}
