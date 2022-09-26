
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles


#define MaterialFloat float
#define MaterialFloat2 float2
#define MaterialFloat3 float3
#define MaterialFloat4 float4
#define MaterialFloat3x3 float3x3
#define MaterialFloat4x4 float4x4 
#define MaterialFloat4x3 float4x3 

#define LOOP UNITY_LOOP
#define UNROLL UNITY_UNROLL

/*struct FTexCoordScalesParams
{

	int2 PixelPosition;


	float4 OneOverDDU;
	float4 OneOverDDV;


	float MinScale;
	float MaxScale;

	float TexSample;


	float4 ScalesPerIndex;
};*/
#define FTexCoordScalesParams float2

struct FMaterialParticleParameters
{
	/** Relative time [0-1]. */
	half RelativeTime;
	/** Fade amount due to motion blur. */
	half MotionBlurFade;
	/** Random value per particle [0-1]. */
	half Random;
	/** XYZ: Direction, W: Speed. */
	half4 Velocity;
	/** Per-particle color. */
	half4 Color;
	/** Particle translated world space position and size(radius). */
	float4 TranslatedWorldPositionAndSize;
	/** Macro UV scale and bias. */
	half4 MacroUV;
	/** Dynamic parameter used by particle systems. */
	half4 DynamicParameter;
	/** mesh particle orientation */
	float4x4 LocalToWorld;

	#if USE_PARTICLE_SUBUVS
	/** SubUV texture coordinates*/
	MaterialFloat2 SubUVCoords[ 2 ];
	/** SubUV interpolation value*/
	MaterialFloat SubUVLerp;
	#endif

	/** The size of the particle. */
	float2 Size;
};

struct FPixelMaterialInputs
{
	MaterialFloat3 EmissiveColor;
	MaterialFloat Opacity;
	MaterialFloat OpacityMask;
	MaterialFloat3 BaseColor;
	MaterialFloat Metallic;
	MaterialFloat Specular;
	MaterialFloat Roughness;
	MaterialFloat3 Normal;
	MaterialFloat AmbientOcclusion;	
	MaterialFloat2 Refraction;
	MaterialFloat PixelDepthOffset;
	MaterialFloat Subsurface;	
	MaterialFloat ShadingModel;
	//4.25
	MaterialFloat Anisotropy;
	MaterialFloat3 Tangent;
};

struct FMaterialVertexParameters
{
	// Position in the translated world (VertexFactoryGetWorldPosition).
	// Previous position in the translated world (VertexFactoryGetPreviousWorldPosition) if
	//    computing material's output for previous frame (See {BasePassVertex,Velocity}Shader.usf).
	float3 WorldPosition;
	// TangentToWorld[2] is WorldVertexNormal
	half3x3 TangentToWorld;
#if USE_INSTANCING
	/** Per-instance properties. */
	float4x4 InstanceLocalToWorld;
	float3 InstanceLocalPosition;
	float4 PerInstanceParams;
	uint InstanceId;
	uint InstanceOffset;

#elif IS_MESHPARTICLE_FACTORY 
	/** Per-particle properties. */
	float4x4 InstanceLocalToWorld;
#endif
	// If either USE_INSTANCING or (IS_MESHPARTICLE_FACTORY && FEATURE_LEVEL >= FEATURE_LEVEL_SM4)
	// is true, PrevFrameLocalToWorld is a per-instance transform
	float4x4 PrevFrameLocalToWorld;

	float3 PreSkinnedPosition;
	float3 PreSkinnedNormal;

#if GPU_SKINNED_MESH_FACTORY
	float3 PreSkinOffset;
	float3 PostSkinOffset;
#endif

	half4 VertexColor;
#if NUM_MATERIAL_TEXCOORDS_VERTEX
	float2 TexCoords[ NUM_MATERIAL_TEXCOORDS_VERTEX ];
#if ES3_1_PROFILE
	float2 TexCoordOffset; // Offset for UV localization for large UV values
#endif
#endif

	/** Per-particle properties. Only valid for particle vertex factories. */
	FMaterialParticleParameters Particle;

	// Index into View.PrimitiveSceneData
	uint PrimitiveId;

#if WATER_MESH_FACTORY
	uint WaterWaveParamIndex;
#endif
};

struct FMaterialPixelParameters
{
	#if NUM_TEX_COORD_INTERPOLATORS
	float2 TexCoords[ NUM_TEX_COORD_INTERPOLATORS ];
	#endif

	/** Interpolated vertex color, in linear color space. */
	half4 VertexColor;//TBD

	/** Normalized world space normal. */
	half3 WorldNormal;

	/** Normalized world space reflected camera vector. */
	half3 ReflectionVector;

	/** Normalized world space camera vector, which is the vector from the point being shaded to the camera position. */
	half3 CameraVector;

	/** World space light vector, only valid when rendering a light function. */
	half3 LightVector;

	/**
	* Like SV_Position (.xy is pixel position at pixel center, z:DeviceZ, .w:SceneDepth)
	* using shader generated value SV_POSITION
	* Note: this is not relative to the current viewport.  RelativePixelPosition = MaterialParameters.SvPosition.xy - View.ViewRectMin.xy;
	*/
	float4 SvPosition;

	/** Post projection position reconstructed from SvPosition, before the divide by W. left..top -1..1, bottom..top -1..1  within the viewport, W is the SceneDepth */
	float4 ScreenPosition;

	half UnMirrored;

	half TwoSidedSign;

	/**
	* Orthonormal rotation-only transform from tangent space to world space
	* The transpose(TangentToWorld) is WorldToTangent, and TangentToWorld[2] is WorldVertexNormal
	*/
	half3x3 TangentToWorld;

	/**
	* Interpolated worldspace position of this pixel
	* todo: Make this TranslatedWorldPosition and also rename the VS/DS/HS WorldPosition to be TranslatedWorldPosition
	*/
	float3 AbsoluteWorldPosition;

	/**
	* Interpolated worldspace position of this pixel, centered around the camera
	*/
	float3 WorldPosition_CamRelative;

