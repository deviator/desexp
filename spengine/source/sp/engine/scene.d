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

        glEnable(GL_DEPTH_TEST);
    }

    ///
    void addObject( SPDrawObject obj )
    in{ assert( obj !is null ); } body
    { objs ~= registerChildEMM( obj ); }

    void newView()
    {
        fbo_view++;
        fbo_view %= 5;

        switch( fbo_view )
        {
            case 0:
                logger.info( "scene" );
                break;
            case 1:
                logger.info( "render color" );
                break;
            case 2:
                logger.info( "render depth" );
                break;
            case 3:
                logger.info( "shadow map" );
                break;
            case 4:
                logger.info( "render normal map" );
                break;
            default: break;
        }
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

        switch( fbo_view )
        {
            case 0:
                drawObjects( obj_shader, camera );
                break;
            case 1:
                render.draw();
                break;
            case 2:
                render.draw( render.getDepth() );
                break;
            case 3:
                render.draw( light.shadow_map );
                break;
            case 4:
                render.draw( render.getColor(1) );
                break;
            default:
                break;
        }
    }

    uint fbo_view = 0;

    ///
    void idle()
    {
        auto dt = tm.cycle();
        light.idle( dt );
        foreach( obj; objs ) obj.idle( dt );
    }

protected:

    void drawObjects( SPObjectShader shader, Camera cam )
    {
        shader.setUp();
        shader.setLight( cam, light );
        foreach( obj; objs )
            obj.draw( shader, cam );
    }
}
