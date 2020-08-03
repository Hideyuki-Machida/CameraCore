//
//  Mask.metal
//  CameraCoreExample
//
//  Created by hideyuki machida on 2020/08/02.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

#include <metal_stdlib>
#include <metal_common>
#include <simd/simd.h>

using namespace metal;

kernel void kernel_Mask(texture2d<float, access::sample> sorceTexture [[texture(0)]],
                        texture2d<float, access::sample> maskTexture [[texture(1)]],
                        texture2d<float, access::write> outputTexture [[texture(2)]],
                        uint2 gid [[thread_position_in_grid]])
{
    float4 sorceTextureColor = sorceTexture.read(gid);
    float4 maskTextureColor = maskTexture.read(gid);
    float4 maskColor = float4(
                              sorceTextureColor.r * maskTextureColor.r,
                              sorceTextureColor.g * maskTextureColor.g,
                              sorceTextureColor.b * maskTextureColor.b,
                              1.0);
    outputTexture.write(maskColor, gid);
}
