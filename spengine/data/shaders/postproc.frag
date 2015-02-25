#version 330

in vec2 uv;

uniform mat4 p2cs; // transform to camera space

uniform sampler2D depth;
uniform sampler2D info; // r:edge
uniform sampler2D color;

vec4 avgTexRect( sampler2D tex, vec2 uvcrd, int sz )
{
    vec4 ret = vec4(0.0f);

    int ww = sz * 2 + 1;
    float N = ww * ww;

    for( int i=-sz; i < sz+1; i++ )
        for( int j=-sz; j < sz+1; j++ )
            ret += textureOffset( tex, uvcrd, ivec2(i,j) );

    return ret / N;
}

// texture anti alias
vec4 textureAA( sampler2D tex, vec2 uvcrd, float df )
{
    if( df < 0.1 )
        return texture( tex, uvcrd );
    else
        return avgTexRect( tex, uvcrd, 2 ) * df +
               texture( tex, uvcrd ) * ( 1 - df );
}

out vec4 result;

void main()
{
    result = textureAA( color, uv, avgTexRect( info, uv, 2 ).r );
}
