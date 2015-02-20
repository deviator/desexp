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

    ///
    GLBuffer vertices, indices;

    ///
    GLBuffer[string] attribs;

    ///
    SPMaterial material;

    ///
    DrawMode base_mode = DrawMode.TRIANGLES;

public:

    Signal!float idle;

    ///
    this( in SPMeshData info, SPMaterial mat )
    in { assert( mat !is null ); } body
    {
        prepareBuffers( info );

        material = registerChildEMM( mat );
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
    void prepareBuffers( in SPMeshData data )
    {
        vertices = createBuffer( data.vertices );

        enforce( vertices !is null && vertices.elementCount,
                new GLObjException( "vertices must have data" ) );

        foreach( key, val; data.attribs )
        {
            //enforce( val.location >= 0, new GLObjException( "bad attrib '" ~ key ~ "' location" ) );

            auto buf = createBuffer( val );

            if( buf !is null )
            {
                attribs[key] = buf;

                logger.Debug( "attrib '%s': loc: %s, elem: %s, type: %s, stride: %s, offset: %s",
                        key, val.location, val.elements, val.type, val.stride, val.offset );
            }
            else
                logger.warn( "bad attrib '%s' location", key );
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
    GLBuffer createBuffer( in SPDrawObjectAttrib attr )
    {
        if( attr.location < 0 ) return null;

        auto buf = newEMM!GLBuffer;
        setAttribPointer( buf, attr.location, attr.elements,
                          attr.type, attr.stride, attr.offset );
        if( attr.data ) buf.setUntypedData( attr.data, float.sizeof * attr.elements );
        return buf;
    }
}
