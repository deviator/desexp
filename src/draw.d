module draw;

import std.conv : to;

import des.gl.base;
import des.space;
import des.math.linear;
import des.util.helpers;

import des.il.io;

import std.file;
import std.math;

import des.engine;

class TestScene : Scene
{
    Loader loader;

    this( Camera cam )
    {
        super( cam, newEMM!MoveLight );

        loader = newEMM!Loader;

        //prepareAbstractModel();
        //prepareRoomModel();
        preparePlaneModel();
    }

protected:

    void prepareAbstractModel()
    {
        loader.loadScene( appPath( "..", "data", "abstract_model.dae" ) );

        auto mat = newEMM!Material();
        mat.diffuse.image( imLoad( appPath( "..", "data", "abstract_model_color.png" ) ) );

        addObject( new TestObject( loader.getMeshData(0), mat ) );
    }

    void prepareRoomModel()
    {
        loader.loadScene( appPath( "..", "data", "room.dae" ) );

        auto mat = newEMM!Material();
        mat.diffuse.image( imLoad( appPath( "..", "data", "masonry-wall-texture.jpg" ) ) );
        mat.normal.image( imLoad( appPath( "..", "data", "masonry-wall-normal-map.jpg" ) ) );

        addObject( new DrawObject( loader.getMeshData(0), mat ) );
    }

    void preparePlaneModel()
    {
        MeshData md;

        md.vertices = Attrib( 0, 3, GLType.FLOAT, [vec3(1,1,0),vec3(1,-1,0),vec3(-1,-1,0),vec3(-1,1,0)] );
        md.indices = [ 0, 1, 3, 1, 2, 3 ];
        md.attribs["texcoords"] = Attrib( 1, 2, GLType.FLOAT, [vec2(1,1),vec2(1,0),vec2(0,0),vec2(0,1)] );
        auto x = vec3(1,0,0);
        auto z = vec3(0,0,1);
        md.attribs["normals"] = Attrib( 2, 3, GLType.FLOAT, [z,z,z,z] );
        md.attribs["tangents"] = Attrib( 3, 3, GLType.FLOAT, [x,x,x,x] );

        auto mat = newEMM!Material();
        mat.diffuse.image( imLoad( appPath( "..", "data", "masonry-wall-texture.jpg" ) ) );
        mat.bump.image( imLoad( appPath( "..", "data", "masonry-wall-bump-map.jpg" ) ) );
        mat.bump_tr = vec2( 0.03, 0.02 );
        mat.normal.image( imLoad( appPath( "..", "data", "masonry-wall-normal-map.jpg" ) ) );
        mat.specular.val = vec4(vec3(0.2),1);

        auto o = new DrawObject( md, mat );
        o.setTransform( mat4.diag(3).setCol(3,vec4(0,0,-1,1)) );
        addObject( o );
    }
}

class MoveLight : Light
{
    float time = 0;
    override void idle( float dt )
    {
        time += dt;
        import std.math;
        auto t = time * 2;
        offset = vec3( vec2( cos(t), sin(t) ) * 5, offset.z );
    }
}

class TestObject : DrawObject
{
protected:

    float time = 0;

public:

    this( in MeshData info, Material mat )
    in { assert( mat !is null ); } body
    {
        super( info, mat );

        connect( idle, (float dt)
        {
            time += dt;

            float a = time * 2;
            float b = time * 1;

            auto v = vec3( cos(a), sin(a), 1 );
            auto q = quat.fromAngle( sin(b) * 0.01, v );

            auto o = vec3( 0,0, sin( time * 3 ) * 0.05 + 0.2 );

            self_mtr = quatAndPosToMatrix( q, o );
        });
    }
}

/+
class RoomDraw : GLMeshObject, SpaceNode
{
    mixin SpaceNodeHelper;

    this()
    {
        auto ll = new SceneLoader( appPath( "..", "data", "room.dae" ) );
        super( readText( appPath( "..", "data", "shader.glsl" ) ), ll.meshes[0] );

        self_mtr[2][3] = -1;
    }

    void draw( Camera cam )
    {
        auto tr = cam.resolve(this);
        shader.setUniform!mat4( "prj", cam.projection.matrix * tr );
        shader.setUniform!vec3( "light1", vec3( -5,-8,3 ) );
        shader.setUniform!vec3( "light2", vec3( 5,8,12 ) );
        shader.setUniform!vec3( "campos", cam.offset );
        shader.setUniform!uint( "use_texture", 0u );

        glEnable( GL_DEPTH_TEST );
        //glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
        drawArrays( DrawMode.TRIANGLES );
    }

protected:

    override void prepareAttribPointers()
    {
        auto loc = shader.getAttribLocations( "in_pos", "in_uv", "in_norm" );
        setAttribPointer( vertices, loc[0], 3, GLType.FLOAT );

        setAttribPointer( normals, loc[2], 3, GLType.FLOAT );
    }
}
+/
