//### vert
#version 330
layout(location=0) in vec3 vertex;
layout(location=1) in vec4 color;
layout(location=2) in vec3 normal;
layout(location=3) in vec3 tangent;
layout(location=4) in vec3 bitangent;
layout(location=5) in vec2 texcoord;

uniform mat4 prj;
uniform mat4 tr;

out vec3 vertex0;
out vec4 color0;
out vec3 normal0;
out vec3 tangent0;
out vec3 bitangent0;
out vec2 texcoord0;

void main()
{
    gl_Position = projection * vec4( vertex, 1 );
}

//### frag

in vec3 vertex;
in vec4 color;
in vec3 normal;
in vec3 tangent;
in vec3 bitangent;
in vec2 texcoord;

layout(location=0) out vec4 diffuse;
layout(location=1) out vec3 normals;
layout(location=2) out vec3 normals;

