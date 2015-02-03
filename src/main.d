module main;

import des.app;
import des.util.logsys;

import window;

void main()
{
    logger.info( "app start" );
    auto app = new DesApp;
    app.addWindow({ return new MainWindow(); });
    while( app.isRunning ) app.step();
    app.destroy();
    logger.info( "app finish" );
}
