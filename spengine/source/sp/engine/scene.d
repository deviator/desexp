module sp.engine.scene;

import std.exception;

import des.util.timer;

import des.assimp;

import sp.engine.base;
import sp.engine.material;
import sp.engine.object;
import sp.engine.light;
import sp.engine.shader;
import sp.engine.render;

///
class SPScene : DesObject
{
    mixin DES;

protected:

    ///
    SPRender render;

    ///
    SPObjectShader obj_shader;

    ///
    SPObjectShader light_shader;

    ///
    SPDrawObject[] objs;

    ///
    float time = 0;

    ///
    Timer tm;

    const @property
    {
        ///
        GLAttrib defaultVertexAttrib()
        { return GLAttrib( "vertex", 0, 3 ); }

        ///
        GLAttrib defaultTCoordAttrib()
        { return GLAttrib( "tcoord", 1, 2 ); }

        ///
        GLAttrib defaultNormalAttrib()
        { return GLAttrib( "normal", 2, 3 ); }

        ///
        GLAttrib defaultTangentAttrib()
        { return GLAttrib( "tangent", 3, 3 ); }

        ///
        GLAttrib[] defaultAttribs()
        {
            return [
                defaultVertexAttrib,
                defaultTCoordAttrib,
                defaultNormalAttrib,
                defaultTangentAttrib
                ];
        }
    }

    GLMeshData convMesh( in SRMesh lm )
    {
        GLMeshData md;

        md.num_vertices = cast(uint)( lm.vertices.length );

        md.indices = lm.indices.dup;

        enforce( lm.vertices !is null );

        md.attribs ~= [
                defaultVertexAttrib, // 0
                defaultTCoordAttrib, // 1
                defaultNormalAttrib, // 2
                defaultTangentAttrib // 3
                ];

        float[] texcoords;

        if( lm.texcoords.length )
        {
            enforce( lm.texcoords[0].comp == 2 );
            enforce( lm.texcoords[0].data !is null );
            texcoords = lm.texcoords[0].data.dup;
        }

        md.buffers ~= GLMeshData.Buffer( lm.vertices.dup, [0] ); // md.attribs[0]

        if( texcoords )
            md.buffers ~= GLMeshData.Buffer( texcoords, [1] );   // md.attribs[1]

        md.buffers ~= GLMeshData.Buffer( lm.normals.dup, [2] );  // md.attribs[2]

        if( lm.tangents )
            md.buffers ~= GLMeshData.Buffer( lm.tangents.dup, [3] ); // md.attribs[3]

        return md;
    }

public:

    ///
    Camera camera;
    ///
    SPLight light;

    ///
    this( Camera camera, SPLight light )
    in{ assert( camera !is null ); } body
    {
        uint[string] frag_info = [
                     "color"        : 0,
                     "diffuse_map"  : 1,
                     "normal_map"   : 2,
                     "specular_map" : 3,
                    ];

        this.camera = camera;
        this.light = light is null ? newEMM!SPLight(4) : light;

        int dvl = defaultVertexAttrib.location;

        obj_shader = newEMM!SPMainShader( dvl, defaultAttribs, frag_info );
        light_shader = newEMM!SPLightShader;

        tm = new Timer;

        render = newEMM!SPRender( frag_info );
        render.cam = camera;
        render.light = light;

        glEnable(GL_DEPTH_TEST);

        setDrawFuncs();
    }

    ///
    void addObject( SPDrawObject obj )
    in{ assert( obj !is null ); } body
    { objs ~= registerChildEMM( obj ); }

    void newView()
    {
        dfNO++;
        dfNO %= listDF.length;
        logger.info( listDF[dfNO].name );
    }

    ///
    void draw()
    {
        light.bind();
        drawObjects( light_shader, light );
        light.unbind();

        render.bind();
        drawObjects( obj_shader, camera );
        render.unbind();

        listDF[dfNO].func();
    }

    ///
    void idle()
    {
        auto dt = tm.cycle();
        light.idle( dt );
        foreach( obj; objs ) obj.idle( dt );
    }

    ///
    void resize( uivec2 sz ) { render.resize( sz ); }

    ///
    void resize(T)( Vector!(2,T) sz )
    if( isIntegral!T )
    in
    {
        assert( sz.x > 0 );
        assert( sz.y > 0 );
    }
    body { resize( uivec2( sz ) ); }

protected:

    void drawObjects( SPObjectShader shader, Camera cam )
    {
        shader.setUp();
        shader.setLight( cam, light );
        foreach( obj; objs )
            obj.draw( shader, cam );
    }

    class DrawFunc
    {
        string name;
        void delegate() func;
        this( string name, void delegate() func )
        in{ assert( func !is null ); } body
        { this.name = name, this.func = func; }
    }

    DrawFunc[] listDF;
    uint dfNO = 0;

    void setDrawFuncs()
    {
        addDF( "clear draw", { drawObjects( obj_shader, camera ); } );
        //addDF( "fbo depth", { render.draw( render.getDepth() ); } );
        //addDF( "fbo simple", { render.draw( render.getColor(0) ); } );
        //addDF( "fbo diffuse", { render.draw( render.getColor(1) ); } );
        //addDF( "fbo normal", { render.draw( render.getColor(2) ); } );
        //addDF( "fbo specular", { render.draw( render.getColor(3) ); } );
        //addDF( "light shadow map", { render.draw( light.shadowMap ); } );
        addDF( "fbo result", { render.draw(); } );
    }

    void addDF( string name, void delegate() func )
    { listDF ~= new DrawFunc( name, func ); }
}
