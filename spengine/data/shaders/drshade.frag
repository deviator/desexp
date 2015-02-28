#version 330

in vec2 uv;

uniform mat4 p2cs; // transform to camera space

uniform sampler2D depth;
uniform sampler2D normal;

uniform struct Light
{
    int  type;
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

/// diffuse, specular
vec3[2] calcLight( Light ll, vec3 pos, vec3 norm, float spow )
{
    vec3[2] ret;
    ret[0] = vec3(0);
    ret[1] = vec3(0);

    if( ll.type < 0 ) return ret;

    vec3 lvec = ll.cspos - pos;
    vec3 ldir = normalize( lvec );
    float ldst = length( lvec );
    float visible = 1.0;

    if( ll.use_shadow )
    {
        vec4 smcoord = ll.fragtr * vec4( pos, 1 );
        visible = 1.0f - getSmoothShadow( ll.shadow_map, smcoord ) * 0.8;
    }

    float atten = 1.0f / ( ll.attenuation.x +
                           ll.attenuation.y * ldst +
                           ll.attenuation.z * ldst * ldst );

    float nxdir = max( 0.0, dot( norm, ldir ) );

    ret[0] = ll.diffuse * nxdir * atten * visible;

    if( nxdir > 0 )
    {
        vec3 cvec = normalize( -pos );
        vec3 hv = normalize( lvec + cvec );
        float nxhalf = max( 0.0, dot( norm, hv ) );
        ret[1] = ll.specular * pow( nxhalf, spow ) * atten * visible;
    }

    return ret;
}

vec4 diff( sampler2D map, vec4 c, vec2 crd, ivec2 o1, ivec2 o2 )
{ return ( c - textureOffset( map, crd, o1 ) ) - ( textureOffset( map, crd, o2 ) - c ); }

float avgComp( vec4 ov, int cmp )
{
    vec4 v = abs(ov);
    if( cmp == 1 ) return v.r;
    if( cmp == 2 ) return ( v.r + v.g ) / 2.0f;
    if( cmp == 3 ) return ( v.r + v.g + v.b ) / 3.0f;
    if( cmp == 4 ) return ( v.r + v.g + v.b + v.a ) / 4.0f;
}

float edgeDetect( sampler2D map, vec2 crd, int cmp )
{
    float ret = 0.0f;

    vec4 c = texture( map, crd );
    ret += avgComp( diff( map, c, crd, ivec2(1,0), ivec2(-1,0) ), cmp ); // horisontal
    ret += avgComp( diff( map, c, crd, ivec2(0,1), ivec2(0,-1) ), cmp ); // vertical
    ret += avgComp( diff( map, c, crd, ivec2(1,1), ivec2(-1,-1) ), cmp ); // diagonal 1
    ret += avgComp( diff( map, c, crd, ivec2(1,-1), ivec2(-1,1) ), cmp ); // diagonal 2

    return ret / 4;
}

float binThreshold( float value, float th )
{ return value > th ? 1.0f : 0.0f; }

layout(location=0) out vec4 shade_diffuse;
layout(location=1) out vec4 shade_specular;
layout(location=2) out vec4 info; // r:edge

void main()
{
    float edge = ( binThreshold( edgeDetect( normal, uv, 3 ), 0.1f ) +
                   binThreshold( edgeDetect( depth, uv, 1 ), 0.0002f ) ) / 2.0f;

    info = vec4( edge, 0, 0, 0 );

    vec4 un_pos = p2cs * vec4( uv*2-1, ( texture(depth,uv).r*2-1 ), 1 );
    vec3 pos = un_pos.xyz / un_pos.w;

    vec3 norm = normalize( texture(normal,uv).xyz*2-1 );

    vec3[2] lr = calcLight( light, pos, norm, 4 );

    shade_diffuse = vec4( lr[0], 1 );
    shade_specular = vec4( lr[1], 1 );
}
