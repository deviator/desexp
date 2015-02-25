module sp.graphics.shader;

import sp.graphics.base;

import sp.graphics.light;
import sp.graphics.material;

import des.util.helpers;

import std.algorithm : canFind;

auto getShaders( string[] path... )
{
    import std.file;
    return parseGLShaderSource( readText( appPath( path ) ) );
}

interface SPGObjectShader
{
    void setTransform( in mat4 tr, in mat4 prj );
    void setMaterial( SPGMaterial mat );
    void checkAttribs( int[] enabled );
    void setUp();
}

class SPGMainShader : CommonGLShaderProgram, SPGObjectShader
{
protected:
    int vert_loc;

    uint[string] attribs;

    uint[string] convInfo( in GLAttrib[] list )
    {
        uint[string] ret;
        foreach( e; list )
            ret[e.name] = e.location;
        return ret;
    }

public:

    this( int vloc, in GLAttrib[] attr_info )
    {
        this.vert_loc = vloc;
        this.attribs = convInfo( attr_info );

        super( parseGLShaderSource( import( bnPath( "shaders", "firstpass.glsl" ) ) ) );
    }

    void setTransform( in mat4 tr, in mat4 prj )
    {
        auto fprj = prj * tr;
        setUniform!mat4( "fprj", fprj );
        setUniform!mat4( "cspace", tr );
    }

    void setMaterial( SPGMaterial mat )
    {
        setTxData( "material.diffuse", mat.diffuse );
        setTxData( "material.specular", mat.specular );
        setTxData( "material.bump", mat.bump );
        setUniform!vec2( "material.bump_tr", mat.bump_tr );
        setTxData( "material.normal", mat.normal );
    }

    void checkAttribs( int[] enabled )
    {
        enforce( canFind( enabled, vert_loc ) );

        foreach( name, loc; attribs )
        {
            auto n = "attrib_use." ~ name;
            auto l = getUniformLocation( n );
            if( l >= 0 ) setUniform!bool( n, canFind( enabled, loc ) );
        }
    }

    void setUp() { use(); }

protected:

    override uint[string] attribLocations() @property
    { return attribs; }

    void setTxData( string name, SPGTxData tx )
    {
        setUniform!bool( name ~ ".use_tex", tx.use_tex );
        setUniform!vec4( name ~ ".val", tx.val );
        if( tx.use_tex ) setTexture( name ~ ".tex", tx.tex );
    }
}

class SPGLightShader : CommonGLShaderProgram, SPGObjectShader
{
    this()
    {
        super( parseGLShaderSource( import( bnPath( "shaders", "shadow.glsl" ) ) ) );
    }

    void setTransform( in mat4 tr, in mat4 prj )
    {
        auto fprj = prj * tr;
        setUniform!mat4( "fprj", fprj );
    }

    void setMaterial( SPGMaterial mat ) {}

    void checkAttribs( int[] enabled )
    { enforce( canFind( enabled, 0 ) ); }

    void setUp() { use(); }

protected:

    override uint[string] attribLocations() @property
    { return [ "vertex" : 0 ]; }
}