	/**
	* Interpolated worldspace position of this pixel, not including any world position offset or displacement.
	* Only valid if shader is compiled with NEEDS_WORLD_POSITION_EXCLUDING_SHADER_OFFSETS, otherwise just contains 0
	*/
	float3 WorldPosition_NoOffsets;

	/**
	* Interpolated worldspace position of this pixel, not including any world position offset or displacement.
	* Only valid if shader is compiled with NEEDS_WORLD_POSITION_EXCLUDING_SHADER_OFFSETS, otherwise just contains 0
	*/
	float3 WorldPosition_NoOffsets_CamRelative;

	/** Offset applied to the lighting position for translucency, used to break up aliasing artifacts. */
	half3 LightingPositionOffset;

	float AOMaterialMask;

	#if LIGHTMAP_UV_ACCESS
	float2	LightmapUVs;
	#endif

	#if USE_INSTANCING
	half4 PerInstanceParams;
	#endif

	// Index into View.PrimitiveSceneData
	uint PrimitiveId;

	/** Per-particle properties. Only valid for particle vertex factories. */
	FMaterialParticleParameters Particle;

	#if (ES2_PROFILE || ES3_1_PROFILE)
	float4 LayerWeights;
	#endif

	#if TEX_COORD_SCALE_ANALYSIS
	/** Parameters used by the MaterialTexCoordScales shader. */
	FTexCoordScalesParams TexCoordScalesParams;
	#endif

	#if POST_PROCESS_MATERIAL && (FEATURE_LEVEL <= FEATURE_LEVEL_ES3_1)
	/** Used in mobile custom pp material to preserve original SceneColor Alpha */
	half BackupSceneColorAlpha;
	#endif

	#if COMPILER_HLSL
	// Workaround for "error X3067: 'GetObjectWorldPosition': ambiguous function call"
	// Which happens when FMaterialPixelParameters and FMaterialVertexParameters have the same number of floats with the HLSL compiler ver 9.29.952.3111
	// Function overload resolution appears to identify types based on how many floats / ints / etc they contain
	uint Dummy;
	#endif

	FTexCoordScalesParams TexCoordScalesParams;

	float3 WorldTangent;
};

float4 View_TemporalAAParams;

//To be moved into InitializeExpressions
float UE_Material_PerFrameScalarExpression0;
float UE_Material_PerFrameScalarExpression1;

MaterialFloat3 ReflectionAboutCustomWorldNormal( FMaterialPixelParameters Parameters, MaterialFloat3 WorldNormal, bool bNormalizeInputNormal )
{
	if( bNormalizeInputNormal )
	{
		WorldNormal = normalize( WorldNormal );
	}

	return -Parameters.CameraVector + WorldNormal * dot( WorldNormal, Parameters.CameraVector ) * 2.0;
}
MaterialFloat4 ProcessMaterialColorTextureLookup(MaterialFloat4 TextureValue)
{
#if (ES2_PROFILE || ES3_1_PROFILE) && !METAL_PROFILE // Metal supports sRGB textures
	#if MOBILE_EMULATION
	if( View.MobilePreviewMode > 0.5f)
	{
		// undo HW srgb->lin
		TextureValue.rgb = pow(TextureValue.rgb, 1.0f / 2.2f); // TODO: replace with a more accurate lin -> sRGB conversion.
	}
	#endif

	// sRGB read approximation
	TextureValue.rgb *= TextureValue.rgb;
#endif 
	return TextureValue;
}
float  ProcessMaterialLinearGreyscaleTextureLookup( float  TextureValue )
{
	return TextureValue;
}

#if DECAL_PRIMITIVE

float3 TransformTangentNormalToWorld( in FMaterialPixelParameters Parameters, float3 TangentNormal )
{
	// To transform the normals use tranpose(Inverse(DecalToWorld)) = transpose(WorldToDecal)
	// But we want to only rotate the normals (we don't want to non-uniformaly scale them).
	// We assume the matrix is only a scale and rotation, and we remove non-uniform scale:
	float3 lengthSqr = { length2( DecalToWorld._m00_m01_m02 ),
		length2( DecalToWorld._m10_m11_m12 ),
		length2( DecalToWorld._m20_m21_m22 ) };

	float3 scale = rsqrt( lengthSqr );

	// Pre-multiply by the inverse of the non-uniform scale in DecalToWorld
	float4 ScaledNormal = float4( -TangentNormal.z * scale.x, TangentNormal.y * scale.y, TangentNormal.x * scale.z, 0.f );

	// Compute the normal 
	return normalize( mul( ScaledNormal, DecalToWorld ).xyz );
}

#else //DECAL_PRIMITIVE

float3 TransformTangentNormalToWorld( in FMaterialPixelParameters Parameters, float3 TangentNormal )
{
	return TangentNormal;// normalize( float3( TransformTangentVectorToWorld( Parameters.TangentToWorld, TangentNormal ) ) );
}

#endif //DECAL_PRIMITIVE

