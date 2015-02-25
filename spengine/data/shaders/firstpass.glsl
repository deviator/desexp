//### vert
#version 330

in vec3 vertex;
in vec2 tcoord;
in vec3 normal;
in vec3 tangent;

uniform mat4 fprj;
uniform mat4 cspace;

out Vertex
{
    vec3 pos;
    vec2 uv;
    vec3 norm;
    vec3 tang;
} vert;

vec3 tr( mat4 mtr, vec3 v, float point )
{ return ( mtr * vec4( v, point ) ).xyz; }

void main()
{
    gl_Position = fprj * vec4( vertex, 1.0 );
    vert.uv = tcoord;
    vert.pos  = tr( cspace, vertex, 1.0 );
    vert.norm = tr( cspace, normal, 0.0 );
    vert.tang = tr( cspace, tangent, 0.0 );
}

//### frag
#version 330

in Vertex
{
    vec3 pos;
    vec2 uv;
    vec3 norm;
    vec3 tang;
} vert;

struct TxData
{
    sampler2D tex;
    vec4 val;
    bool use_tex;
};

uniform struct Material
{
    TxData diffuse;
    TxData specular;
    TxData bump;
    vec2 bump_tr;
    TxData normal;
} material;

vec4 getValue( TxData tx, vec2 uv, bool nut=false )
{
    if( !tx.use_tex || nut ) return tx.val;
    else return texture2D( tx.tex, uv );
}

// TODO: calc in vertex shader
mat3 tangentSpace()
{
    vec3 n = normalize( vert.norm );
    vec3 t = normalize( vert.tang );
    vec3 b = normalize( cross( n, t ) );
    return mat3( t, b, n );
}

uniform struct AttribUse
{
    bool tcoord;
    bool normal;
    bool tangent;
} attrib_use;

layout(location=0) out vec4 diffuse;
layout(location=1) out vec4 normal;
layout(location=2) out vec4 specular;

void main()
{
    vec2 bump_tr = material.bump_tr;
    bool nutc = false;
    bool nutt = false;

    if( !attrib_use.tcoord )
    {
        nutc = true;
        nutt = true;
    }

    if( !attrib_use.normal )
    {
        diffuse = getValue( material.diffuse, vert.uv, nutc );
        return;
    }

    if( !attrib_use.tangent )
    {
        bump_tr = vec2(0);
        nutt = true;
    }

    mat3 ts = tangentSpace();

    float hsb = getValue( material.bump, vert.uv, nutt ).r * bump_tr.x -
                bump_tr.y;

    vec2 uv = vert.uv + normalize( (-vert.pos * ts) ).xy * hsb;

    vec3 nn = normalize( ts * ( getValue( material.normal, uv, nutt ).xyz * 2 - vec3(1) ) );
    normal = vec4( nn * .5 + .5, 1 );

    diffuse = getValue( material.diffuse, uv, nutc );
    specular = getValue( material.specular, uv, nutc );
}
