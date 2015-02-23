module sp.engine.object;

import sp.engine.base;
import sp.engine.attrib;

import sp.engine.material;
import sp.engine.shader;

///
class SPDrawObject : GLObject, SpaceNode
{
    mixin DES;
    mixin SpaceNodeHelper;

protected:

    uint num_vertices;

    ///
    GLBuffer indices;

    ///
    GLBuffer[] buffers;

    ///
    SPMaterial material;

public:

    Signal!float idle;

    ///
    this( in SPMeshData md, SPMaterial mat )
    in { assert( mat !is null ); } body
    {
        prepareMesh( md );

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

    /// creates buffers, set vertices count, etc
    void prepareMesh( in SPMeshData data )
    {
        num_vertices = data.num_vertices;

        if( data.indices.length )
        {
            indices = newEMM!GLBuffer( GLBuffer.Target.ELEMENT_ARRAY_BUFFER );
            indices.setData( data.indices );
            logger.Debug( "indices count: ", data.indices.length );
            import std.algorithm;
            logger.Debug( "indices max: ", reduce!max( data.indices ) );
        }

        foreach( bufdata; data.buffers )
            if( auto buf = createBuffer( bufdata, data.attribs ) )
                buffers ~= buf;
    }

    /// create buffer, set attrib pointer, set data if exists
    GLBuffer createBuffer( in SPMeshData.Buffer bd, in SPAttrib[] attrlist )
    {
        if( bd.data is null )
        {
            logger.warn( "buffer is defined, but has no data" );
            return null;
        }

        if( bd.attribs is null )
        {
            logger.warn( "buffer is defined, but has no attribs" );
            return null;
        }

        auto buf = newEMM!GLBuffer;
        buf.setUntypedData( bd.data, attrlist[bd.attribs[0]].dataSize,
                            GLBuffer.Usage.STATIC_DRAW );

        foreach( attr_no; bd.attribs )
        {
            auto attr = attrlist[attr_no];
            setAttribPointer( buf, attr.location, attr.elements,
                              attr.type, attr.stride, attr.offset );
            logger.Debug( "set attrib '%s' at loc '%d'", attr.name, attr.location );
        }

        return buf;
    }
}
