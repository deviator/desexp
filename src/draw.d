module draw;

import std.conv : to;

import des.gl;
import des.space;
import des.math.linear;
import des.util.helpers;

import des.il.io;

import std.file;
import std.math;

class TestDraw : GLMeshObject, SpaceNode
{
    mixin SpaceNodeHelper;
protected:

    GLTexture tex;

    float time = 0;

public:

    this()
    {
        auto ll = new SceneLoader( appPath( "..", "data", "abstract_model.dae" ) );
        super( readText( appPath( "..", "data", "shader.glsl" ) ), ll.meshes[0] );
        tex = newEMM!GLTexture( GLTexture.Target.T2D );
        tex.setParameter( GLTexture.Parameter.MIN_FILTER, GLTexture.Filter.NEAREST );
        tex.setParameter( GLTexture.Parameter.MAG_FILTER, GLTexture.Filter.NEAREST );
        tex.image( imLoad( appPath( "..", "data", "abstract_model_color.png" ) ) );
    }

    void idle( float dt )
    {
        time += dt;

        float a = time * 2;
        float b = time * 1;

        auto v = vec3( cos(a), sin(a), 1 );
        auto q = quat.fromAngle( sin(b) * 0.01, v );

        auto o = vec3( 0,0, sin( time * 3 ) * 0.05 + 0.2 );

        self_mtr = quatAndPosToMatrix( q, o );
    }

    void draw( Camera cam )
    {
        tex.bind();
        auto tr = cam.resolve(this);
        shader.setUniform!mat4( "prj", cam.projection.matrix * tr );
        shader.setUniform!vec3( "light1", vec3( -5,-8,3 ) );
        shader.setUniform!vec3( "light2", vec3( 5,8,12 ) );
        shader.setUniform!vec3( "campos", cam.offset );
        shader.setUniform!uint( "use_texture", 1u );

        glEnable( GL_DEPTH_TEST );
        //glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
        drawArrays( DrawMode.TRIANGLES );
    }

protected:

    override void prepareAttribPointers()
    {
        auto loc = shader.getAttribLocations( "in_pos", "in_uv", "in_norm" );
        setAttribPointer( vertices, loc[0], 3, GLType.FLOAT );

        setAttribPointer( texcrds[0], loc[1], 2, GLType.FLOAT );

        setAttribPointer( normals, loc[2], 3, GLType.FLOAT );
    }
}

class RoomDraw : GLMeshObject, SpaceNode
{
    mixin SpaceNodeHelper;

    this()
    {
        auto ll = new SceneLoader( appPath( "..", "data", "room.dae" ) );
        super( readText( appPath( "..", "data", "shader.glsl" ) ), ll.meshes[0] );

        self_mtr[2][3] = -1;
    }

    void draw( Camera cam )
    {
        auto tr = cam.resolve(this);
        shader.setUniform!mat4( "prj", cam.projection.matrix * tr );
        shader.setUniform!vec3( "light1", vec3( -5,-8,3 ) );
        shader.setUniform!vec3( "light2", vec3( 5,8,12 ) );
        shader.setUniform!vec3( "campos", cam.offset );
        shader.setUniform!uint( "use_texture", 0u );

        glEnable( GL_DEPTH_TEST );
        //glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
        drawArrays( DrawMode.TRIANGLES );
    }

protected:

    override void prepareAttribPointers()
    {
        auto loc = shader.getAttribLocations( "in_pos", "in_uv", "in_norm" );
        setAttribPointer( vertices, loc[0], 3, GLType.FLOAT );

        setAttribPointer( normals, loc[2], 3, GLType.FLOAT );
    }
}
