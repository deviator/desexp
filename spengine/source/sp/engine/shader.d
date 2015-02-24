module sp.engine.shader;

import sp.engine.base;

import sp.engine.light;
import sp.engine.material;

import des.util.helpers;

import std.algorithm : canFind;

auto getShaders( string[] path... )
{
    import std.file;
    return parseGLShaderSource( readText( appPath( path ) ) );
}

interface SPObjectShader
{
    void setTransform( in mat4 tr, in mat4 prj );
    void setLight( Camera camera, SPLight light );
    void setMaterial( SPMaterial mat );
    void checkAttribs( int[] enabled );
    void setUp();
}

class SPMainShader : CommonGLShaderProgram, SPObjectShader
{
protected:
    int vert_loc;

    uint[string] attribs;
    uint[string] fragdata;

    uint[string] convInfo( in GLAttrib[] list )
    {
        uint[string] ret;
        foreach( e; list )
            ret[e.name] = e.location;
        return ret;
    }

public:

    this( int vloc, in GLAttrib[] attr_info, uint[string] fragdata )
    {
        this.vert_loc = vloc;
        this.attribs = convInfo( attr_info );
        this.fragdata = fragdata;

        super( parseGLShaderSource( import( bnPath( "shaders", "sp_obj_shader.glsl" ) ) ) );
    }

    void setTransform( in mat4 tr, in mat4 prj )
    {
        auto fprj = prj * tr;
        setUniform!mat4( "fprj", fprj );
        setUniform!mat4( "cspace", tr );
    }

    void setLight( Camera camera, SPLight light )
    {
        setLightByName( "light", camera, light );
    }

    void setMaterial( SPMaterial mat )
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

    override uint[string] fragDataLocations() @property
    { return fragdata; }

    void setTxData( string name, SPTxData tx )
    {
        setUniform!bool( name ~ ".use_tex", tx.use_tex );
        setUniform!vec4( name ~ ".val", tx.val );
        if( tx.use_tex )
            setTexture( name ~ ".tex", tx.tex );
    }

    void setLightByName( string name, Camera cam, SPLight ll )
    {
        setUniform!int ( name ~ ".type", ll.type );
        setUniform!vec3( name ~ ".ambient", ll.ambient );
        setUniform!vec3( name ~ ".diffuse", ll.diffuse );
        setUniform!vec3( name ~ ".specular", ll.specular );
        setUniform!vec3( name ~ ".attenuation", ll.attenuation );
        setUniform!bool( name ~ ".use_shadow", ll.use_shadow );
        setTexture( name ~ ".shadow_map", ll.shadowMap );
        auto crl = cam.resolve(ll);
        setUniform!vec3( name ~ ".cspos", crl.offset );
        auto bais = mat4( .5,  0,  0, .5,
                           0, .5,  0, .5,
                           0,  0, .5, .5,
                           0,  0,  0,  1 );
        auto cam2light = ll.projectMatrix * crl.speedTransformInv;
        setUniform!mat4( name ~ ".fragtr", bais * cam2light );
    }
}

class SPLightShader : CommonGLShaderProgram, SPObjectShader
{
    this()
    {
        super( parseGLShaderSource( import( bnPath( "shaders", "sp_light_shader.glsl" ) ) ) );
    }

    void setTransform( in mat4 tr, in mat4 prj )
    {
        auto fprj = prj * tr;
        setUniform!mat4( "fprj", fprj );
    }

    void setLight( Camera camera, SPLight light ) {}

    void setMaterial( SPMaterial mat ) {}

    void checkAttribs( int[] enabled )
    { enforce( canFind( enabled, 0 ) ); }

    void setUp() { use(); }

protected:

    override uint[string] attribLocations() @property
    { return [ "vertex" : 0 ]; }
}
