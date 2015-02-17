module engine.object;

import engine.base;
import engine.attrib;

import engine.material;
import engine.shader;

///
class DrawObject : GLObject, SpaceNode
{
    mixin DES;
    mixin SpaceNodeHelper;
    
protected:

    ///
    GLBuffer vertices, indices;

    ///
    GLBuffer[string] attribs;

    ///
    Material material;

    ///
    DrawMode base_mode = DrawMode.TRIANGLES;

public:

    Signal!float idle;

    ///
    this( in MeshData info, Material mat )
    in { assert( mat !is null ); } body
    {
        prepareBuffers( info );

        material = registerChildEMM( mat );
        connect( idle, &(material.idle.opCall) );
    }

    ///
    bool visible = true;

    ///
    void draw( ObjectShader shader, Camera camera )
    in
    {
        assert( shader !is null );
        assert( camera !is null );
    }
    body
    {
        if( !visible ) return;

        shader.setMaterial( material );
        shader.setTransform( camera.resolve(this), camera.projection.matrix );

        checkGLCall!glEnable( GL_DEPTH_TEST );

        if( indices is null )
            drawArrays( base_mode );
        else
            drawElements( base_mode );
    }

    void setTransform( in mat4 m )
    { self_mtr = m; }

protected:

    override void preDraw() { if( indices !is null ) indices.bind(); }

    ///
    void drawArrays( DrawMode mode )
    { super.drawArrays( mode, vertices.elementCount ); }

    ///
    void drawElements( DrawMode mode )
    { super.drawElements( mode, indices.elementCount ); }

    /// creates buffers from `Attrib`s in `MeshData`
    void prepareBuffers( in MeshData data )
    {
        vertices = createBuffer( data.vertices );

        enforce( vertices !is null && vertices.elementCount,
                new GLObjException( "vertices must have data" ) );

        foreach( key, val; data.attribs )
        {
            enforce( val.location >= 0, new GLObjException( "bad attrib '" ~ key ~ "' location" ) );

            auto buf = createBuffer( val );
            attribs[key] = buf;

            logger.Debug( "attrib '%s': loc: %s, elem: %s, type: %s, stride: %s, offset: %s",
                    key, val.location, val.elements, val.type, val.stride, val.offset );
        }

        if( data.indices.length )
        {
            indices = newEMM!GLBuffer( GLBuffer.Target.ELEMENT_ARRAY_BUFFER );
            indices.setData( data.indices );
            logger.Debug( "indices count: ", data.indices.length );
            import std.algorithm;
            logger.Debug( "indices max: ", reduce!max( data.indices ) );
        }
    }

    /// create buffer, set attrib pointer, set data if exists
    GLBuffer createBuffer( in Attrib attr )
    {
        auto buf = newEMM!GLBuffer;
        setAttribPointer( buf, attr.location, attr.elements,
                          attr.type, attr.stride, attr.offset );
        if( attr.data ) buf.setUntypedData( attr.data, float.sizeof * attr.elements );
        return buf;
    }
}
