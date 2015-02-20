module sp.engine.render;

import sp.engine.base;

import des.util.helpers;

class SPRender : DesObject
{
    mixin DES;

    GLFrameBuffer fbo;
    GLTexture depth;
    GLTexture color;

    CommonGLShaderProgram shader;

    SPFBOPlane plane;

    int w = 800;
    int h = 600;

    this()
    {
        color = newEMM!GLTexture( GLTexture.Target.T2D, 5 );
        color.setMinFilter( GLTexture.Filter.NEAREST );
        color.setMagFilter( GLTexture.Filter.NEAREST );
        color.setWrapS( GLTexture.Wrap.CLAMP_TO_EDGE );
        color.setWrapT( GLTexture.Wrap.CLAMP_TO_EDGE );
        color.image( ivec2(w,h), GLTexture.InternalFormat.RGBA,
                          GLTexture.Format.RGBA, GLTexture.Type.FLOAT );

        depth = newEMM!GLTexture( GLTexture.Target.T2D, 6 );
        depth.setMinFilter( GLTexture.Filter.NEAREST );
        depth.setMagFilter( GLTexture.Filter.NEAREST );
        depth.setWrapS( GLTexture.Wrap.CLAMP_TO_EDGE );
        depth.setWrapT( GLTexture.Wrap.CLAMP_TO_EDGE );
        //depth.setCompareMode( GLTexture.CompareMode.REF_TO_TEXTURE );
        depth.image( ivec2(w,h), GLTexture.InternalFormat.DEPTH,
                          GLTexture.Format.DEPTH, GLTexture.Type.FLOAT );

        fbo = newEMM!GLFrameBuffer;
        fbo.setAttachment( depth, fbo.Attachment.DEPTH );
        fbo.setAttachment( color, fbo.Attachment.COLOR0 );
        fbo.check();
        fbo.unbind();

        enum sp = bnPath( "shaders", "sp_fbo_shader.glsl" );
        auto ss = parseGLShaderSource( import(sp) );
        shader = newEMM!CommonGLShaderProgram( ss );

        plane = newEMM!SPFBOPlane;
    }

    int[4] vpbuf;

    void start()
    {
        fbo.bind();
        checkGLCall!glGetIntegerv( GL_VIEWPORT, vpbuf.ptr );
        checkGLCall!glViewport( 0, 0, w, h );
        checkGLCall!glClearDepth(1.0);
        checkGLCall!glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    }

    void finish()
    {
        fbo.unbind();
        checkGLCall!glViewport( vpbuf[0], vpbuf[1], vpbuf[2], vpbuf[3] );
    }

    void draw( GLTexture tex = null )
    {
        shader.use();
        if( tex is null ) tex = color;
        tex.bind();
        shader.setUniform!int( "tex", tex.unit );
        plane.draw();
    }
}

class SPFBOPlane : GLObject
{
    ///
    GLBuffer vertices, indices;

    this()
    {
        vertices = newEMM!GLBuffer();
        vertices.setData( [vec2(1,1),vec2(1,-1),vec2(-1,-1),vec2(-1,1)] );
        setAttribPointer( vertices, 0, 2, GLType.FLOAT );

        indices = newEMM!GLBuffer( GLBuffer.Target.ELEMENT_ARRAY_BUFFER );
        indices.setData( [ 0, 1, 3, 1, 2, 3 ] );
    }

    void draw()
    {
        drawElements( DrawMode.TRIANGLES, indices.elementCount );
    }

protected:

    override void preDraw()
    { indices.bind(); }
}