//These 2 are the Unity Normal unpacking functions
/*fixed3 UnpackNormalmapRGorAG( fixed4 packednormal )
{
	// This do the trick
	packednormal.x *= packednormal.w;

	fixed3 normal;
	normal.xy = packednormal.xy * 2 - 1;
	normal.z = sqrt( 1 - saturate( dot( normal.xy, normal.xy ) ) );
	return normal;
}
inline fixed3 UnpackNormal( fixed4 packednormal )
{
#if defined(UNITY_NO_DXT5nm)
	return packednormal.xyz * 2 - 1;
#else
	return UnpackNormalmapRGorAG( packednormal );
#endif
}*/
void swap( inout float x, inout float y ){	float temp = x;	x = y;	y = temp;}
MaterialFloat4 UnpackNormalMap( MaterialFloat4 TextureSample )
{
	float3 Unpacked = UnpackNormal( TextureSample );
	//This is needed for textures that don't have flip Green channel on
	Unpacked.y *= -1;
	//Unpacked.x *= -1;
	//swap( Unpacked.x, Unpacked.y );	
	return MaterialFloat4( Unpacked.xy, Unpacked.z, 1.0f );
}
SamplerState GetMaterialSharedSampler(SamplerState TextureSampler, SamplerState SharedSampler)
{
	return TextureSampler;
}
float3 GetActorWorldPosition()
{
	return UNITY_MATRIX_M[ 3 ];
}
float3 GetActorWorldPosition( uint PrimitiveId )
{
	return UNITY_MATRIX_M[ 3 ];
}
MaterialFloat4 Texture2DSample(Texture2D Tex, SamplerState Sampler, float2 UV)
{
#if COMPUTESHADER
	return tex2D( Tex, UV, 0);
#else
	#if HDRP
		return SAMPLE_TEXTURE2D(Tex, Sampler, UV);
	#else
		return tex2D(Tex, UV);
	#endif
#endif
}
MaterialFloat4 Texture2DSampleGrad( Texture2D Tex, SamplerState Sampler, float2 UV, MaterialFloat2 DDX, MaterialFloat2 DDY )
{
	#if HDRP
		return SAMPLE_TEXTURE2D( Tex, Sampler, UV );// , DDX, DDY );
	#else
		return tex2Dgrad( Tex, UV, DDX, DDY );
	#endif
}
MaterialFloat4 Texture2DSampleLevel( Texture2D Tex, SamplerState Sampler, float2 UV, MaterialFloat Mip )
{
	#if HDRP
		return SAMPLE_TEXTURE2D_LOD( Tex, Sampler, UV, Mip );
	#else
		//tex2Dlod( Tex, float3( UV, Mip ) );
		return tex2D( Tex, float3( UV, Mip ) );
	#endif
}
MaterialFloat4 TextureCubeSample( TextureCube Tex, SamplerState Sampler, float3 UV)
{
	//#if COMPUTESHADER
	//	return Tex.SampleLevel(Sampler, UV, 0);
	//#else
	#if HDRP
		return SAMPLE_TEXTURECUBE(Tex, Sampler, UV);
	#else
		return texCUBE(Tex, UV);
	#endif
	//#endif
}
MaterialFloat4 TextureCubeSampleBias( TextureCube Tex, SamplerState Sampler, float3 UV, MaterialFloat MipBias )
{
#if USE_FORCE_TEXTURE_MIP
	return texCUBEbias( Tex, float4( UV, 0 ) );
#else
	#if HDRP
		return SAMPLE_TEXTURECUBE_BIAS( Tex, Sampler, UV, MipBias );
	#else
		return texCUBEbias( Tex, float4( UV, MipBias ) );
	#endif
#endif
}
MaterialFloat4 TextureCubeSampleLevel( TextureCube Tex, SamplerState Sampler, float3 UV, MaterialFloat Mip )
{
	#if HDRP
		return SAMPLE_TEXTURECUBE_LOD( Tex, Sampler, UV, Mip );
	#else
		return texCUBElod( Tex, float4(UV, Mip) );
	#endif
}
float4  Texture2DSampleBias( Texture2D Tex, SamplerState Sampler, float2 UV, float  MipBias )
{
#if HDRP
	return SAMPLE_TEXTURE2D_BIAS( Tex, Sampler, UV, MipBias );
#else
	return tex2Dbias( Tex, float4( UV, 0, MipBias ) );
#endif
}
half3 GetMaterialNormalRaw(FPixelMaterialInputs PixelMaterialInputs)
{
	return PixelMaterialInputs.Normal;
}

half3 GetMaterialNormal(FMaterialPixelParameters Parameters, FPixelMaterialInputs PixelMaterialInputs)
{
	half3 RetNormal;

	RetNormal = GetMaterialNormalRaw(PixelMaterialInputs);
		
	#if (USE_EDITOR_SHADERS && !(ES2_PROFILE || ES3_1_PROFILE || ESDEFERRED_PROFILE)) || MOBILE_EMULATION
	{
		// this feature is only needed for development/editor - we can compile it out for a shipping build (see r.CompileShadersForDevelopment cvar help)
		half3 OverrideNormal = View.NormalOverrideParameter.xyz;

		#if !MATERIAL_TANGENTSPACENORMAL
			OverrideNormal = Parameters.TangentToWorld[2] * (1 - View.NormalOverrideParameter.w);
		#endif

		RetNormal = RetNormal * View.NormalOverrideParameter.w + OverrideNormal;
	}
	#endif

	return RetNormal;
}
MaterialFloat PositiveClampedPow( MaterialFloat X, MaterialFloat Y )
{
	return pow( max( X, 0.0f ), Y );
}
MaterialFloat2 PositiveClampedPow( MaterialFloat2 X, MaterialFloat2 Y )
{
	return pow( max( X, MaterialFloat2( 0.0f, 0.0f ) ), Y );
}
MaterialFloat3 PositiveClampedPow( MaterialFloat3 X, MaterialFloat3 Y )
{
	return pow( max( X, MaterialFloat3( 0.0f, 0.0f, 0.0f ) ), Y );
}
MaterialFloat4 PositiveClampedPow( MaterialFloat4 X, MaterialFloat4 Y )
{
	return pow( max( X, MaterialFloat4( 0.0f, 0.0f, 0.0f, 0.0f ) ), Y );
}

/** Get the per-instance random value when instancing */
float GetPerInstanceRandom(FMaterialPixelParameters Parameters)
{
#if USE_INSTANCING
	return Parameters.PerInstanceParams.x;
#else
	return 0.5;
#endif
}
float3 GetObjectWorldPosition( FMaterialPixelParameters Parameters )
{
	//TODO
	//return Primitive.ObjectWorldPositionAndRadius.xyz;
	return float3( 0, 0, 0 );
}

