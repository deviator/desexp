module draw;

import std.conv : to;

import des.gl.base;
import des.space;
import des.math.linear;
import des.util.helpers;

import des.il.io;

import std.file;
import std.math;

import sp.graphics;

import des.util.stdext.algorithm;
import des.assimp;

class TestScene : SPGScene
{
protected:
    SMLoader loader;

public:
    this( Camera cam )
    {
        super( cam, newEMM!MoveLight( 4, 5, 0.2, vec3(0.5,0.1,0.025) ) );

        loader = newEMM!SMLoader;

        mat_wall = newEMM!SPGMaterial();
        mat_wall.diffuse.image( imLoad( appPath( "..", "data", "masonry-wall-texture.jpg" ) ) );
        mat_wall.bump.image( imLoad( appPath( "..", "data", "masonry-wall-bump-map.jpg" ) ) );
        mat_wall.bump_tr = vec2( 0.03, 0.02 );
        mat_wall.normal.image( imLoad( appPath( "..", "data", "masonry-wall-normal-map.jpg" ) ) );
        mat_wall.specular.val = vec4(vec3(0.2),1);

        prepareAbstractModel();
        prepareRoomModel();
        preparePlaneModel();
        prepareSphereModel();

        //glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
    }

    void changeMoveLight()
    {
        (cast(MoveLight)light).move = !(cast(MoveLight)light).move;
    }

protected:

    void prepareAbstractModel()
    {
        loader.loadScene( appPath( "..", "data", "abstract_model.dae" ) );

        auto mat = newEMM!SPGMaterial();
        mat.diffuse.image( imLoad( appPath( "..", "data", "abstract_model_color.png" ) ) );

        addObject( new TestObject( convMesh( loader.getMesh(0) ), mat ) );
    }

    void prepareRoomModel()
    {
        loader.loadScene( appPath( "..", "data", "room.dae" ) );

        auto mat = newEMM!SPGMaterial();
        mat.diffuse.image( imLoad( appPath( "..", "data", "masonry-wall-texture.jpg" ) ) );
        mat.normal.image( imLoad( appPath( "..", "data", "masonry-wall-normal-map.jpg" ) ) );

        auto o = new SPGDrawObject( convMesh( loader.getMesh(0) ), mat );
        o.offset = vec3(0,0,-2);
        addObject( o );
    }

    SPGMaterial mat_wall;

    void preparePlaneModel()
    {
        SMMesh mesh;

        mesh.indices = [ 0, 1, 3, 1, 2, 3 ];
        mesh.vertices = [vec3(1,1,0),vec3(1,-1,0),vec3(-1,-1,0),vec3(-1,1,0)];
        auto tex_repeat = 10;
        mesh.texcoords ~= SMTexCoord( 2, cast(float[])( amap!(a=>a*tex_repeat)( [vec2(1,1),vec2(1,0),vec2(0,0),vec2(0,1)] ) ) );
        auto x = vec3(1,0,0);
        auto z = vec3(0,0,1);
        mesh.normals = [z,z,z,z];
        mesh.tangents = [x,x,x,x];

        auto o = new SPGDrawObject( convMesh( mesh ), mat_wall );
        o.setTransform( mat4.diag(tex_repeat*1.5).setCol(3,vec4(0,0,-1.5,1)) );
        addObject( o );
    }

    void prepareSphereModel()
    {
        auto mg = new SMSphereMeshGenerator( 1, 32, 32 );
        auto o = new SPGDrawObject( convMesh( mg.genMesh( "sphere" ) ), mat_wall );
        o.setTransform( mat4().setCol(3,vec4(3,3,0,1)) );
        addObject( o );
    }
}

class MoveLight : SPGLight
{
    this( float Z, float R = 5, float S = 0.2, vec3 att = vec3(1,0.1,0.01) )
    {
        super( 10 );
        ltr.pos.z = Z;
        radius = R;
        speed = S;
        attenuation = att;
    }

    float speed = 0.2;
    float radius = 5;
    float time = 0;

