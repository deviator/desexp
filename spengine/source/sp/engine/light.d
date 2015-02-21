module sp.engine.light;

import sp.engine.base;

class SPLight : DesObject, Camera
{
    mixin DES;
    mixin CameraHelper;

    LookAtTransform ltr;

    int type = 0;

    vec3 ambient = vec3(0.05);
    vec3 diffuse = vec3(1);
    vec3 specular = vec3(1);
    vec3 attenuation = vec3( 1, 0.1, 0.01 );

    bool use_shadow = true;

    GLTexture shadow_map;
    GLRender render;

    this( uint smtu )
    {
        render = newEMM!GLRender;
        shadow_map = render.defaultDepth( smtu );
        render.setDepth( shadow_map );
        render.resize( 800, 800 );

        ltr = new LookAtTransform;
        transform = ltr;
        ltr.up = vec3(0,0,1);
        ltr.target = vec3(0,0,0);

        auto pp = new OrthoTransform;
        pp.scale = 10;
        pp.ratio = 1;
        pp.near = 0.1;
        pp.far = 100;
        projection = pp;

        resolver = new Resolver;
    }

    void idle( float dt ) {}

    void bind()
    {
        render.bind();
        glEnable( GL_DEPTH_TEST );
        checkGLCall!glClearDepth(1.0);
        checkGLCall!glClear( GL_DEPTH_BUFFER_BIT );
        checkGLCall!glCullFace( GL_FRONT );
    }

    void unbind()
    {
        render.unbind();
        checkGLCall!glCullFace( GL_BACK );
    }
}
