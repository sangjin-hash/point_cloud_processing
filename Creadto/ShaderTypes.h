#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

enum TextureIndices {
    kTextureY = 0,
    kTextureCbCr = 1,
    kTextureDepth = 2,
    kTextureConfidence = 3
};

enum BufferIndices {
    kPointCloudUniforms = 0,
    kParticleUniforms = 1,
    kWorldCoordinateUniforms = 2,
    kGridPoints = 3
};

struct RGBUniforms {
    matrix_float3x3 viewToCamera;
    float viewRatio;
    float radius;
};

struct PointCloudUniforms {
    matrix_float4x4 viewProjectionMatrix;
    
    /**
     Description : localToWorld and cameraToWorld are the same matrices required when changing from the camera's local space to the world space.
             However, localToWorld uses world coordinates for rendering to render particles, and cameraToWorld uses the world coordinates collected based on the camera.
     */
    matrix_float4x4 localToWorld;
    matrix_float4x4 cameraToWorld;
    
    matrix_float3x3 cameraIntrinsicsInversed;
    simd_float2 cameraResolution;
    matrix_float4x4 rotateAroundY;

    float particleSize;
    int maxPoints;
    int pointCloudCurrentIndex;
    int confidenceThreshold;
};

struct ParticleUniforms {
    simd_float3 position;
    simd_float3 color;
    float confidence;
};

#endif /* ShaderTypes_h */
