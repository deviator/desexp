module des.engine.scene;

import std.exception;

import des.space;
import des.gl.base;
import des.util.arch;
import des.util.timer;

import des.engine.attrib;
import des.engine.base;
import des.engine.material;
import des.engine.object;
import des.engine.light;
import des.engine.shader;

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
    this( Camera camera, Light light )
    in{ assert( camera !is null ); } body
    {
        this.camera = camera;
        this.light = light is null ? newEMM!Light : light;
        obj_shader = newEMM!ObjectShader;
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

    void drawObjects()
    {
        obj_shader.use();
        obj_shader.setLight( camera, light );
        foreach( obj; objs )
            obj.draw( obj_shader, camera );
    }
}
