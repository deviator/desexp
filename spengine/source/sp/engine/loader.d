module sp.engine.loader;

import derelict.assimp3.assimp;
import derelict.assimp3.types;

import des.util.helpers;
import des.util.data.type;
import des.util.stdext.string;

import sp.engine.base;
import sp.engine.attrib;

///
class SPLoaderException : SPEngineException
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) pure nothrow @safe
    { super( msg, file, line ); } 
}

///
class SPLoader : DesObject
{
    mixin DES;
protected:

    string scene_file_name;
    const(aiScene)* scene;

    string sourceName() const @property 
    { return "scene '" ~ scene_file_name ~ "'"; }

public:

    /// process scene before loading, use Assimp3 documentation for more information
    enum PostProcess
    {
        /// Calculates the tangents and bitangents for the imported meshes. 
        CalcTangentSpace = aiProcess_CalcTangentSpace,
        
        /// Identifies and joins identical vertex data sets within all imported meshes.
        JoinIdenticalVertices = aiProcess_JoinIdenticalVertices,
        
        /// Converts all the imported data to a left-handed coordinate space. 
        MakeLeftHanded = aiProcess_MakeLeftHanded,
        
        /// Triangulates all faces of all meshes. 
        Triangulate = aiProcess_Triangulate,
        
        /++ Removes some parts of the data structure (animations, materials, 
            light sources, cameras, textures, vertex components).  +/
        //RemoveComponent = aiProcess_RemoveComponent,
        
        /// Generates normals for all faces of all meshes. 
        GenNormals = aiProcess_GenNormals,
        
        /// Generates smooth normals for all vertices in the mesh.
        GenSmoothNormals = aiProcess_GenSmoothNormals,
        
        /// Splits large meshes into smaller sub-meshes.
        SplitLargeMeshes = aiProcess_SplitLargeMeshes,
        
        /++ <hr>Removes the node graph and pre-transforms all vertices with
        the local transformation matrices of their nodes. +/
        PreTransformVertices = aiProcess_PreTransformVertices,
        
        /// Limits the number of bones simultaneously affecting a single vertex to a maximum value.
        LimitBoneWeights = aiProcess_LimitBoneWeights,
        
        /// Validates the imported scene data structure.
        ValidateDataStructure = aiProcess_ValidateDataStructure,
        
        /// Reorders triangles for better vertex cache locality.
        ImproveCacheLocality = aiProcess_ImproveCacheLocality,
        
        /// Searches for redundant/unreferenced materials and removes them.
        RemoveRedundantMaterials = aiProcess_RemoveRedundantMaterials,
        
        /++ This step tries to determine which meshes have normal vectors
            that are facing inwards and inverts them. +/
        FixInFacingNormals = aiProcess_FixInFacingNormals,
        
        /++ This step splits meshes with more than one primitive type in 
            homogeneous sub-meshes. +/
        SortByPType = aiProcess_SortByPType,
        
        /++ This step searches all meshes for degenerate primitives and
            converts them to proper lines or points. +/
        FindDegenerates = aiProcess_FindDegenerates,
        
        /++ This step searches all meshes for invalid data, such as zeroed
            normal vectors or invalid UV coords and removes/fixes them. This is
            intended to get rid of some common exporter errors. +/
        FindInvalidData = aiProcess_FindInvalidData,
        
        /++ This step converts non-UV mappings (such as spherical or
            cylindrical mapping) to proper texture coordinate channels. +/
        GenUVCoords = aiProcess_GenUVCoords,
        
        /++ This step applies per-texture UV transformations and bakes
            them into stand-alone vtexture coordinate channels. +/
        TransformUVCoords = aiProcess_TransformUVCoords,
        
        /++ This step searches for duplicate meshes and replaces them
            with references to the first mesh. +/
        FindInstances = aiProcess_FindInstances,
        
        /// A postprocessing step to reduce the number of meshes.
        OptimizeMeshes = aiProcess_OptimizeMeshes,
        
        
        /// A postprocessing step to optimize the scene hierarchy. 
        OptimizeGraph = aiProcess_OptimizeGraph,
        