    override void idle( float dt )
    {
        super.idle( dt );
        if( !move ) return;
        time += dt;
        import std.math;
        auto t = time * 2 * PI * speed;
        ltr.pos = vec3( vec2( cos(t), sin(t) ) * radius, offset.z );
    }

    bool move = true;
}

class TestObject : SPGDrawObject
{
protected:

    float time = 0;

public:

    this( in GLMeshData info, SPGMaterial mat )
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

            auto s = 1;

            self_mtr = mat4.diag(s,s,s,1) * self_mtr;
        });
    }
}

///
interface SMMeshGenerator
{
    ///
    SMMesh genMesh( string name );
}

///
class SMUniformSurfaceMeshGenerator
{
    mixin ClassLogger;
protected:

    ///
    vec2[] planeCoords( uivec2 res )
    {
        vec2[] ret;

        float sx = 1.0 / res.x;
        float sy = 1.0 / res.y;

        foreach( y; 0 .. res.y+1 )
            foreach( x; 0 .. res.x+1 )
                ret ~= vec2( sx * x, sy * y );

        return ret;
    }

    ///
    uint[] triangleStripPlaneIndex( uivec2 res, uint term=uint.max )
    {
        uint[] ret;
        foreach( y; 0 .. res.y-1 )
        {
            ret ~= [ y*res.x, (y+1)*res.x ];
            foreach( x; 1 .. res.x )
                ret ~= [ y*res.x+x, (y+1)*res.x+x ];
            ret ~= term;
        }
        return ret;
    }

    abstract
    {
        vec3[] transformCoords( vec2[] );
        vec2[] transformTexCoords( vec2[] );
        mat3[] getTangentSpace( vec2[] );
    }

public:

    this() { logger = new InstanceLogger( this ); }

    uivec2 subdiv;

    SMMesh genMesh( string name )
    {
        scope(exit) logger.Debug( "generate mesh '%s'" );

        auto crd = planeCoords( subdiv );

        SMMesh m;

        m.name = name;
        m.type = m.Type.TRIANGLE_STRIP;
        m.indices = triangleStripPlaneIndex( subdiv+uivec2(1,1) );
        m.vertices = transformCoords( crd );
        m.texcoords = [ SMTexCoord( 2, cast(float[])transformTexCoords( crd ) ) ];

        auto ts = getTangentSpace( crd );

        m.normals = amap!(a=>vec3(a.col(2)))( ts );
        m.tangents = amap!(a=>vec3(a.col(0)))( ts );
        m.bitangents = amap!(a=>vec3(a.col(1)))( ts );
        m.colors = null;

        return m;
    }
}

vec3 cylinder( in vec2 c ) pure
{ return vec3( cos(c.x), sin(c.x), c.y ); }

class SMSphereMeshGenerator : SMUniformSurfaceMeshGenerator
{
protected:

    import std.math;

    vec3 spheric( in vec2 c ) pure
    { return vec3( cos(c.x) * sin(c.y), sin(c.x) * sin(c.y), cos(c.y) ); }

    vec2[] truePos( vec2[] crd )
    { return amap!( a => a * vec2(PI*2,PI) )( crd ); }

    mat3 tangentSpace( in vec2 c )
    {
        auto t = vec3( cos(c.x), sin(c.x), 0 );
        auto n = vec3( cos(c.x) * sin(c.y), sin(c.x) * sin(c.y), cos(c.y) );
        return mat3( t,-cross(t,n),n ).T;
    }

    override
    {
        vec3[] transformCoords( vec2[] crd )
        { return amap!( a => spheric(a) * radius )( truePos( crd ) ); }

        vec2[] transformTexCoords( vec2[] crd ) { return crd; }

        mat3[] getTangentSpace( vec2[] crd )
        { return amap!( a => tangentSpace(a) )( truePos( crd ) ); }
    }

public:

    this( float R, uint rx, uint ry )
    {
        subdiv = uivec2(rx,ry);
        radius = R;
    }

    float radius;
}
