module sp.engine.attrib;

import des.gl.base.type;

///
struct SPAttrib
{
    ///
    string name;

    /// by default invalid value < 0
    int location = -1;
    ///
    uint elements;
    ///
    GLType type;
    ///
    size_t stride;
    ///
    size_t offset;

pure:
    ///
    this( string name, int location, uint elements,
          GLType type=GLType.FLOAT,
          size_t stride=0, size_t offset=0 )
    {
        this.name     = name;
        this.location = location;
        this.elements = elements;
        this.type     = type;
        this.stride   = stride;
        this.offset   = offset;
    }

    size_t dataSize() const @property
    {
        if( stride ) return stride;
        return elements * sizeofGLType( type );
    }
}

///
struct SPMeshData
{
    ///
    uint num_vertices;

    ///
    uint[] indices;

    ///
    SPAttrib[] attribs;

    ///
    static struct Buffer
    {
        ///
        void[] data;
        /// numbers of attributes in `SPMeshData.attribs` array
        uint[] attribs;
    }

    ///
    Buffer[] buffers;
}
