module draw;

import des.gl;
import des.space;
import des.math.linear;
import des.util.logsys;
import des.util.helpers;

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

class TestDraw : GLSimpleObject, SpaceNode
{
    mixin SpaceNodeHelper;

protected:

    GLBuffer pos;
    GLBuffer ind;

public:

    this()
    {
        super( SS_TEST );

        auto ll = new Loader( appPath( "..", "data", "abstract_model.dae" ) );

        pos = createArrayBuffer();
        auto loc = shader.getAttribLocation( "pos" );
        setAttribPointer( pos, loc, 3, GLType.FLOAT );
        pos.setData( ll.vertices );

        ind = createIndexBuffer();
        ind.setData( ll.indices );
    }

    void draw( Camera cam )
    {
        shader.setUniform!mat4( "prj", cam.projection.matrix * cam.resolve(this) );

        glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
        drawArrays( DrawMode.TRIANGLES );
    }
}
