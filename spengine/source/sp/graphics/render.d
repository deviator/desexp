module sp.graphics.render;

import sp.graphics.base;
import sp.graphics.light;

import des.stdx;

class SPGRender : DesObject
{
    mixin DES;

protected:

    GLRender r_deferrer;
    GLRender r_postproc;

    CommonGLShaderProgram sp_deferrer;
    CommonGLShaderProgram sp_postproc;
    CommonGLShaderProgram sp_simpletex;

    SPGScreenPlane screen;

public:

    GLTexture t_depth;
    GLTexture t_diffuse;
    GLTexture t_normal;
    GLTexture t_specular;
    GLTexture t_shade_diffuse;
    GLTexture t_shade_specular;
    GLTexture t_info;

    this()
    {
        prepareTextures();
        prepareShaders();
        prepareRenders();

        resize( uivec2( 1600, 1200 ) );

        screen = newEMM!SPGScreenPlane;
    }

    ///
    void bind()
    {
        r_deferrer.bind();
        checkGLCall!glClearDepth( 1.0 );
        checkGLCall!glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    }

    ///
    void unbind()
    {
        r_deferrer.unbind();
    }

    Camera cam;
    SPGLight light;

    bool aliased;

    ///
    void draw()
    {
        r_postproc.bind();

        sp_deferrer.use();
        setLightByName( sp_deferrer, "light", cam, light );

        auto p2cs = cam.projectMatrix.inv;
        sp_deferrer.setUniform!mat4( "p2cs", p2cs );
        sp_deferrer.setTexture( "depth", t_depth );
        sp_deferrer.setTexture( "normal", t_normal );

        screen.draw();

        r_postproc.unbind();

        sp_postproc.use();
        //sp_postproc.setUniform!mat4( "p2cs", p2cs );
        //sp_postproc.setTexture( "depth", t_depth );
        sp_postproc.setTexture( "info", t_info );
        sp_postproc.setTexture( "diffuse", t_diffuse );
        sp_postproc.setTexture( "specular", t_specular );
        sp_postproc.setTexture( "shade_diffuse", t_shade_diffuse );
        sp_postproc.setTexture( "shade_specular", t_shade_specular );
        sp_postproc.setUniform!bool( "aliased", aliased );

        screen.draw();
    }

    void drawTexture( GLTexture tex )
    {
        sp_simpletex.use();
        sp_simpletex.setTexture( "tex", tex );
        screen.draw();
    }

    void resize(T)( in T w, in T h )
    if( isIntegral!T )
    in
    {
        assert( w > 0 );
        assert( h > 0 );
    }
    body { resize( uivec2( w, h ) ); }

    void resize( uivec2 sz )
    {
        r_deferrer.resize( sz );
        r_postproc.resize( sz );
    }

protected:

    void prepareTextures()
    {
        t_depth = defaultDepth(0);
        t_diffuse = defaultColor(1);
        t_normal = defaultColor(2);
        t_specular = defaultColor(3);
        t_shade_diffuse = defaultColor(4);
        t_shade_specular = defaultColor(5);
        t_info = defaultColor(6);
    }

    void prepareShaders()
    {
        static auto shdir( string[] path... )
        { return bnPath( ["shaders"] ~ path ); }

        auto screen_v = newEMM!GLVertShader( import( shdir( "screen.vert" ) ) );

        auto deferrer_f = new GLFragShader( import( shdir( "drshade.frag" ) ) );
        auto postproc_f = new GLFragShader( import( shdir( "postproc.frag" ) ) );
        auto simpletex_f = new GLFragShader( import( shdir( "simpletexture.frag" ) ) );

        sp_deferrer = newEMM!CommonGLShaderProgram( [ screen_v, deferrer_f ] );
        sp_postproc = newEMM!CommonGLShaderProgram( [ screen_v, postproc_f ] );
        sp_simpletex = newEMM!CommonGLShaderProgram( [ screen_v, simpletex_f ] );
    }

    void prepareRenders()
    {
        r_deferrer = newEMM!GLRender;
        r_deferrer.setDepth( t_depth );
        r_deferrer.setColor( t_diffuse, 0 );
        r_deferrer.setColor( t_normal, 1 );
        r_deferrer.setColor( t_specular, 2 );
        r_deferrer.drawBuffers( 0, 1, 2 );

        r_postproc = newEMM!GLRender;
        r_postproc.setColor( t_shade_diffuse, 0 );
        r_postproc.setColor( t_shade_specular, 1 );
        r_postproc.setColor( t_info, 2 );
        r_postproc.drawBuffers( 0, 1, 2 );
    }

    ///
    void setLightByName( CommonGLShaderProgram shader, string name,
                         Camera cam, SPGLight ll )
    {
        shader.setUniform!int ( name ~ ".type", ll.type );
        shader.setUniform!vec3( name ~ ".diffuse", ll.diffuse );
        shader.setUniform!vec3( name ~ ".specular", ll.specular );
        shader.setUniform!vec3( name ~ ".attenuation", ll.attenuation );
        shader.setUniform!bool( name ~ ".use_shadow", ll.use_shadow );
        shader.setTexture( name ~ ".shadow_map", ll.shadowMap );
        auto crl = cam.resolve(ll);
        shader.setUniform!vec3( name ~ ".cspos", crl.offset );
        auto bais = mat4( .5,  0,  0, .5,
                           0, .5,  0, .5,
                           0,  0, .5, .5,
                           0,  0,  0,  1 );
        auto cam2light = ll.projectMatrix * crl.speedTransformInv;
        shader.setUniform!mat4( name ~ ".fragtr", bais * cam2light );
    }

    ///
    GLTexture defaultDepth( uint unit )
    {
        auto tex = createDefaultTexture( unit );
        tex.image( ivec2(1,1), GLTexture.InternalFormat.DEPTH32F,
            GLTexture.Format.DEPTH, GLTexture.Type.FLOAT );
        return tex;
    }

    ///
    GLTexture defaultColor( uint unit )
    {
        auto tex = createDefaultTexture( unit );
        tex.image( ivec2(1,1), GLTexture.InternalFormat.RGBA,
            GLTexture.Format.RGBA, GLTexture.Type.FLOAT );
        return tex;
    }

    ///
    GLTexture createDefaultTexture( uint unit )
    {
        auto tex = newEMM!GLTexture( GLTexture.Target.T2D, unit );
        tex.setWrapS( GLTexture.Wrap.CLAMP_TO_EDGE );
        tex.setWrapT( GLTexture.Wrap.CLAMP_TO_EDGE );
        tex.setMinFilter( GLTexture.Filter.NEAREST );
        tex.setMagFilter( GLTexture.Filter.NEAREST );
        return tex;
    }
}

///
class SPGScreenPlane : GLObject
{
    ///
    GLBuffer vert;

    ///
    this()
    {
        vert = newEMM!GLBuffer();
        vert.setData( [ vec2( 1, 1), vec2( 1,-1), vec2(-1, 1),
                        vec2( 1,-1), vec2(-1,-1), vec2(-1, 1) ] );
        setAttribPointer( vert, 0, 2, GLType.FLOAT );
    }

    ///
    void draw() { drawArrays( DrawMode.TRIANGLES, vert.elementCount ); }
}
