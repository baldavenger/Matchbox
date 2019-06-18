// ChannelBox Shader 
 
#version 120 
uniform sampler2D front; 
uniform float adsk_result_w, adsk_result_h; 
uniform float p_ScaleR; 
uniform float p_ScaleG; 
uniform float p_ScaleB; 
uniform float p_ScaleA;
uniform float p_ScaleD;
uniform float p_ScaleE;
uniform float p_ScaleO;
uniform float p_ScaleZ;
uniform float p_Blur; 
uniform int p_Channel;
uniform int p_LumaMath; 
uniform bool p_SwitchA; 
uniform bool p_SwitchB; 
uniform bool p_SwitchC;

float Luma(float R, float G, float B, int L)
{
  float lumaRec709 = R * 0.2126 + G * 0.7152 + B * 0.0722;
  float lumaRec2020 = R * 0.2627 + G * 0.6780 + B * 0.0593;
  float lumaDCIP3 = R * 0.209492 + G * 0.721595 + B * 0.0689131;
  float lumaACESAP0 = R * 0.3439664498 + G * 0.7281660966 + B * -0.0721325464;
  float lumaACESAP1 = R * 0.2722287168 + G * 0.6740817658 + B * 0.0536895174;
  float lumaAvg = (R + G + B) / 3.0;
  float lumaMax = max(max(R, G), B);
  float Lu = L == 0 ? lumaRec709 : L == 1 ? lumaRec2020 : L == 2 ? lumaDCIP3 : L == 3 ? lumaACESAP0 : L == 4 ? lumaACESAP1 : L == 5 ? lumaAvg : lumaMax;
  return Lu;
}
  
float Alpha(float p_ScaleR, float p_ScaleG, float p_ScaleB, float p_ScaleA, float p_ScaleD, float p_ScaleE, float p_ScaleZ, float n, bool p_SwitchB)
{
  float r = p_ScaleR;				
  float g = p_ScaleG;				
  float b = p_ScaleB;				
  float a = p_ScaleA;				
  float d = 1.0 / p_ScaleD;							
  float e = 1.0 / p_ScaleE;							
  float z = p_ScaleZ;						 
  float w = r == 0.0 ? 0.0 : (r - (1.0 - g) >= n ? 1.0 : (r >= n ? pow((r - n) / (1.0 - g), d) : 0.0));		
  float k = a == 1.0 ? 0.0 : (a + b <= n ? 1.0 : (a <= n ? pow((n - a) / b, e) : 0.0));						
  float alpha = k * w;									
  float alphaM = alpha + (1.0 - alpha) * z;		 
  float alphaV = p_SwitchB ? 1.0 - alphaM : alphaM;
  return alphaV;
}
  
float AlphaBlur(float p_Width, float p_Height, float x, float y, int p_LumaMath, float p_Blur, sampler2D front)
{
  float sum = 0.0, sum1 = 0.0;
  int Length = p_Blur < 2.0 ? 1 : int(floor(p_Blur));
  if (p_Blur >= 2.0) {p_Blur -= 1.0;} 
  for(int i = -Length; i <= Length; i++) {
  int X = int(min(max(x + i, 0), p_Width - 1));
  for(int j = -Length; j <= Length; j++) {
  int Y = int(min(max(y + j, 0), p_Height - 1));
  vec2 uv = vec2(X,Y) / vec2( p_Width, p_Height); 
  sum += Luma(texture2D(front, uv).r, texture2D(front, uv).g, texture2D(front, uv).b, p_LumaMath) * exp(-(float(i * i + j * j) / (2.0 * p_Blur * p_Blur)));
  sum1 += exp(-(float(i * i + j * j) / (2.0 * p_Blur * p_Blur)));}}
  float Luma = sum / sum1;
  return Luma;
}
 
void main(void) 
{ 
vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h); 
vec3 Col = texture2D(front, uv).rgb;
float R = Col.r;
float G = Col.g;
float B = Col.b;

bool BlueRed = p_Channel == 0;
bool BlueGreen = p_Channel == 1;
bool BlueGreenRed = p_Channel == 2;
bool BlueMxGreenRed = p_Channel == 3;

bool GreenRed = p_Channel == 4;
bool GreenBlue = p_Channel == 5;
bool GreenBlueRed = p_Channel == 6;
bool GreenMxBlueRed = p_Channel == 7;

bool RedGreen = p_Channel == 8;
bool RedBlue = p_Channel == 9;
bool RedBlueGreen = p_Channel == 10;
bool RedMxBlueGreen = p_Channel == 11;

float inLuma = Luma(R, G, B, p_LumaMath);
float luma = inLuma;

if (p_Blur != 0.0) {
luma = AlphaBlur(adsk_result_w, adsk_result_h, gl_FragCoord.x, gl_FragCoord.y, p_LumaMath, p_Blur, front);
}

float BR = B > R ? R : B;    
float BG = B > G ? G : B;    
float BGR = B > min(G, R) ? min(G, R) : B;    
float BGRX = B > max(G, R) ? max(G, R) : B;    
float blue = BlueRed ? BR : BlueGreen ? BG : BlueGreenRed ? BGR : BlueMxGreenRed ? BGRX : B; 
								  
float GR = G > R ? R : G;    
float GB = G > B ? B : G;    
float GBR = G > min(B, R) ? min(B, R) : G;    
float GBRX = G > max(B, R) ? max(B, R) : G;    
float green = GreenRed ? GR : GreenBlue ? GB : GreenBlueRed ? GBR : GreenMxBlueRed ? GBRX : G; 
								  
float RG = R > G ? G : R;    
float RB = R > B ? B : R;    
float RBG = R > min(B, G) ? min(B, G) : R;    
float RBGX = R > max(B, G) ? max(B, G) : R;    
float red = RedGreen ? RG : RedBlue ? RB : RedBlueGreen ? RBG : RedMxBlueGreen ? RBGX : R;

if (p_SwitchC) {
float outLuma = Luma(red, green, blue, p_LumaMath);
red *= (inLuma / outLuma);
green *= (inLuma / outLuma);
blue *= (inLuma / outLuma);
}				

float L = luma - p_ScaleO;								
float q = min(L, 1.0);									
float n = max(q, 0.0);

float alphaV = Alpha(p_ScaleR, p_ScaleG, p_ScaleB, p_ScaleA, p_ScaleD, p_ScaleE, p_ScaleZ, n, p_SwitchB);
															  
Col.r = p_SwitchA ? alphaV : R * (1.0f - alphaV) + (red * alphaV);		
Col.g = p_SwitchA ? alphaV : G * (1.0f - alphaV) + (green * alphaV);
Col.b = p_SwitchA ? alphaV : B * (1.0f - alphaV) + (blue * alphaV);

gl_FragColor = vec4(Col, 1.0); 
}
	 