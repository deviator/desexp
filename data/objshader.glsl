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
    uint use_tex;
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
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    vec3 attenuation;
    vec3 cspos;
} light;

out vec4 color;

vec4 getValue( TxData tx, vec2 uv )
{
    if( tx.use_tex != 0u )
        return texture2D( tx.tex, uv );
    else return tx.val;
}

mat3 tangentSpace()
{
    vec3 n = normalize( vert.norm );
    vec3 t = normalize( vert.tang );
    vec3 b = normalize( cross( n, t ) );
    return mat3( t, b, n );
}

void main()
{
    mat3 ts = tangentSpace();

    float hsb = getValue( material.bump, vert.uv ).r * material.bump_tr.x -
                material.bump_tr.y;

    vec2 uv = vert.uv + normalize( (-vert.pos * ts) ).xy * hsb;

    vec3 normal = normalize( ts * ( getValue( material.normal, uv ).xyz * 2 - vec3(1) ) );

    vec3 lightVec = light.cspos - vert.pos;
    float lightDst = length( lightVec );
    vec3 lightDir = normalize( lightVec );

    float atten = 1.0f / ( light.attenuation.x +
                           light.attenuation.y * lightDst + 
                           light.attenuation.z * lightDst * lightDst );

    float nxdir = max( 0.0, dot( normal, lightDir ) );

    vec3 rlSpecular = vec3(0);
    vec3 rlDiffuse = light.diffuse * nxdir * atten;

    if( nxdir != 0.0 )
    {
        vec3 cvec = normalize( -vert.pos );
        vec3 hv = normalize( lightVec + cvec );
        float nxhalf = max( 0.0, dot( normal, hv ) );
        rlSpecular = light.specular * pow( nxhalf, 2 ) * atten;
    }

    color = vec4( light.ambient, 1.0 ) +
            vec4( rlDiffuse, 1.0 ) * getValue( material.diffuse, uv ) +
            vec4( rlSpecular, 1.0 ) * getValue( material.specular, uv );
}
