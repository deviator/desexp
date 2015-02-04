module draw;

import std.conv : to;

import des.gl;
import des.space;
import des.math.linear;
import des.util.logsys;
import des.util.helpers;
import des.util.stdext.algorithm;

import loader;

enum SS_TEST =
`//### vert
#version 330
in vec3 pos;
uniform mat4 prj;
void main() { gl_Position = prj * vec4( pos, 1.0 ); }
//### frag
#version 330
out vec4 ocolor;
void main(void) { ocolor = vec4(1,0,0,1); }
`;

class DrawMesh : GLSimpleObject, SpaceNode
{
    mixin SpaceNodeHelper;

protected:

    GLBuffer vertices;
    GLBuffer normals;
    GLBuffer[] texcrds;
    GLBuffer indices;

    abstract void prepareAttribPointers();

public:

    this( string shader_src, MeshData md )
    {
        super( shader_src );

        vertices = createArrayBuffer();
        vertices.setData( md.vertices );

        if( md.normals.length )
        {
            normals = newEMM!GLBuffer();
            normals.setData( md.normals );
        }

        foreach( i; 0 .. md.texcrds.length )
        {
            auto tbuf = newEMM!GLBuffer();
            switch( md.texcrdsdims[i] )
            {
                case 1:
                    tbuf.setData( amap!(a=>a.x)( md.texcrds[i] ) );
                    break;
                case 2:
                    tbuf.setData( amap!(a=>a.xy)( md.texcrds[i] ) );
                    break;
                case 3:
                    tbuf.setData( md.texcrds[i] );
                    break;
                default:
                    throw new Exception( "WTF?: texture coordinate dims == " ~ 
                            to!string( md.texcrdsdims[i] ) );
            }
            texcrds ~= tbuf;
        }

        if( md.indices.length )
        {
            indices = createIndexBuffer();
            indices.setData( md.indices );
        }

        prepareAttribPointers();
    }
}

class TestDraw : DrawMesh
{
    this()
    {
        auto ll = new Loader( appPath( "..", "data", "abstract_model.dae" ) );
        super( SS_TEST, ll.meshes[0] );
    }

    void draw( Camera cam )
    {
        shader.setUniform!mat4( "prj", cam.projection.matrix * cam.resolve(this) );

        glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
        drawArrays( DrawMode.TRIANGLES );
    }

protected:

    override void prepareAttribPointers()
    {
        auto loc = shader.getAttribLocation( "pos" );
        setAttribPointer( vertices, loc, 3, GLType.FLOAT );
    }
}
