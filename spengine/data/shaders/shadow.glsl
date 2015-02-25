//### vert
#version 330

in vec3 vertex;

uniform mat4 fprj;

void main()
{
    gl_Position = fprj * vec4( vertex, 1.0 );
}

//### frag
#version 330
void main() {}
