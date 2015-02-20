//### vert
#version 330

in vec3 vertex;
in vec2 texcoord;
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
    vert.uv = texcoord;
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

uniform struct Light
{
    int  type;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    vec3 attenuation;
    bool use_shadow;
    sampler2D shadow_map;
    vec3 cspos;
    mat4 fragtr;
    mat4 mtr;
} light;

vec4 getValue( TxData tx, vec2 uv, bool nut=false )
{
    if( !tx.use_tex || nut ) return tx.val;
    else return texture2D( tx.tex, uv );
}

mat3 tangentSpace()
{
    vec3 n = normalize( vert.norm );
    vec3 t = normalize( vert.tang );
    vec3 b = normalize( cross( n, t ) );
    return mat3( t, b, n );
}

uniform struct AttribUse
{
    bool texcoord;
    bool normal;
    bool tangent;
} attrib_use;

out vec4 color;

float getShadow( sampler2D sm, vec4 crd, ivec2 offset )
{
    return ( textureOffset( sm, crd.xy / crd.w, offset ).r < crd.z / crd.w - 0.005 ) ? 1.0 : 0.0;
}

float getSmoothShadow( sampler2D sm, vec4 crd )
{
    float ret = 0.0;

    ret += getShadow( sm, crd, ivec2( 1, 1) );
    ret += getShadow( sm, crd, ivec2( 1, 0) );
    ret += getShadow( sm, crd, ivec2( 1,-1) );

    ret += getShadow( sm, crd, ivec2( 0, 1) );
    ret += getShadow( sm, crd, ivec2( 0, 0) );
    ret += getShadow( sm, crd, ivec2( 0,-1) );

    ret += getShadow( sm, crd, ivec2(-1, 1) );
    ret += getShadow( sm, crd, ivec2(-1, 0) );
    ret += getShadow( sm, crd, ivec2(-1,-1) );

    return ret / 9;
}

/// ambient, diffuse, specular
vec3[3] calcLight( Light ll, vec3 pos, vec3 norm )
{
    vec3[3] ret;
    ret[0] = vec3(0);
    ret[1] = vec3(0);
    ret[2] = vec3(0);

    if( ll.type < 0 ) return ret;

    vec3 lvec = ll.cspos - pos;
    vec3 ldir = normalize( lvec );
    float ldst = length( lvec );
    float visible = 1.0;

    if( ll.use_shadow )
    {
        vec4 smcoord = ll.fragtr * vec4( pos, 1 );
        //lighted = textureProj( ll.shadow_map, smcoord ) * 0.8 + 0.2;
        visible = 1 - getSmoothShadow( ll.shadow_map, smcoord ) * 0.8;
    }

    float atten = 1.0f / ( ll.attenuation.x +
                           ll.attenuation.y * ldst + 
                           ll.attenuation.z * ldst * ldst );

    float nxdir = max( 0.0, dot( norm, ldir ) );

    ret[0] = ll.ambient;
    ret[1] = ll.diffuse * nxdir * atten * visible;

    if( nxdir != 0.0 )
    {
        vec3 cvec = normalize( -pos );
        vec3 hv = normalize( lvec + cvec );
        float nxhalf = max( 0.0, dot( norm, hv ) );
        ret[2] = ll.specular * pow( nxhalf, 2 ) * atten * visible;
    }

    return ret;
}

void main()
{
    vec2 bump_tr = material.bump_tr;
    bool nutc = false;
    bool nutt = false;

    if( !attrib_use.texcoord )
    {
        nutc = true;
        nutt = true;
    }

    if( !attrib_use.normal )
    {
        color = getValue( material.diffuse, vert.uv, nutc );
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

    vec3 normal = normalize( ts * ( getValue( material.normal, uv, nutt ).xyz * 2 - vec3(1) ) );

    vec3[3] lr = calcLight( light, vert.pos, normal );

    color = vec4( lr[0], 1.0 ) +
            vec4( lr[1], 1.0 ) * getValue( material.diffuse, uv, nutc ) +
            vec4( lr[2], 1.0 ) * getValue( material.specular, uv, nutc );
}
