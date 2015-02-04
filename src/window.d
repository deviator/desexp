module window;

import des.app;
import des.util.stdext.algorithm;
import des.util.logsys;

import draw;
import camera;

class MainWindow : DesWindow
{
    mixin DES;
protected:

    MCamera cam;
    TestDraw obj;

    override void prepare()
    {
        cam = new MCamera;

        connect( key, &keyReaction );
        connect( key, &(cam.keyReaction) );
        connect( mouse, &(cam.mouseReaction) );
        connect( event.resized, (ivec2 sz){ cam.ratio = sz.w / cast(float)sz.h; });

        connect( draw, &drawFunc );

        obj = newEMM!TestDraw;
    }

    void keyReaction( in KeyboardEvent ke )
    {
        if( ke.scan == ke.Scan.ESCAPE ) app.quit();
    }

    void drawFunc()
    {
        obj.draw( cam );
    }

public:

    this() { super( "desexp", ivec2(800,600), false ); }
}
