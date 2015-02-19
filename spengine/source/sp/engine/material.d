module sp.engine.material;

import des.math.linear;
import des.gl.base;
import des.util.arch;

import des.il;

import sp.engine.base;
import sp.engine.shader;

///
class SPTxData : DesObject
{
    mixin DES;

    ///
    GLTexture tex;
    ///
    vec4 val = vec4(0);
    ///
    bool use_tex = 0;

    ///
    this( uint tu, vec4 val )
    {
        this.val = val;
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
class SPMaterial : DesObject
{
    mixin DES;

    ///
    SPTxData diffuse, specular, bump, normal;

    // tx ambient; tx emission; float shininess;

    vec2 bump_tr;

    ///
    Signal!float idle;

    ///
    this()
    {
        diffuse  = newEMM!SPTxData( 0, vec4( vec3(.5), 1 ) );
        specular = newEMM!SPTxData( 1, vec4( vec3(.5), 1 ) );
        bump     = newEMM!SPTxData( 2, vec4(0) );
        normal   = newEMM!SPTxData( 3, vec4(.5,.5,1,1) );
    }
}
