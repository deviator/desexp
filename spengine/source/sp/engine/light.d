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
    GLTexture color;

    GLFrameBuffer fbo;

    this( uint smtu )
    {
        shadow_map = newEMM!GLTexture( GLTexture.Target.T2D, smtu );
        shadow_map.setWrapS( GLTexture.Wrap.CLAMP_TO_EDGE );
        shadow_map.setWrapT( GLTexture.Wrap.CLAMP_TO_EDGE );
        shadow_map.setMinFilter( GLTexture.Filter.NEAREST );
        shadow_map.setMagFilter( GLTexture.Filter.NEAREST );
        shadow_map.image( ivec2(800,800), GLTexture.InternalFormat.DEPTH32F,
                          GLTexture.Format.DEPTH, GLTexture.Type.FLOAT );

        fbo = newEMM!GLFrameBuffer;
        fbo.setAttachment( shadow_map, fbo.Attachment.DEPTH );
        fbo.check();
        fbo.unbind();

        ltr = new LookAtTransform;
        transform = ltr;
        ltr.up = vec3(0,0,1);
        ltr.target = vec3(0,0,0);

        auto pp = new OrthoTransform;
        pp.scale = 2;
        pp.ratio = 1;
        pp.near = 0.1;
        pp.far = 254;
        projection = pp;

        resolver = new Resolver;
    }

    void idle( float dt ) {}

    int[4] vpbuf;

    void bind()
    {
        fbo.bind();
        checkGLCall!glGetIntegerv( GL_VIEWPORT, vpbuf.ptr );
        checkGLCall!glViewport( 0, 0, 800, 800 );
        glEnable(GL_DEPTH_TEST);
        checkGLCall!glClearDepth(1.0);
        //checkGLCall!glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
        //checkGLCall!glDepthMask(GL_TRUE);
        checkGLCall!glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
        checkGLCall!glCullFace(GL_FRONT);
    }

    void unbind()
    {
        fbo.unbind();
        checkGLCall!glViewport( vpbuf[0], vpbuf[1], vpbuf[2], vpbuf[3] );
        //checkGLCall!glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
        checkGLCall!glCullFace(GL_BACK);
    }
}
