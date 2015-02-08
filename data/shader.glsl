//### vert
#version 330
in vec3 in_pos;
in vec2 in_uv;
in vec3 in_norm;

uniform mat4 prj;

out vec3 pos;
out vec2 uv;
out vec3 v_norm;

void main()
{
    gl_Position = prj * vec4( in_pos, 1.0 );
    pos = in_pos;
    uv = in_uv;
    v_norm = in_norm;
}

//### frag
#version 330

in vec3 pos;
in vec2 uv;
in vec3 v_norm;

uniform sampler2D ttu;
uniform vec3 campos;
uniform vec3 light1;
uniform vec3 light2;
uniform uint use_texture;

vec4[3] calcLight( vec4 ambient, vec4 diffuse, vec4 specular, 
                   vec3 attenuation, vec3 lpos, vec3 cpos,
                   vec3 pos, vec3 norm )
{
    vec4 ret[3];

    ret[2] = vec4(0.0f);
    ret[0] = ambient;

    vec3 lvec = lpos - pos;
    float dist = length( lvec );
    vec3 ldir = normalize( lvec );

    float atten = 1.0f / ( attenuation.x +
                           attenuation.y * dist + 
                           attenuation.z * dist * dist );

    float nxdir = max( 0.0, dot( norm, ldir ) );

    ret[1] = diffuse * nxdir * atten;

    if( nxdir != 0.0 )
    {
        vec3 cvec = normalize( cpos - pos );
        vec3 hv = normalize( lvec + cvec );
        float nxhalf = max( 0.0, dot( norm, hv ) );
        ret[2] = specular * pow( nxhalf, 2 ) * atten;
    }

    return ret;
}

void main(void)
{

    vec4 a1 = vec4(0.005,0.005,.01,1);
    vec4 a2 = vec4(0.01,0.01,.005,1);

    vec4 d1 = vec4(0.25,0.25,0.3,1) * 10;
    vec4 d2 = vec4(0.3,0.3,0.25,1) * 10;

    vec4 clrs1[3] = calcLight( a1, d1, vec4(0.5f),
                               vec3(1,0.1,0.01), light1, campos,
                               pos, normalize( v_norm ) );

    vec4 clrs2[3] = calcLight( a2, d2, vec4(0.5f),
                               vec3(1,0.1,0.01), light2, campos,
                               pos, normalize( v_norm ) );

    vec4 clrs[3];
    for( int i = 0; i < 3; i++ )
        clrs[i] = clrs1[i] + clrs2[i];

    vec4 tc;
    if( use_texture > 0u )
        tc = texture2D( ttu, uv );
    else
        tc = vec4(1,0,0,1);
    gl_FragColor = clrs[0] +
                   clrs[1] * vec4( tc.rgb, 1.0 ) +
                   clrs[2] * tc.a;
}
