module window;

import des.app;
import des.util.stdext.algorithm;
import des.util.logsys;
import des.util.timer;

import draw;
import camera;

class MainWindow : DesWindow
{
    mixin DES;
protected:

    MouseControlCamera cam;
    TestDraw obj;
    RoomDraw room;
    Timer tm;

    override void prepare()
    {
        cam = new MouseControlCamera;
        tm = new Timer;

        connect( key, &keyReaction );
        connect( mouse, &(cam.mouseReaction) );
        connect( key, &(cam.keyReaction) );
        connect( event.resized, (ivec2 sz){ cam.ratio = sz.w / cast(float)sz.h; });

        connect( draw, &drawFunc );
        connect( idle, &idleFunc );

        obj = newEMM!TestDraw;
        room = newEMM!RoomDraw;
    }

    void keyReaction( in KeyboardEvent ke )
    {
        if( ke.scan == ke.Scan.ESCAPE ) app.quit();
    }

    void idleFunc()
    {
        obj.idle( tm.cycle() );
    }

    void drawFunc()
    {
        obj.draw( cam );
        room.draw( cam );
    }

public:

    this() { super( "desexp", ivec2(800,600), false ); }
}
