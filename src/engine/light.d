module engine.light;

import engine.base;

class Light
{
    vec3 ambient = vec3(0.05);
    vec3 diffuse = vec3(1);
    vec3 specular = vec3(1);
    vec3 attenuation = vec3( 1, 0.1, 0.01 );
    vec3 pos = vec3( 0, 0, 1 );

    float time = 0;
    void idle( float dt )
    {
        time += dt;
        import std.math;

        auto t = time * 2;

        pos.xy = vec2( cos(t), sin(t) ) * 5;
    }
}
