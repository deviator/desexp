module sp.engine.light;

import sp.engine.base;

class SPLight : SpaceNode
{
    mixin SpaceNodeHelper;

    int type = 0;
    vec3 ambient = vec3(0.05);
    vec3 diffuse = vec3(1);
    vec3 specular = vec3(1);
    vec3 attenuation = vec3( 1, 0.1, 0.01 );

    void idle( float dt ) {}
}
