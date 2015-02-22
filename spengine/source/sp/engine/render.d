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
        setDepth( defaultDepth( 0 ) );
        setColor( defaultColor( 1 ), 0 ); // color
        setColor( defaultColor( 2 ), 1 ); // diffuse
        setColor( defaultColor( 3 ), 2 ); // normal
        setColor( defaultColor( 4 ), 3 ); // specular
        fbo.drawBuffers( 0, 1, 2, 3 );

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

    ///
    void draw( GLTexture tex = null )
    {
        shader.use();
        bool simple = tex !is null;
        shader.setUniform!bool( "simple", simple );
        if( simple ) setTexture( "tex", tex );
        else
        {
            //shader.setUniform!mat4( "p2cs", cam.projectMatrix.inv );
            setTexture( "depth", getDepth() );
            setTexture( "diffuse", getColor(1) );
            setTexture( "normal", getColor(2) );
            setTexture( "specular", getColor(3) );
        }
        screen.draw();
    }

protected:

    void setTexture( string name, GLTexture tex )
    {
        tex.bind();
        shader.setUniform!int( name, tex.unit );
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
