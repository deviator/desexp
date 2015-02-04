module draw;

import des.gl;
import des.space;
import des.math.linear;
import des.util.logsys;

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

public:

    this()
    {
        super( SS_TEST );

        pos = createArrayBuffer();
        auto loc = shader.getAttribLocation( "pos" );
        setAttribPointer( pos, loc, 3, GLType.FLOAT );

        pos.setData( [vec3(0), vec3(1), vec3(0,1,0), vec3(1,0,0)] );
    }

    void draw( Camera cam )
    {
        shader.setUniform!mat4( "prj", cam.projection.matrix * cam.resolve(this) );

        drawArrays( DrawMode.POINTS );
    }
}