        /++ This step flips all UV coordinates along the y-axis and adjusts
            material settings and bitangents accordingly. +/
        FlipUVs = aiProcess_FlipUVs,
        
        /// This step adjusts the output face winding order to be CW.
        FlipWindingOrder = aiProcess_FlipWindingOrder,
        
        /++ This step splits meshes with many bones into sub-meshes so that each
            su-bmesh has fewer or as many bones as a given limit. +/
        SplitByBoneCount = aiProcess_SplitByBoneCount,
        
        /// This step removes bones losslessly or according to some threshold.
        Debone = aiProcess_Debone,
        
        // aiProcess_GenEntityMeshes = 0x100000,
        // aiProcess_OptimizeAnimations = 0x200000
        // aiProcess_FixTexturePaths = 0x200000
    };

    ///
    this()
    {
        if( !DerelictASSIMP3.isLoaded )
            DerelictASSIMP3.load();
    }

    ///
    PostProcess[] default_post_process = [ PostProcess.OptimizeMeshes,
                                           PostProcess.CalcTangentSpace,
                                           PostProcess.JoinIdenticalVertices,
                                           PostProcess.Triangulate ];

    ///
    void loadScene( string fname, PostProcess[] pp... )
    {
        scene_file_name = fname;
        scene = aiImportFile( fname.toStringz,
                buildFlags( default_post_process ~ pp ) );
    }

    ///
    SPMeshData getMeshData( string name )
    {
        foreach( i; 0 .. scene.mNumMeshes )
            if( toDStringFix( scene.mMeshes[i].mName.data ) == name )
                return convMesh( scene.mMeshes[i] );
        throw new SPLoaderException( "no mesh '" ~ name ~ "' in " ~ sourceName );
    }

    ///
    SPMeshData getMeshData( size_t no )
    {
        if( no < scene.mNumMeshes )
            return convMesh( scene.mMeshes[no] );
        throw new SPLoaderException( "no mesh #" ~ to!string(no) ~ " in " ~ sourceName );
    }

protected:

    SPMeshData convMesh( in aiMesh* m )
    in{ assert( m !is null ); } body
    { return SPMeshData( getVertices( m ), getIndices( m ), getAttribs( m ) ); }

    SPDrawObjectAttrib getVertices( in aiMesh* m )
    { return getAttrib( 0, 3, m.mNumVertices, m.mVertices ); }

    uint[] getIndices( in aiMesh* m )
    {
        uint[] ret;

        foreach( i; 0 .. m.mNumFaces )
        {
            auto f = m.mFaces[i];
            enforce( f.mNumIndices == 3, new SPLoaderException( "one or more faces is not triangle" ) );
            ret ~= getTypedArray!uint( 3, f.mIndices ).arr;
        }

        return ret;
    }

    SPDrawObjectAttrib[string] getAttribs( in aiMesh* m )
    {
        auto c = m.mNumVertices;
        auto tc = getTexcoordsAttrib( 1, m );
        auto n = getAttrib( 2, 3, c, m.mNormals );
        auto t = getAttrib( 3, 3, c, m.mTangents );
        return [ "texcoords": tc, "normals": n, "tangents": t ];
    }

    SPDrawObjectAttrib getTexcoordsAttrib( int loc, in aiMesh* m )
    {
        auto tc = m.mTextureCoords[0];
        if( tc is null ) return SPDrawObjectAttrib.init;
        enforce( m.mNumUVComponents[0] == 2, new SPLoaderException( "texture coordinates has wrong dimension count (!= 2)" ) );
        vec2[] buf;
        foreach( i; 0 .. m.mNumVertices )
            buf ~= vec2( tc[i].x, tc[i].y );
        return SPDrawObjectAttrib( loc, 2, GLType.FLOAT, buf );
    }

    SPDrawObjectAttrib getAttrib(T)( int loc, uint pe, uint cnt, T* data )
    {
        if( data is null ) return SPDrawObjectAttrib.init;
        logger.Debug( "%s %s %s", loc, pe, cnt );
        return SPDrawObjectAttrib( loc, pe, GLType.FLOAT,
                getTypedArray!void( cnt*float.sizeof*pe , data ).arr.dup );
    }
}
