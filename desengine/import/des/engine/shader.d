module des.engine.shader;

import des.engine.base;

import des.engine.light;
import des.engine.material;

auto getShaders( string[] path... )
{
    import std.file;
    import des.util.helpers;
    return parseGLShaderSource( readText( appPath( path ) ) );
}

class ObjectShader : CommonGLShaderProgram
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

    void setLight( Camera camera, Light light )
    {
        setUniform!vec3( "light.ambient", light.ambient );
        setUniform!vec3( "light.diffuse", light.diffuse );
        setUniform!vec3( "light.specular", light.specular );
        setUniform!vec3( "light.attenuation", light.attenuation );
        setUniform!vec3( "light.cspos", ( camera.resolve(light).tr( vec3(0),1.0 ) ) );
    }

    void setMaterial( Material mat )
    {
        setTxData( "material.diffuse", mat.diffuse );
        setTxData( "material.specular", mat.specular );
        setTxData( "material.bump", mat.bump );
        setUniform!vec2( "material.bump_tr", mat.bump_tr );
        setTxData( "material.normal", mat.normal );
    }

protected:

    override uint[string] attribLocations()
    {
        return [ "vertex" : 0, "texcoord" : 1,
                 "normal" : 2, "tangent" : 3 ];
    }

    void setTxData( string name, TxData tx )
    {
        setUniform!uint( name ~ ".use_tex", tx.use_tex );
        setUniform!vec4( name ~ ".val", tx.val );
        if( tx.use_tex )
        {
            setUniform!int( name ~ ".tex", tx.tex.unit );
            tx.bind();
        }
    }
}
