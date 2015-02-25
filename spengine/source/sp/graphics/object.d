module sp.graphics.object;

import sp.graphics.base;

import sp.graphics.material;
import sp.graphics.shader;

///
class SPGDrawObject : GLMeshObject, SpaceNode
{
    mixin DES;
    mixin SpaceNodeHelper;

protected:

    ///
    SPGMaterial material;

public:

    Signal!float idle;

    ///
    this( in GLMeshData md, SPGMaterial mat )
    in { assert( mat !is null ); } body
    {
        super( md );

        material = registerChildEMM( mat, true );
        connect( idle, &(material.idle.opCall) );
    }

    ///
    bool visible = true;

    ///
    void draw( SPGObjectShader shader, Camera camera )
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
}
