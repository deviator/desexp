module des.engine.loader;

import derelict.assimp3.assimp;
import derelict.assimp3.types;

import des.util.data.type;
import des.util.stdext.string;

import des.engine.base;
import des.engine.attrib;

///
class LoaderException : EngineException
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) pure nothrow @safe
    { super( msg, file, line ); } 
}

///
class Loader : DesObject
{
    mixin DES;
protected:

    string scene_file_name;
    const(aiScene)* scene;

    string sourceName() const @property 
    { return "scene '" ~ scene_file_name ~ "'"; }

public:

    ///
    this()
    {
        if( !DerelictASSIMP3.isLoaded )
            DerelictASSIMP3.load();
    }

    ///
    void loadScene( string fname )
    {
        scene_file_name = fname;
        scene = aiImportFile( fname.toStringz, aiProcess_CalcTangentSpace );
    }

    ///
    MeshData getMeshData( string name )
    {
        foreach( i; 0 .. scene.mNumMeshes )
            if( toDStringFix( scene.mMeshes[i].mName.data ) == name )
                return convAIMeshToMeshData( scene.mMeshes[i] );
        throw new LoaderException( "no mesh '" ~ name ~ "' in " ~ sourceName );
    }

    ///
    MeshData getMeshData( size_t no )
    {
        if( no < scene.mNumMeshes )
            return convAIMeshToMeshData( scene.mMeshes[no] );
        throw new LoaderException( "no mesh #" ~ to!string(no) ~ " in " ~ sourceName );
    }

protected:

    MeshData convAIMeshToMeshData( in aiMesh* m )
    in{ assert( m !is null ); } body
    { return MeshData( getVertices( m ), getIndices( m ), getAttribs( m ) ); }

    Attrib getVertices( in aiMesh* m )
    { return getAttrib( 0, 3, m.mNumVertices, m.mVertices ); }

    uint[] getIndices( in aiMesh* m )
    {
        uint[] ret;

        foreach( i; 0 .. m.mNumFaces )
        {
            auto f = m.mFaces[i];
            enforce( f.mNumIndices == 3, new LoaderException( "one or more faces is not triangle" ) );
            ret ~= getTypedArray!uint( 3, f.mIndices ).arr;
        }

        return ret;
    }

    Attrib[string] getAttribs( in aiMesh* m )
    {
        auto c = m.mNumVertices;
        auto tc = getTexcoordsAttrib( 1, m );
        auto n = getAttrib( 2, 3, c, m.mNormals );
        auto t = getAttrib( 3, 3, c, m.mTangents );
        return [ "texcoords": tc, "normals": n, "tangents": t ];
    }

    Attrib getTexcoordsAttrib( int loc, in aiMesh* m )
    {
        auto tc = m.mTextureCoords[0];
        if( tc is null ) return Attrib.init;
        enforce( m.mNumUVComponents[0] == 2, new LoaderException( "texture coordinates has wrong dimension count (!= 2)" ) );
        vec2[] buf;
        foreach( i; 0 .. m.mNumVertices )
            buf ~= vec2( tc[i].x, tc[i].y );
        return Attrib( loc, 2, GLType.FLOAT, buf );
    }

    Attrib getAttrib(T)( int loc, uint pe, uint cnt, T* data )
    {
        if( data is null ) return Attrib.init;
        logger.Debug( "%s %s %s", loc, pe, cnt );
        return Attrib( loc, pe, GLType.FLOAT,
                getTypedArray!void( cnt*float.sizeof*pe , data ).arr.dup );
    }
}
