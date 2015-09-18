module sp.graphics.base;

public
{
    import des.math.linear;
    import des.stdx.type;
    import des.gl.base;
    import des.space;
    import des.arch;
}

///
class SPGException : Exception
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) pure nothrow @safe
    { super( msg, file, line ); }
}
