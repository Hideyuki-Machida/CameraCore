//
//  Binarization.metal
//  CameraCoreExample
//
//  Created by hideyuki machida on 2020/08/02.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

#include <metal_stdlib>
#include <metal_common>
#include <simd/simd.h>

using namespace metal;

kernel void kernel_Binarization(texture2d<float, access::sample> disparityTexture [[texture(0)]],
                                texture2d<float, access::write> outputTexture [[texture(1)]],
                                constant float &intensity [[ buffer(0) ]],
                                uint2 gid [[thread_position_in_grid]])
{
    float4 disparityTextureColor = disparityTexture.read(gid);
    float r = disparityTextureColor.r > intensity ? 1.0 : 0.0;
    outputTexture.write(float4(r, r, r, 1.0), gid);
}
