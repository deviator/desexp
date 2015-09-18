module window;

import des.app;
import des.stdx;
import des.log;

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
        cam = new MouseControlCamera( vec3( 8, -2, 3 ) );
        cam.fov = 90;

        scene = newEMM!TestScene( cam );

        connect( key, ( in KeyboardEvent ke )
        {
            if( ke.scan == ke.Scan.ESCAPE )
                app.quit();
            if( ke.pressed )
            {
                if( ke.scan == ke.Scan.N )
                    scene.newView();
                if( ke.scan == ke.Scan.L )
                    scene.changeMoveLight();
                if( ke.scan == ke.Scan.A )
                    scene.changeAliased();
            }
        });
        connect( mouse, &(cam.mouseReaction) );
        connect( key, &(cam.keyReaction) );
        connect( event.resized, (ivec2 sz)
        {
            cam.ratio = sz.w / cast(float)sz.h;
            scene.resize( sz );
        });

        //connect( draw, &(scene.draw) );
        connect( draw,
        {
            scene.draw();
            //logger.fatal( "forced quit" );
            //app.quit();
        });
        connect( idle, &(scene.idle) );

        glEnable( GL_PRIMITIVE_RESTART );
        glPrimitiveRestartIndex( uint.max );
    }

public:

    this() { super( "desexp", ivec2(800,600), false ); }
}