MaterialFloat ProcessMaterialGreyscaleTextureLookup( MaterialFloat TextureValue )
{
#if (ES2_PROFILE || ES3_1_PROFILE) && !METAL_PROFILE // Metal supports R8 sRGB
#if MOBILE_EMULATION
	if ( View.MobilePreviewMode > 0.5f )
	{
		// undo HW srgb->lin
		TextureValue = pow( TextureValue, 1.0f / 2.2f ); // TODO: replace with a more accurate lin -> sRGB conversion.
	}
#endif
	// sRGB read approximation
	TextureValue *= TextureValue;
#endif 
	return TextureValue;
}
float3 GetWorldPosition_NoMaterialOffsets( FMaterialPixelParameters Parameters )
{
	return Parameters.WorldPosition_NoOffsets;
}
float3 GetWorldPosition( FMaterialPixelParameters Parameters )
{
	return Parameters.AbsoluteWorldPosition;
}
MaterialFloat4 ProcessMaterialLinearColorTextureLookup( MaterialFloat4 TextureValue )
{
	return TextureValue;
}
float  StoreTexCoordScale( in out FTexCoordScalesParams Params, float2 UV, int TextureReferenceIndex )
{
	/*float GPUScaleX = length( ddx( UV ) );
	float GPUScaleY = length( ddy( UV ) );

	if ( TextureReferenceIndex >= 0 && TextureReferenceIndex <  32 )
	{
		float OneOverCPUScale = OneOverCPUTexCoordScales[ TextureReferenceIndex / 4 ][ TextureReferenceIndex % 4 ];

		int TexCoordIndex = TexCoordIndices[ TextureReferenceIndex / 4 ][ TextureReferenceIndex % 4 ];

		float GPUScale = min( GPUScaleX * GetComponent( Params.OneOverDDU, TexCoordIndex ), GPUScaleY * GetComponent( Params.OneOverDDV, TexCoordIndex ) );


		const bool bUpdateMinMax = ( OneOverCPUScale > 0 && ( AnalysisParams.x == -1 || AnalysisParams.x == TextureReferenceIndex ) );
		Params.MinScale = bUpdateMinMax ? min( Params.MinScale, GPUScale * OneOverCPUScale ) : Params.MinScale;
		Params.MaxScale = bUpdateMinMax ? max( Params.MaxScale, GPUScale * OneOverCPUScale ) : Params.MaxScale;


		const bool bUpdateScale = ( AnalysisParams.y  && Params.PixelPosition.x / 32 == TextureReferenceIndex / 4 );
		Params.ScalesPerIndex[ TextureReferenceIndex % 4 ] = bUpdateScale ? min( Params.ScalesPerIndex[ TextureReferenceIndex % 4 ], GPUScale ) : Params.ScalesPerIndex[ TextureReferenceIndex % 4 ];
	}*/
	return 1.f;
}
float  StoreTexSample( in out FTexCoordScalesParams Params, float4 C, int TextureReferenceIndex )
{
	//Params.TexSample = AnalysisParams.x == TextureReferenceIndex ? lerp( .4f, 1.f, saturate( Luminance( C.rgb ) ) ) : Params.TexSample;

	return 1.f;
}
float3 RotateAboutAxis( float4 NormalizedRotationAxisAndAngle, float3 PositionOnAxis, float3 Position )
{

	float3 ClosestPointOnAxis = PositionOnAxis + NormalizedRotationAxisAndAngle.xyz * dot( NormalizedRotationAxisAndAngle.xyz, Position - PositionOnAxis );

	float3 UAxis = Position - ClosestPointOnAxis;
	float3 VAxis = cross( NormalizedRotationAxisAndAngle.xyz, UAxis );
	float CosAngle;
	float SinAngle;
	sincos( NormalizedRotationAxisAndAngle.w, SinAngle, CosAngle );

	float3 R = UAxis * CosAngle + VAxis * SinAngle;

	float3 RotatedPosition = ClosestPointOnAxis + R;

	return RotatedPosition - Position;
}
float2 SvPositionToBufferUV( float4 SvPosition )
{
	return SvPosition.xy * View_BufferSizeAndInvSize.zw;
}
float2 GetSceneTextureUV( FMaterialPixelParameters Parameters )
{
	return SvPositionToBufferUV( Parameters.SvPosition );
}
MaterialFloat UnMirror( MaterialFloat Coordinate, FMaterialPixelParameters Parameters )
{
	return ( ( Coordinate )*( Parameters.UnMirrored )*0.5 + 0.5 );
}
MaterialFloat2 UnMirrorU( MaterialFloat2 UV, FMaterialPixelParameters Parameters )
{
	return MaterialFloat2( UnMirror( UV.x, Parameters ), UV.y );
}
MaterialFloat2 UnMirrorV( MaterialFloat2 UV, FMaterialPixelParameters Parameters )
{
	return MaterialFloat2( UV.x, UnMirror( UV.y, Parameters ) );
}
MaterialFloat2 UnMirrorUV( MaterialFloat2 UV, FMaterialPixelParameters Parameters )
{
	return MaterialFloat2( UnMirror( UV.x, Parameters ), UnMirror( UV.y, Parameters ) );
}
float4 GetScreenPosition( FMaterialPixelParameters Parameters )
{
	return Parameters.ScreenPosition;
}
float GetPixelDepth(FMaterialPixelParameters Parameters)
{
	//FLATTEN
	//if (View.ViewToClip[3][3] < 1.0f)
	//{
		// Perspective
		return GetScreenPosition(Parameters).w;
	//}
	//else
	//{
	//	// Ortho
	//	return ConvertFromDeviceZ(GetScreenPosition(Parameters).z);
	//}
}
uint Mod( uint a, uint b )
{

	return a % b;
}

uint2 Mod( uint2 a, uint2 b )
{

	return a % b;
}

uint3 Mod( uint3 a, uint3 b )
{

	return a % b;
}
float CalcSceneDepth( float2 ScreenUV )
{
	return 0.0f;
}
float CalcSceneDepth( uint2 PixelPos )
{
	return 0.0f;
}
float2 ScreenPositionToBufferUV( float4 ScreenPosition )
{
	float4 View_ScreenPositionScaleBias = float4( 1, 1, 0, 0 );//TODO

	return float2( ScreenPosition.xy / ScreenPosition.w * View_ScreenPositionScaleBias.xy + View_ScreenPositionScaleBias.wz );
}
float2  ScreenAlignedPosition( float4 ScreenPosition )
{
	return  float2 ( ScreenPositionToBufferUV( ScreenPosition ) );
}
float4 VoronoiCompare(float4 minval, float3 candidate, float3 offset, bool bDistanceOnly)
{
	if (bDistanceOnly)
	{
		return float4( 0, 0, 0, min(minval.w, dot(offset, offset)) );
	}
	else
	{
		float newdist = dot(offset, offset);
		return newdist > minval.w ? minval : float4( candidate, newdist );
	}
}

