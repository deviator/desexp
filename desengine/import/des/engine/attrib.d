module des.engine.attrib;

import des.gl.base.type;

///
struct Attrib
{
    /// by default invalid value < 0
    int location = -1;
    ///
    uint elements;
    ///
    GLType type;
    ///
    size_t stride = 0;
    ///
    size_t offset = 0;
    ///
    void[] data;

    ///
    this(T)( int location, uint elements,
            GLType type, T[] data=null )
    {
        this.location = location;
        this.elements = elements;
        this.type     = type;
        this.data     = cast(void[])data;
    }

    ///
    this(T)( int location, uint elements,
            GLType type, size_t stride,
            size_t offset, T[] data=null )
    {
        this.location = location;
        this.elements = elements;
        this.type     = type;
        this.stride   = stride;
        this.offset   = offset;
        this.data     = cast(void[])data;
    }
}

///
struct MeshData
{
    ///
    Attrib vertices;
    ///
    uint[] indices;
    ///
    Attrib[string] attribs;
}
