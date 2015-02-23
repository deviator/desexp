module sp.engine.render;

import sp.engine.base;
import sp.engine.light;

import des.util.helpers;

class SPRender : GLRender
{
    mixin DES;

protected:

    CommonGLShaderProgram shader;
    SPScreenPlane screen;

    uint[string] named_colors;

    void setNamedColor( string name, GLTexture tx, uint N )
    {
        setColor( tx, N );
        named_colors[name] = N;
    }

public:

    this( uint[string] frag_info )
    {
        super();
        uint tu = 0;
        setDepth( defaultDepth( tu++ ) );

        int[] draw_bufs;

        foreach( key, val; frag_info )
        {
            setNamedColor( key, defaultColor(tu), val );
            logger.Debug( "set color '%s' at unit %d as COLOR%d", key, tu, val );
            tu++;
            draw_bufs ~= val;
        }

        fbo.drawBuffers( draw_bufs.sort );

        resize( uivec2( 1600, 1200 ) );

        enum sp = bnPath( "shaders", "sp_fbo_shader.glsl" );
        auto ss = parseGLShaderSource( import(sp) );
        shader = newEMM!CommonGLShaderProgram( ss );

        screen = newEMM!SPScreenPlane;
    }

    ///
    override void bind()
    {
        super.bind();
        checkGLCall!glClearDepth( 1.0 );
        checkGLCall!glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    }

    Camera cam;
    SPLight light;

    ///
    void draw( GLTexture tex = null )
    {
        shader.use();
        setLightByName( "light", cam, light );
        auto p2cs = cam.projectMatrix.inv;
        shader.setUniform!mat4( "p2cs", p2cs );
        shader.setTexture( "depth", getDepth() );

        foreach( name, N; named_colors )
            shader.setTexture( name, getColor(N) );

        bool simple = tex !is null;
        shader.setUniform!bool( "simple", simple );
        if( simple )
            shader.setTexture( "tex", tex );

        screen.draw();
    }

protected:

    void setLightByName( string name, Camera cam, SPLight ll )
    {
        shader.setUniform!int ( name ~ ".type", ll.type );
        shader.setUniform!vec3( name ~ ".ambient", ll.ambient );
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
}

///
class SPScreenPlane : GLObject
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
