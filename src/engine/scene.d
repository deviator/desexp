module engine.scene;

import std.exception;

import des.space;
import des.gl.base;
import des.util.arch;
import des.util.timer;

import engine.attrib;
import engine.base;
import engine.material;
import engine.object;
import engine.light;
import engine.shader;

///
class Scene : DesObject
{
    mixin DES;

protected:

    //GLFrameBuffer fbo;

    ///
    ObjectShader obj_shader;

    ///
    DrawObject[] objs;

    ///
    float time = 0;

    ///
    Timer tm;

public:

    ///
    Camera camera;
    ///
    Light light;

    ///
    this( Camera camera )
    in{ assert( camera !is null ); } body
    {
        this.camera = camera;
        obj_shader = newEMM!ObjectShader;
        light = newEMM!Light;
        tm = new Timer;
        //fbo = newEMM!GLFrameBuffer;
    }

    ///
    void addObject( DrawObject obj )
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

    void drawObjets()
    {
        obj_shader.use();
        obj_shader.setLight( camera, light );
        foreach( obj; objs )
            obj.draw( obj_shader, camera );
    }
}
