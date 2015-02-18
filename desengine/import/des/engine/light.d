module des.engine.light;

import des.engine.base;

class Light : SpaceNode
{
    mixin SpaceNodeHelper;

    vec3 ambient = vec3(0.05);
    vec3 diffuse = vec3(1);
    vec3 specular = vec3(1);
    vec3 attenuation = vec3( 1, 0.1, 0.01 );

    void idle( float dt ) {}
}
