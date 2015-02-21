module sp.engine.render;

import sp.engine.base;

import des.util.helpers;

class SPRender : GLRender
{
    mixin DES;

    CommonGLShaderProgram shader;

    SPScreenPlane screen;

    this()
    {
        super();
        setDepth( defaultDepth( 5 ) );
        setColor( defaultColor( 6 ), 0 );
        setColor( defaultColor( 7 ), 1 );

        resize( uivec2( 800, 600 ) );
        fbo.drawBuffers( 0, 1 );

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

    ///
    void draw( GLTexture tex = null )
    {
        shader.use();
        if( tex is null ) tex = getColor(0);
        tex.bind();
        shader.setUniform!int( "tex", tex.unit );
        screen.draw();
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
