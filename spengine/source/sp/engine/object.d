module sp.engine.object;

import sp.engine.base;

import sp.engine.material;
import sp.engine.shader;

///
class SPDrawObject : GLMeshObject, SpaceNode
{
    mixin DES;
    mixin SpaceNodeHelper;

protected:

    ///
    SPMaterial material;

public:

    Signal!float idle;

    ///
    this( in GLMeshData md, SPMaterial mat )
    in { assert( mat !is null ); } body
    {
        super( md );

        material = registerChildEMM( mat, true );
        connect( idle, &(material.idle.opCall) );
    }

    ///
    bool visible = true;

    ///
    void draw( SPObjectShader shader, Camera camera )
    in
    {
        assert( shader !is null );
        assert( camera !is null );
    }
    body
    {
        if( !visible ) return;

        shader.checkAttribs( vao.enabled );

        shader.setMaterial( material );
        shader.setTransform( camera.resolve(this), camera.projectMatrix );

        checkGLCall!glEnable( GL_DEPTH_TEST );

        if( indices is null ) drawArrays();
        else drawElements();
    }

    ///
    DrawMode mode = DrawMode.TRIANGLES;

    ///
    void setTransform( in mat4 m ) { self_mtr = m; }

protected:

    override void preDraw() { if( indices !is null ) indices.bind(); }

    ///
    void drawArrays()
    { super.drawArrays( mode, num_vertices ); }

    ///
    void drawElements()
    { super.drawElements( mode, indices.elementCount ); }
}
