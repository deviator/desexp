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

uniform mat4 p2cs; // projection to camera space
uniform sampler2D depth;

uniform sampler2D tex;
uniform sampler2D color;
uniform sampler2D diffuse_map;
uniform sampler2D normal_map;
uniform sampler2D specular_map;
uniform sampler2D position_map;

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

float getShadow( sampler2D sm, vec4 crd, ivec2 offset )
{ return ( textureOffset( sm, crd.xy / crd.w, offset ).r < crd.z / crd.w - 0.005 ) ? 1.0 : 0.0; }

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

out vec4 result;

void main()
{
    if( simple ) result = texture( tex, uv );
    else
    {
        vec4 un_pos = p2cs * vec4( uv*2-1, (texture(depth,uv).r*2-1), 1 );
        vec3 pos = un_pos.xyz / un_pos.w;
        vec3 pp0 = texture( position_map, uv ).xyz;

        vec3 norm = normalize( texture( normal_map, uv ).xyz * 2 - 1 );

        vec3[3] lr = calcLight( light, pos, norm );

        result = vec4( lr[0], 1.0 ) +
                 vec4( lr[1], 1.0 ) * texture( diffuse_map, uv ) +
                 vec4( lr[2], 1.0 ) * texture( specular_map, uv );

        result *= 0.1;
        result += vec4( pos - pp0, 1 ) * 0.1;
    }
}