uint3 Rand3DPCG16(int3 p)
{
	// taking a signed int then reinterpreting as unsigned gives good behavior for negatives
	uint3 v = uint3( p );

	// Linear congruential step. These LCG constants are from Numerical Recipies
	// For additional #'s, PCG would do multiple LCG steps and scramble each on output
	// So v here is the RNG state
	v = v * 1664525u + 1013904223u;

	// PCG uses xorshift for the final shuffle, but it is expensive (and cheap
	// versions of xorshift have visible artifacts). Instead, use simple MAD Feistel steps
	//
	// Feistel ciphers divide the state into separate parts (usually by bits)
	// then apply a series of permutation steps one part at a time. The permutations
	// use a reversible operation (usually ^) to part being updated with the result of
	// a permutation function on the other parts and the key.
	//
	// In this case, I'm using v.x, v.y and v.z as the parts, using + instead of ^ for
	// the combination function, and just multiplying the other two parts (no key) for 
	// the permutation function.
	//
	// That gives a simple mad per round.
	v.x += v.y*v.z;
	v.y += v.z*v.x;
	v.z += v.x*v.y;
	v.x += v.y*v.z;
	v.y += v.z*v.x;
	v.z += v.x*v.y;

	// only top 16 bits are well shuffled
	return v >> 16u;
}
float3 VoronoiCornerSample(float3 pos, int Quality)
{
	// random values in [-0.5, 0.5]
	float3 noise = float3( Rand3DPCG16(int3( pos )) ) / 0xffff - 0.5;

	// quality level 1 or 2: searches a 2x2x2 neighborhood with points distributed on a sphere
	// scale factor to guarantee jittered points will be found within a 2x2x2 search
	if (Quality <= 2)
	{
		return normalize(noise) * 0.2588;
	}

	// quality level 3: searches a 3x3x3 neighborhood with points distributed on a sphere
	// scale factor to guarantee jittered points will be found within a 3x3x3 search
	if (Quality == 3)
	{
		return normalize(noise) * 0.3090;
	}

	// quality level 4: jitter to anywhere in the cell, needs 4x4x4 search
	return noise;
}
float3 NoiseTileWrap(float3 v, bool bTiling, float RepeatSize)
{
	return bTiling ? ( frac(v / RepeatSize) * RepeatSize ) : v;
}
// 220 instruction Worley noise
float4 VoronoiNoise3D_ALU(float3 v, int Quality, bool bTiling, float RepeatSize, bool bDistanceOnly)
{
	float3 fv = frac(v), fv2 = frac(v + 0.5);
	float3 iv = floor(v), iv2 = floor(v + 0.5);

	// with initial minimum distance = infinity (or at least bigger than 4), first min is optimized away
	float4 mindist = float4( 0, 0, 0, 100 );
	float3 p, offset;

	// quality level 3: do a 3x3x3 search
	if (Quality == 3)
	{
		UNROLL for (offset.x = -1; offset.x <= 1; ++offset.x)
		{
			UNROLL for (offset.y = -1; offset.y <= 1; ++offset.y)
			{
				UNROLL for (offset.z = -1; offset.z <= 1; ++offset.z)
				{
					p = offset + VoronoiCornerSample(NoiseTileWrap(iv2 + offset, bTiling, RepeatSize), Quality);
					mindist = VoronoiCompare(mindist, iv2 + p, fv2 - p, bDistanceOnly);
				}
			}
		}
	}

	// everybody else searches a base 2x2x2 neighborhood
	else
	{
		UNROLL for (offset.x = 0; offset.x <= 1; ++offset.x)
		{
			UNROLL for (offset.y = 0; offset.y <= 1; ++offset.y)
			{
				UNROLL for (offset.z = 0; offset.z <= 1; ++offset.z)
				{
					p = offset + VoronoiCornerSample(NoiseTileWrap(iv + offset, bTiling, RepeatSize), Quality);
					mindist = VoronoiCompare(mindist, iv + p, fv - p, bDistanceOnly);

					// quality level 2, do extra set of points, offset by half a cell
					if (Quality == 2)
					{
						// 467 is just an offset to a different area in the random number field to avoid similar neighbor artifacts
						p = offset + VoronoiCornerSample(NoiseTileWrap(iv2 + offset, bTiling, RepeatSize) + 467, Quality);
						mindist = VoronoiCompare(mindist, iv2 + p, fv2 - p, bDistanceOnly);
					}
				}
			}
		}
	}

	// quality level 4: add extra sets of four cells in each direction
	if (Quality >= 4)
	{
		UNROLL for (offset.x = -1; offset.x <= 2; offset.x += 3)
		{
			UNROLL for (offset.y = 0; offset.y <= 1; ++offset.y)
			{
				UNROLL for (offset.z = 0; offset.z <= 1; ++offset.z)
				{
					// along x axis
					p = offset.xyz + VoronoiCornerSample(NoiseTileWrap(iv + offset.xyz, bTiling, RepeatSize), Quality);
					mindist = VoronoiCompare(mindist, iv + p, fv - p, bDistanceOnly);

					// along y axis
					p = offset.yzx + VoronoiCornerSample(NoiseTileWrap(iv + offset.yzx, bTiling, RepeatSize), Quality);
					mindist = VoronoiCompare(mindist, iv + p, fv - p, bDistanceOnly);

					// along z axis
					p = offset.zxy + VoronoiCornerSample(NoiseTileWrap(iv + offset.zxy, bTiling, RepeatSize), Quality);
					mindist = VoronoiCompare(mindist, iv + p, fv - p, bDistanceOnly);
				}
			}
		}
	}

	// transform squared distance to real distance
	return float4( mindist.xyz, sqrt(mindist.w) );
}
float Noise3D_Multiplexer(int Function, float3 Position, int Quality, bool bTiling, uint RepeatSize)
{
	// verified, HLSL compiled out the switch if Function is a constant
	//switch (Function)
	//{
	//	case 0:
	//		return SimplexNoise3D_TEX(Position);
	//	case 1:
	//		return GradientNoise3D_TEX(Position, bTiling, RepeatSize);
	//	case 2:
	//		return FastGradientPerlinNoise3D_TEX(Position);
	//	case 3:
	//		return GradientNoise3D_ALU(Position, bTiling, RepeatSize);
	//	case 4:
	//		return ValueNoise3D_ALU(Position, bTiling, RepeatSize);
		//default:
	return VoronoiNoise3D_ALU(Position, Quality, bTiling, RepeatSize, true).w * 2. - 1.;
	//}
	//return 0;
}

