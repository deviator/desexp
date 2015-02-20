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

uniform sampler2D tex;

void main()
{
    gl_FragColor = texture( tex, uv );
}
