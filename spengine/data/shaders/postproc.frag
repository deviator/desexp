#version 330

in vec2 uv;

uniform mat4 p2cs; // transform to camera space

uniform sampler2D depth;
uniform sampler2D info; // r:edge
uniform sampler2D diffuse;
uniform sampler2D specular;
uniform sampler2D shade_diffuse;
uniform sampler2D shade_specular;

vec4 avgTexRect( sampler2D tex, vec2 uvcrd, int sz, bool quad )
{
    vec4 ret = vec4(0.0f);

    int ww = sz * 2 + 1;
    float N;

    if( quad )
    {
        N = ww * ww;
        for( int i=-sz; i < sz+1; i++ )
            for( int j=-sz; j < sz+1; j++ )
                ret += textureOffset( tex, uvcrd, ivec2(i,j) );
    }
    else
    {
        N = 0.0f;
        for( int i=-sz; i < sz+1; i++ )
            for( int j=-sz; j < sz+1; j++ )
            {
                float k = 1 / ( (i*i+j*j) / 2.0 + 1);
                ret += textureOffset( tex, uvcrd, ivec2(i,j) ) * k;
                N += k;
            }
    }

    return ret / N;
}

// texture anti alias
vec4 textureAA( sampler2D tex, vec2 uvcrd, float df )
{
    if( df < 0.5 ) return texture( tex, uvcrd );
    else return avgTexRect( tex, uvcrd, 2, false );
}

uniform bool aliased;

out vec4 result;

void main()
{
    float df = avgTexRect( info, uv, 2, true ).r * 25;
    if( aliased )
        result = textureAA( shade_diffuse, uv, df ) * texture( diffuse, uv ) +
                textureAA( shade_specular, uv, df ) * texture( specular, uv );
    else
        result = texture( shade_diffuse, uv ) * texture( diffuse, uv ) +
                texture( shade_specular, uv ) * texture( specular, uv );
}