// @param LevelScale usually 2 but higher values allow efficient use of few levels
// @return in user defined range (OutputMin..OutputMax)
MaterialFloat MaterialExpressionNoise(float3 Position, float Scale, int Quality, int Function, bool bTurbulence, uint Levels, float OutputMin, float OutputMax, float LevelScale, float FilterWidth, bool bTiling, float RepeatSize)
{
	Position *= Scale;
	FilterWidth *= Scale;

	float Out = 0.0f;
	float OutScale = 1.0f;
	float InvLevelScale = 1.0f / LevelScale;

	LOOP for (uint i = 0; i < Levels; ++i)
	{
		// fade out noise level that are too high frequent (not done through dynamic branching as it usually requires gradient instructions)
		OutScale *= saturate(1.0 - FilterWidth);

		if (bTurbulence)
		{
			Out += abs(Noise3D_Multiplexer(Function, Position, Quality, bTiling, RepeatSize)) * OutScale;
		}
		else
		{
			Out += Noise3D_Multiplexer(Function, Position, Quality, bTiling, RepeatSize) * OutScale;
		}

		Position *= LevelScale;
		RepeatSize *= LevelScale;
		OutScale *= InvLevelScale;
		FilterWidth *= LevelScale;
	}

	if (!bTurbulence)
	{
		// bring -1..1 to 0..1 range
		Out = Out * 0.5f + 0.5f;
	}

	// Out is in 0..1 range
	return lerp(OutputMin, OutputMax, Out);
}

#define NUM_CUSTOM_PRIMITIVE_DATA 8 // Num float4s used for custom data. Must match FCustomPrimitiveData::NumCustomPrimitiveDataFloat4s in SceneTypes.h

struct FPrimitiveSceneData
{
	float4x4 LocalToWorld;
	float4 InvNonUniformScaleAndDeterminantSign;
	float4 ObjectWorldPositionAndRadius;
	float4x4 WorldToLocal;
	float4x4 PreviousLocalToWorld;
	float4x4 PreviousWorldToLocal;
	float3 ActorWorldPosition;
	float UseSingleSampleShadowFromStationaryLights;
	float3 ObjectBounds;
	float LpvBiasMultiplier;
	float DecalReceiverMask;
	float PerObjectGBufferData;
	float UseVolumetricLightmapShadowFromStationaryLights;
	float DrawsVelocity;
	float4 ObjectOrientation;
	float4 NonUniformScale;
	float3 LocalObjectBoundsMin;
	uint LightingChannelMask;
	float3 LocalObjectBoundsMax;
	uint LightmapDataIndex;
	float3 PreSkinnedLocalBoundsMin;
	int SingleCaptureIndex;
	float3 PreSkinnedLocalBoundsMax;
	uint OutputVelocity;
	float4 CustomPrimitiveData[ NUM_CUSTOM_PRIMITIVE_DATA ];
};

// Stride of a single primitive's data in float4's, must match C++
#define PRIMITIVE_SCENE_DATA_STRIDE 35

