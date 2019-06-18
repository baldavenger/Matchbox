// SoftClip Shader 
 
#version 120 
uniform sampler2D front; 
uniform float adsk_result_w, adsk_result_h; 
uniform float p_SoftClipA; 
uniform float p_SoftClipB; 
uniform float p_SoftClipC; 
uniform float p_SoftClipD; 
uniform float p_SoftClipE; 
uniform float p_SoftClipF; 
uniform int p_Source; 
uniform bool p_SwitchA; 
uniform bool p_SwitchB; 
 
vec3 from_Cineon(vec3 col) 
{ 
	col.r = (pow(10.0, (1023.0 * col.r - 685.0) / 300.0) - 0.0108) / (1.0 - 0.0108); 
	col.g = (pow(10.0, (1023.0 * col.g - 685.0) / 300.0) - 0.0108) / (1.0 - 0.0108); 
	col.b = (pow(10.0, (1023.0 * col.b - 685.0) / 300.0) - 0.0108) / (1.0 - 0.0108); 
	 
	return col; 
} 
 
vec3 from_logc(vec3 col) 
{ 
    float r = col.r > 0.1496582 ? (pow(10.0, (col.r - 0.385537) / 0.2471896) - 0.052272) / 5.555556 : (col.r - 0.092809) / 5.367655; 
    float g = col.g > 0.1496582 ? (pow(10.0, (col.g - 0.385537) / 0.2471896) - 0.052272) / 5.555556 : (col.g - 0.092809) / 5.367655; 
    float b = col.b > 0.1496582 ? (pow(10.0, (col.b - 0.385537) / 0.2471896) - 0.052272) / 5.555556 : (col.b - 0.092809) / 5.367655; 
     
    col.r = r * 1.617523 + g * -0.537287 + b * -0.080237; 
	col.g = r * -0.070573 + g * 1.334613 + b * -0.26404; 
	col.b = r * -0.021102 + g * -0.226954 + b * 1.248056; 
 
    return col; 
} 
 
vec3 to_sRGB(vec3 col) 
{ 
    if (col.r >= 0.0 && col.r <= 1.0) { 
         col.r = (1.055 * pow(col.r, 1.0 / 2.4)) - .055; 
    } 
 
    if (col.g >= 0.0 && col.g <= 1.0) { 
         col.g = (1.055 * pow(col.g, 1.0 / 2.4)) - .055; 
    } 
 
    if (col.b >= 0.0 && col.b <= 1.0) { 
         col.b = (1.055 * pow(col.b, 1.0 / 2.4)) - .055; 
    } 
 
    return col; 
} 
 
 
void main(void) 
{ 
vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h); 
vec3 COL = texture2D(front, uv).rgb; 
	 
if (p_Source == 1) { 
            COL = from_Cineon(COL); 
        } else if (p_Source == 2) { 
            COL = from_logc(COL); 
        } 
         
float Lr = COL.r > 1.0 ? 1.0 : COL.r; 
float Lg = COL.g > 1.0 ? 1.0 : COL.g; 
float Lb = COL.b > 1.0 ? 1.0 : COL.b; 
 
float Hr = (COL.r < 1.0 ? 1.0 : COL.r) - 1.0; 
float Hg = (COL.g < 1.0 ? 1.0 : COL.g) - 1.0; 
float Hb = (COL.b < 1.0 ? 1.0 : COL.b) - 1.0; 
 
float rr = p_SoftClipA; 
float gg = p_SoftClipB; 
float aa = p_SoftClipC; 
float bb = p_SoftClipD; 
float ss = 1.0 - (p_SoftClipE / 10.0); 
float sf = 1.0 - p_SoftClipF; 
 
float Hrr = Hr * pow(2.0, rr); 
float Hgg = Hg * pow(2.0, rr); 
float Hbb = Hb * pow(2.0, rr); 
 
float HR = Hrr <= 1.0 ? 1.0 - pow(1.0 - Hrr, gg) : Hrr; 
float HG = Hgg <= 1.0 ? 1.0 - pow(1.0 - Hgg, gg) : Hgg; 
float HB = Hbb <= 1.0 ? 1.0 - pow(1.0 - Hbb, gg) : Hbb; 
 
float R = Lr + HR; 
float G = Lg + HG; 
float B = Lb + HB; 
 
