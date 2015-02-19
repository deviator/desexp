module sp.engine.scene;

import std.exception;

import des.space;
import des.gl.base;
import des.util.arch;
import des.util.timer;

import sp.engine.attrib;
import sp.engine.base;
import sp.engine.material;
import sp.engine.object;
import sp.engine.light;
import sp.engine.shader;

///
class SPScene : DesObject
{
    mixin DES;

protected:

    //GLFrameBuffer fbo;

    ///
    SPObjectShader obj_shader;

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
        this.light = light is null ? newEMM!SPLight : light;
        obj_shader = newEMM!SPObjectShader;
        tm = new Timer;
        //fbo = newEMM!GLFrameBuffer;
    }

    ///
    void addObject( SPDrawObject obj )
    in{ assert( obj !is null ); } body
    { objs ~= registerChildEMM( obj ); }

    ///
    void draw()
    {
        drawObjects();
    }

    ///
    void idle()
    {
        auto dt = tm.cycle();
        light.idle( dt );
        foreach( obj; objs ) obj.idle( dt );
    }

protected:

    void drawObjects()
    {
        obj_shader.use();
        obj_shader.setLight( camera, light );
        foreach( obj; objs )
            obj.draw( obj_shader, camera );
    }
}
