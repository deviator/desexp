module window;

import des.app;
import des.util.stdext.algorithm;
import des.util.logsys;
import des.util.timer;

import camera;

import draw;

class MainWindow : DesWindow
{
    mixin DES;
protected:

    MouseControlCamera cam;

    TestScene scene;

    override void prepare()
    {
        cam = new MouseControlCamera;

        scene = newEMM!TestScene( cam );

        connect( key, ( in KeyboardEvent ke )
        {
            if( ke.scan == ke.Scan.ESCAPE )
                app.quit();
        });
        connect( mouse, &(cam.mouseReaction) );
        connect( key, &(cam.keyReaction) );
        connect( event.resized, (ivec2 sz){ cam.ratio = sz.w / cast(float)sz.h; });

        connect( draw, &(scene.draw) );
        connect( idle, &(scene.idle) );
    }

public:

    this() { super( "desexp", ivec2(800,600), false ); }
}