// Fetch from scene primitive buffer
FPrimitiveSceneData GetPrimitiveData( uint PrimitiveId )
{
	// Note: layout must match FPrimitiveSceneShaderData in C++
	// Relying on optimizer to remove unused loads

	FPrimitiveSceneData PrimitiveData;
	uint PrimitiveBaseOffset = PrimitiveId * PRIMITIVE_SCENE_DATA_STRIDE;
	PrimitiveData.LocalToWorld[ 0 ] = View.PrimitiveSceneData[ PrimitiveBaseOffset + 0 ];
	PrimitiveData.LocalToWorld[ 1 ] = View.PrimitiveSceneData[ PrimitiveBaseOffset + 1 ];
	PrimitiveData.LocalToWorld[ 2 ] = View.PrimitiveSceneData[ PrimitiveBaseOffset + 2 ];
	PrimitiveData.LocalToWorld[ 3 ] = View.PrimitiveSceneData[ PrimitiveBaseOffset + 3 ];

	PrimitiveData.InvNonUniformScaleAndDeterminantSign = View.PrimitiveSceneData[ PrimitiveBaseOffset + 4 ];
	PrimitiveData.ObjectWorldPositionAndRadius = View.PrimitiveSceneData[ PrimitiveBaseOffset + 5 ];

	PrimitiveData.WorldToLocal[ 0 ] = View.PrimitiveSceneData[ PrimitiveBaseOffset + 6 ];
	PrimitiveData.WorldToLocal[ 1 ] = View.PrimitiveSceneData[ PrimitiveBaseOffset + 7 ];
	PrimitiveData.WorldToLocal[ 2 ] = View.PrimitiveSceneData[ PrimitiveBaseOffset + 8 ];
	PrimitiveData.WorldToLocal[ 3 ] = View.PrimitiveSceneData[ PrimitiveBaseOffset + 9 ];

	PrimitiveData.PreviousLocalToWorld[ 0 ] = View.PrimitiveSceneData[ PrimitiveBaseOffset + 10 ];
	PrimitiveData.PreviousLocalToWorld[ 1 ] = View.PrimitiveSceneData[ PrimitiveBaseOffset + 11 ];
	PrimitiveData.PreviousLocalToWorld[ 2 ] = View.PrimitiveSceneData[ PrimitiveBaseOffset + 12 ];
	PrimitiveData.PreviousLocalToWorld[ 3 ] = View.PrimitiveSceneData[ PrimitiveBaseOffset + 13 ];

	PrimitiveData.PreviousWorldToLocal[ 0 ] = View.PrimitiveSceneData[ PrimitiveBaseOffset + 14 ];
	PrimitiveData.PreviousWorldToLocal[ 1 ] = View.PrimitiveSceneData[ PrimitiveBaseOffset + 15 ];
	PrimitiveData.PreviousWorldToLocal[ 2 ] = View.PrimitiveSceneData[ PrimitiveBaseOffset + 16 ];
	PrimitiveData.PreviousWorldToLocal[ 3 ] = View.PrimitiveSceneData[ PrimitiveBaseOffset + 17 ];

	PrimitiveData.ActorWorldPosition = View.PrimitiveSceneData[ PrimitiveBaseOffset + 18 ].xyz;
	PrimitiveData.UseSingleSampleShadowFromStationaryLights = View.PrimitiveSceneData[ PrimitiveBaseOffset + 18 ].w;

	PrimitiveData.ObjectBounds = View.PrimitiveSceneData[ PrimitiveBaseOffset + 19 ].xyz;
	PrimitiveData.LpvBiasMultiplier = View.PrimitiveSceneData[ PrimitiveBaseOffset + 19 ].w;

	PrimitiveData.DecalReceiverMask = View.PrimitiveSceneData[ PrimitiveBaseOffset + 20 ].x;
	PrimitiveData.PerObjectGBufferData = View.PrimitiveSceneData[ PrimitiveBaseOffset + 20 ].y;
	PrimitiveData.UseVolumetricLightmapShadowFromStationaryLights = View.PrimitiveSceneData[ PrimitiveBaseOffset + 20 ].z;
	PrimitiveData.DrawsVelocity = View.PrimitiveSceneData[ PrimitiveBaseOffset + 20 ].w;

	PrimitiveData.ObjectOrientation = View.PrimitiveSceneData[ PrimitiveBaseOffset + 21 ];
	PrimitiveData.NonUniformScale = View.PrimitiveSceneData[ PrimitiveBaseOffset + 22 ];

	PrimitiveData.LocalObjectBoundsMin = View.PrimitiveSceneData[ PrimitiveBaseOffset + 23 ].xyz;
	PrimitiveData.LightingChannelMask = asuint( View.PrimitiveSceneData[ PrimitiveBaseOffset + 23 ].w );

	PrimitiveData.LocalObjectBoundsMax = View.PrimitiveSceneData[ PrimitiveBaseOffset + 24 ].xyz;
	PrimitiveData.LightmapDataIndex = asuint( View.PrimitiveSceneData[ PrimitiveBaseOffset + 24 ].w );

	PrimitiveData.PreSkinnedLocalBoundsMin = View.PrimitiveSceneData[ PrimitiveBaseOffset + 25 ].xyz;
	PrimitiveData.SingleCaptureIndex = asuint( View.PrimitiveSceneData[ PrimitiveBaseOffset + 25 ].w );

	PrimitiveData.PreSkinnedLocalBoundsMax = View.PrimitiveSceneData[ PrimitiveBaseOffset + 26 ].xyz;
	PrimitiveData.OutputVelocity = asuint( View.PrimitiveSceneData[ PrimitiveBaseOffset + 26 ].w );

	UNROLL
		for( int i = 0; i < NUM_CUSTOM_PRIMITIVE_DATA; i++ )
		{
			PrimitiveData.CustomPrimitiveData[ i ] = View.PrimitiveSceneData[ PrimitiveBaseOffset + 27 + i ];
		}

	return PrimitiveData;
}
float2 SvPositionToViewportUV( float4 SvPosition )
{
	// can be optimized from 2SUB+2MUL to 2MAD
	float2 PixelPos = SvPosition.xy - View.ViewRectMin.xy;

	return PixelPos.xy * View.ViewSizeAndInvSize.zw;
}

#if POST_PROCESS_MATERIAL

float2 GetPixelPosition( FMaterialPixelParameters Parameters )
{
	return Parameters.SvPosition.xy - float2( PostProcessOutput_ViewportMin );
}

float2 GetViewportUV( FMaterialPixelParameters Parameters )
{
	return GetPixelPosition( Parameters ) * PostProcessOutput_ViewportSizeInverse;
}

#else

float2 GetPixelPosition( FMaterialPixelParameters Parameters )
{
	return Parameters.SvPosition.xy - float2( View.ViewRectMin.xy );
}

float2 GetViewportUV( FMaterialPixelParameters Parameters )
{
	return SvPositionToViewportUV( Parameters.SvPosition );
}

#endif
float2 CalcScreenUVFromOffsetFraction( float4 ScreenPosition, float2 OffsetFraction )
{
	float2 NDC = ScreenPosition.xy / ScreenPosition.w;
	// Apply the offset in NDC space so that it is consistent regardless of scene color buffer size
	// Clamp to valid area of the screen to avoid reading garbage
	//@todo - soft clamp
	float2 OffsetNDC = clamp( NDC + OffsetFraction * float2( 2, -2 ), -.999f, .999f );
	return float2( OffsetNDC * ResolvedView.ScreenPositionScaleBias.xy + ResolvedView.ScreenPositionScaleBias.wz );
}
float3 DecodeSceneColorForMaterialNode( float2 ScreenUV )
{
#if !defined(SceneColorCopyTexture)
	// Hit proxies rendering pass doesn't have access to valid render buffers
	return float3( 0.0f, 0.0f, 0.0f );
#else
	float4 EncodedSceneColor = Texture2DSample( SceneColorCopyTexture, SceneColorCopySampler, ScreenUV );

	// Undo the function in EncodeSceneColorForMaterialNode
	float3 SampledColor = pow( EncodedSceneColor.rgb, 4 ) * 10;

#if USE_PREEXPOSURE
	SampledColor *= View.OneOverPreExposure.xxx;
#endif

	return SampledColor;
#endif
}

float3 MaterialExpressionBlackBody( float Temp )
{
	float u = ( 0.860117757f + 1.54118254e-4f * Temp + 1.28641212e-7f * Temp * Temp ) / ( 1.0f + 8.42420235e-4f * Temp + 7.08145163e-7f * Temp * Temp );
	float v = ( 0.317398726f + 4.22806245e-5f * Temp + 4.20481691e-8f * Temp * Temp ) / ( 1.0f - 2.89741816e-5f * Temp + 1.61456053e-7f * Temp * Temp );

	float x = 3 * u / ( 2 * u - 8 * v + 4 );
	float y = 2 * v / ( 2 * u - 8 * v + 4 );
	float z = 1 - x - y;

	float Y = 1;
	float X = Y / y * x;
	float Z = Y / y * z;

	float3x3 XYZtoRGB =
	{
		 3.2404542, -1.5371385, -0.4985314,
		-0.9692660,  1.8760108,  0.0415560,
		 0.0556434, -0.2040259,  1.0572252
	};

	return mul( XYZtoRGB, float3( X, Y, Z ) ) * pow( 0.0004 * Temp, 4 );
}

