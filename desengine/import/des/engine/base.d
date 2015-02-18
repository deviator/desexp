module des.engine.base;

public
{
    import des.math.linear; 
    import des.util.data.type;
    import des.gl.base;
    import des.space;
    import des.util.arch;
}

///
class EngineException : Exception
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) pure nothrow @safe
    { super( msg, file, line ); } 
}
