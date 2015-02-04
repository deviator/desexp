module loader;

import derelict.assimp3.assimp;
import derelict.assimp3.types;

import des.math.linear;
import des.util.data.type;

import std.stdio;
import std.string;

shared static this() { DerelictASSIMP3.load(); }

class Loader
{
    this( string fname )
    {
        auto scene = aiImportFile( fname.toStringz, 0 );

        auto m = scene.mMeshes[0];
        vertices = getTypedArray!vec3( m.mNumVertices, cast(void*)(m.mVertices) ).arr.dup;
        normals = getTypedArray!vec3( m.mNumVertices, cast(void*)(m.mNormals) ).arr.dup;

        foreach( i; 0 .. m.mNumFaces )
        {
            auto f = m.mFaces[i];
            indices ~= getTypedArray!uint( f.mNumIndices, cast(void*)f.mIndices ).arr;
        }
    }

    vec3[] vertices;
    vec3[] normals;
    vec2[] texcoord;
    uint[] indices;
}
