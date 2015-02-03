module window;

import des.app;
import des.util.stdext.algorithm;
import des.util.logsys;

class MainWindow : DesWindow
{
    mixin DES;
protected:

    override void prepare()
    {
        connect( key, &keyControl );
    }

    void keyControl( in KeyboardEvent ke )
    {
        if( ke.scan == ke.Scan.ESCAPE ) app.quit();
    }

public:

    this() { super( "desexp", ivec2(800,600), false ); }
}
