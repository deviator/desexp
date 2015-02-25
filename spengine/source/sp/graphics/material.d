module sp.graphics.material;

import des.math.linear;
import des.gl.base;
import des.util.arch;

import des.il;

import sp.graphics.base;
import sp.graphics.shader;

///
class SPGTxData : DesObject
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
        tex.setMinFilter( GLTexture.Filter.NEAREST );
        tex.setMagFilter( GLTexture.Filter.NEAREST );
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
class SPGMaterial : DesObject
{
    mixin DES;

    ///
    SPGTxData diffuse, specular, bump, normal;

    // tx ambient; tx emission; float shininess;

    vec2 bump_tr;

    ///
    Signal!float idle;

    ///
    this()
    {
        diffuse  = newEMM!SPGTxData( 0, vec4( vec3(.5), 1 ) );
        specular = newEMM!SPGTxData( 1, vec4( vec3(.5), 1 ) );
        bump     = newEMM!SPGTxData( 2, vec4(0) );
        normal   = newEMM!SPGTxData( 3, vec4(.5,.5,1,1) );
    }
}
