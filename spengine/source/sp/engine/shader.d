module sp.engine.shader;

import sp.engine.base;

import sp.engine.light;
import sp.engine.material;

auto getShaders( string[] path... )
{
    import std.file;
    import des.util.helpers;
    return parseGLShaderSource( readText( appPath( path ) ) );
}

class SPObjectShader : CommonGLShaderProgram
{
    this()
    {
        super( getShaders( "..", "data", "objshader.glsl" ) );
    }

    void setTransform( in mat4 tr, in mat4 prj )
    {
        auto fprj = prj * tr;
        setUniform!mat4( "fprj", fprj );
        setUniform!mat4( "cspace", tr );
    }

    void setLight( Camera camera, SPLight light )
    {
        setUniform!int ( "light.type", light.type );
        setUniform!vec3( "light.ambient", light.ambient );
        setUniform!vec3( "light.diffuse", light.diffuse );
        setUniform!vec3( "light.specular", light.specular );
        setUniform!vec3( "light.attenuation", light.attenuation );
        setUniform!vec3( "light.cspos", camera.resolve(light).offset );
    }

    void setMaterial( SPMaterial mat )
    {
        setTxData( "material.diffuse", mat.diffuse );
        setTxData( "material.specular", mat.specular );
        setTxData( "material.bump", mat.bump );
        setUniform!vec2( "material.bump_tr", mat.bump_tr );
        setTxData( "material.normal", mat.normal );
    }

    void setAttribs( int[] enabled )
    {
        auto list = [ "texcoord", "normal", "tangent" ];

        enforce( canFindAttrib( enabled, "vertex" ) );

        foreach( a; list )
            setUniform!bool( "attrib_use." ~ a,
                    canFindAttrib( enabled, a ) );
    }

protected:

    override uint[string] attribLocations() @property
    {
        return [ "vertex" : 0, "texcoord" : 1,
                 "normal" : 2, "tangent" : 3 ];
    }

    bool canFindAttrib( int[] attribs, string name )
    {
        import std.algorithm;
        return canFind( attribs, attribLocations[name] );
    }

    void setTxData( string name, SPTxData tx )
    {
        setUniform!bool( name ~ ".use_tex", tx.use_tex );
        setUniform!vec4( name ~ ".val", tx.val );
        if( tx.use_tex )
        {
            setUniform!int( name ~ ".tex", tx.tex.unit );
            tx.bind();
        }
    }
}