#define DDX ddx
#define DDY ddy

float GetPerInstanceFadeAmount( FMaterialPixelParameters Parameters )
{
#if USE_INSTANCING
	return float( Parameters.PerInstanceParams.y );
#else
	return float( 1.0 );
#endif
}

MaterialFloat3x3 GetLocalToWorld3x3( uint PrimitiveId )
{
	//return (MaterialFloat3x3)GetPrimitiveData( PrimitiveId ).LocalToWorld;
	return (MaterialFloat3x3)Primitive.LocalToWorld;
}

MaterialFloat3x3 GetLocalToWorld3x3()
{
	return (MaterialFloat3x3)Primitive.LocalToWorld;
}

MaterialFloat3 TransformLocalVectorToWorld( FMaterialPixelParameters Parameters, MaterialFloat3 InLocalVector )
{
	return mul( InLocalVector, GetLocalToWorld3x3( Parameters.PrimitiveId ) );
}
float3 TransformLocalPositionToWorld( FMaterialPixelParameters Parameters, float3 InLocalPosition )
{
	//return mul( float4( InLocalPosition, 1 ), GetPrimitiveData( Parameters.PrimitiveId ).LocalToWorld ).xyz;
	return mul( float4( InLocalPosition, 1 ), Primitive.LocalToWorld ).xyz;
}

bool GetShadowReplaceState()
{
#ifdef SHADOW_DEPTH_SHADER
	return true;
#else
	return false;
#endif
}

float IsShadowDepthShader()
{
	return GetShadowReplaceState() ? 1.0f : 0.0f;
}

float3 GetTranslatedWorldPosition( FMaterialPixelParameters Parameters )
{
	return Parameters.WorldPosition_CamRelative;
}
float GetDistanceToNearestSurfaceGlobal( float3 Position )
{
	//Distance to nearest DistanceField voxel I think ?
	return 1000.0f;
}
float2 RotateScaleOffsetTexCoords( float2 InTexCoords, float4 InRotationScale, float2 InOffset )
{
	return float2( dot( InTexCoords, InRotationScale.xy ), dot( InTexCoords, InRotationScale.zw ) ) + InOffset;
}
float2 GetTanHalfFieldOfView()
{
	//@return tan(View.FieldOfViewWideAngles * .5)
	//return float2( View.ClipToView[ 0 ][ 0 ], View.ClipToView[ 1 ][ 1 ] );
	float EmulatedFOV = 3.14f / 2.0f;
	return float2( EmulatedFOV, EmulatedFOV );
}
float Pow2( float x )
{
	return x * x;
}
float3 HairAbsorptionToColor( float3 A, float B = 0.3f )
{
	const float b2 = B * B;
	const float b3 = B * b2;
	const float b4 = b2 * b2;
	const float b5 = B * b4;
	const float D = ( 5.969f - 0.215f * B + 2.532f * b2 - 10.73f * b3 + 5.574f * b4 + 0.245f * b5 );
	return exp( -sqrt( A ) * D );
}
float3 HairColorToAbsorption( float3 C, float B = 0.3f )
{
	const float b2 = B * B;
	const float b3 = B * b2;
	const float b4 = b2 * b2;
	const float b5 = B * b4;
	const float D = ( 5.969f - 0.215f * B + 2.532f * b2 - 10.73f * b3 + 5.574f * b4 + 0.245f * b5 );
	return Pow2( log( C ) / D );
}
float3 GetHairColorFromMelanin( float InMelanin, float InRedness, float3 InDyeColor )
{
	InMelanin = saturate( InMelanin );
	InRedness = saturate( InRedness );
	const float Melanin = -log( max( 1 - InMelanin, 0.0001f ) );
	const float Eumelanin = Melanin * ( 1 - InRedness );
	const float Pheomelanin = Melanin * InRedness;

	const float3 DyeAbsorption = HairColorToAbsorption( saturate( InDyeColor ) );
	const float3 Absorption = Eumelanin * float3( 0.506f, 0.841f, 1.653f ) + Pheomelanin * float3( 0.343f, 0.733f, 1.924f );

	return HairAbsorptionToColor( Absorption + DyeAbsorption );
}

float3 MaterialExpressionGetHairColorFromMelanin( float Melanin, float Redness, float3 DyeColor )
{
	return GetHairColorFromMelanin( Melanin, Redness, DyeColor );
}
bool GetRayTracingQualitySwitch()
{
#if RAYHITGROUPSHADER
	return true;
#else
	return false;
#endif
}
MaterialFloat2 GetDefaultSceneTextureUV( FMaterialPixelParameters Parameters, uint SceneTextureId )
{
	return float2( 0, 0 );
}
float4 SceneTextureLookup( float2 UV, int SceneTextureIndex, bool bFiltered )
{
	return float4( 0, 0, 0, 0 );
}
float3 MaterialExpressionAtmosphericLightVector( FMaterialPixelParameters Parameters )
{
#if MATERIAL_ATMOSPHERIC_FOG
	return ResolvedView.AtmosphereLightDirection[ 0 ].xyz;
#else
	return float3( 0.f, 0.f, 0.f );
#endif
}

#if TEX_COORD_SCALE_ANALYSIS
	#define MaterialStoreTexCoordScale(Parameters, UV, TextureReferenceIndex) StoreTexCoordScale(Parameters.TexCoordScalesParams, UV, TextureReferenceIndex)
	#define MaterialStoreTexSample(Parameters, UV, TextureReferenceIndex) StoreTexSample(Parameters.TexCoordScalesParams, UV, TextureReferenceIndex)
#else
	#define MaterialStoreTexCoordScale(Parameters, UV, TextureReferenceIndex) 1.0f
	#define MaterialStoreTexSample(Parameters, UV, TextureReferenceIndex) 1.0f
#endif