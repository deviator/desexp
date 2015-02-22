module sp.engine.scene;

import std.exception;

import des.util.timer;

import sp.engine.attrib;
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

public:

    ///
    Camera camera;
    ///
    SPLight light;

    ///
    this( Camera camera, SPLight light )
    in{ assert( camera !is null ); } body
    {
        this.camera = camera;
        this.light = light is null ? newEMM!SPLight(4) : light;
        obj_shader = newEMM!SPMainShader;
        light_shader = newEMM!SPLightShader;
        tm = new Timer;

        render = newEMM!SPRender;
        render.cam = camera;

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

protected:

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
        addDF( "fbo depth", { render.draw( render.getDepth() ); } );
        addDF( "fbo simple", { render.draw( render.getColor(0) ); } );
        addDF( "fbo diffuse", { render.draw( render.getColor(1) ); } );
        addDF( "fbo normal", { render.draw( render.getColor(2) ); } );
        addDF( "fbo specular", { render.draw( render.getColor(3) ); } );
        addDF( "light shadow map", { render.draw( light.shadow_map ); } );
        addDF( "fbo result", { render.draw(); } );
    }

    void addDF( string name, void delegate() func )
    { listDF ~= new DrawFunc( name, func ); }

    void drawObjects( SPObjectShader shader, Camera cam )
    {
        shader.setUp();
        shader.setLight( cam, light );
        foreach( obj; objs )
            obj.draw( shader, cam );
    }
}