float softr = aa == 1.0 ? R : (R > aa ? (-1.0 / ((R - aa) / (bb - aa) + 1.0) + 1.0) * (bb - aa) + aa : R); 
float softR = bb == 1.0 ? softr : softr > 1.0 - (bb / 50.0) ? (-1.0 / ((softr - (1.0 - (bb / 50.0))) / (1.0 - (1.0 - (bb / 50.0))) + 1.0) +  
1.0) * (1.0 - (1.0 - (bb / 50.0))) + (1.0 - (bb / 50.0)) : softr; 
float softg = (aa == 1.0) ? G : (G > aa ? (-1.0 / ((G - aa) / (bb - aa) + 1.0) + 1.0) * (bb - aa) + aa : G); 
float softG = bb == 1.0 ? softg : softg > 1.0 - (bb / 50.0) ? (-1.0 / ((softg - (1.0 - (bb / 50.0))) / (1.0 - (1.0 - (bb / 50.0))) + 1.0) +  
1.0) * (1.0 - (1.0 - (bb / 50.0))) + (1.0 - (bb / 50.0)) : softg; 
float softb = (aa == 1.0) ? B : (B > aa ? (-1.0 / ((B - aa) / (bb - aa) + 1.0) + 1.0) * (bb - aa) + aa : B); 
float softB = bb == 1.0 ? softb : softb > 1.0 - (bb / 50.0) ? (-1.0 / ((softb - (1.0 - (bb / 50.0))) / (1.0 - (1.0 - (bb / 50.0))) + 1.0) +  
1.0) * (1.0 - (1.0 - (bb / 50.0))) + (1.0 - (bb / 50.0)) : softb; 
 
float Cr = (softR * -1.0) + 1.0; 
float Cg = (softG * -1.0) + 1.0; 
float Cb = (softB * -1.0) + 1.0; 
 
float cR = ss == 1.0 ? Cr : Cr > ss ? (-1.0 / ((Cr - ss) / (sf - ss) + 1.0) + 1.0) * (sf - ss) + ss : Cr; 
COL.r = sf == 1.0 ? (cR - 1.0) * -1.0 : ((cR > 1.0 - (-p_SoftClipF / 50.0) ? (-1.0 / ((cR - (1.0 - (-p_SoftClipF / 50.0))) /  
(1.0 - (1.0 - (-p_SoftClipF / 50.0))) + 1.0) + 1.0) * (1.0 - (1.0 - (-p_SoftClipF / 50.0))) + (1.0 - (-p_SoftClipF / 50.0)) : cR) - 1.0) * -1.0; 
float cG = ss == 1.0 ? Cg : Cg > ss ? (-1.0 / ((Cg - ss) / (sf - ss) + 1.0) + 1.0) * (sf - ss) + ss : Cg; 
COL.g = sf == 1.0 ? (cG - 1.0) * -1.0 : ((cG > 1.0 - (-p_SoftClipF / 50.0) ? (-1.0 / ((cG - (1.0 - (-p_SoftClipF / 50.0))) /  
(1.0 - (1.0 - (-p_SoftClipF / 50.0))) + 1.0) + 1.0) * (1.0 - (1.0 - (-p_SoftClipF / 50.0))) + (1.0 - (-p_SoftClipF / 50.0)) : cG) - 1.0) * -1.0; 
float cB = ss == 1.0 ? Cb : Cb > ss ? (-1.0 / ((Cb - ss) / (sf - ss) + 1.0) + 1.0) * (sf - ss) + ss : Cb; 
COL.b = sf == 1.0 ? (cB - 1.0) * -1.0 : ((cB > 1.0 - (-p_SoftClipF / 50.0) ? (-1.0 / ((cB - (1.0 - (-p_SoftClipF / 50.0))) /  
(1.0 - (1.0 - (-p_SoftClipF / 50.0))) + 1.0) + 1.0) * (1.0 - (1.0 - (-p_SoftClipF / 50.0))) + (1.0 - (-p_SoftClipF / 50.0)) : cB) - 1.0) * -1.0; 
 
COL = p_Source == 0 ? COL : to_sRGB(COL); 
 
if (p_SwitchA) { 
COL.r = (COL.r < 1.0 ? 1.0 : COL.r) - 1.0; 
COL.g = (COL.g < 1.0 ? 1.0 : COL.g) - 1.0; 
COL.b = (COL.b < 1.0 ? 1.0 : COL.b) - 1.0; 
}  
else if (p_SwitchB) { 
COL.r = COL.r >= 0.0 ? 0.0 : COL.r + 1.0; 
COL.g = COL.g >= 0.0 ? 0.0 : COL.g + 1.0; 
COL.b = COL.b >= 0.0 ? 0.0 : COL.b + 1.0; 
} 
 
gl_FragColor = vec4(COL, 1.0); 
} 
