module engine.material;

import des.math.linear;
import des.gl.base;
import des.util.arch;

import des.il;

import engine.base;
import engine.shader;

///
class TxData : DesObject
{
    mixin DES;

    ///
    GLTexture tex;
    ///
    vec4 val = vec4(0);
    ///
    uint use_tex = 0;

    ///
    this( uint tu )
    {
        tex = newEMM!GLTexture( GLTexture.Target.T2D, tu );
        tex.setParameter( GLTexture.Parameter.MIN_FILTER, GLTexture.Filter.NEAREST );
        tex.setParameter( GLTexture.Parameter.MAG_FILTER, GLTexture.Filter.NEAREST );
    }

    ///
    void image( in Image2 img )
    {
        tex.image( img );
        use_tex = 1;
    }

    ///
    void bind() { tex.bind(); }
}

///
class Material : DesObject
{
    mixin DES;

    ///
    TxData diffuse, specular, bump, normal;

    // tx ambient; tx emission; float shininess;

    vec2 bump_tr;

    ///
    Signal!float idle;

    ///
    this()
    {
        diffuse = newEMM!TxData( 0 );
        diffuse.val = vec4(vec3(0.5),1);

        specular = newEMM!TxData( 1 );
        specular.val = vec4(0.5);

        bump = newEMM!TxData( 2 );
        bump.val = vec4(0);

        normal = newEMM!TxData( 3 );
        normal.val = vec4( 0.5, 0.5, 1, 1 );
    }
}
