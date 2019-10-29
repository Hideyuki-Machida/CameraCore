//
//  OpenGLUtils.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/12/19.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import GLKit
import OpenGLES

public class GLTextureConvert {
    var unmanagedVideoTexture: Unmanaged<CVOpenGLESTexture>?
    var videoTexture: CVOpenGLESTexture?
    var videoTextureID: GLuint?
    var coreVideoTextureCache: CVOpenGLESTextureCache?
    var context: EAGLContext?
    
    public init(context: EAGLContext){
        self.context = context
        CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, self.context!, nil, &coreVideoTextureCache)
        //print("coreVideoTextureCache : \(self.coreVideoTextureCache)")
    }
    
    public func getTextureFromSampleBuffer(pixelBuffer: inout CVPixelBuffer, textureID: inout GLuint?) -> Bool {
        
        let textureWidth: Int = CVPixelBufferGetWidth(pixelBuffer)
        let textureHeight: Int = CVPixelBufferGetHeight(pixelBuffer)
        
        let cvRet: CVReturn = CVOpenGLESTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            coreVideoTextureCache!,
            pixelBuffer,
            nil,
            GLenum(GL_TEXTURE_2D),
            GL_RGBA,
            GLsizei(textureWidth),
            GLsizei(textureHeight),
            GLenum(GL_BGRA),
            UInt32(GL_UNSIGNED_BYTE),
            0,
            &videoTexture
        )
        
        guard kCVReturnSuccess == cvRet else { return false }
        guard videoTexture != nil else { return false }
        textureID = CVOpenGLESTextureGetName(videoTexture!);
        guard textureID != nil else { return false }
        glBindTexture(GLenum(GL_TEXTURE_2D), textureID!)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        return true
    }
    
    public func clear() {
        self.videoTexture = nil
        guard self.coreVideoTextureCache != nil else { return }
        CVOpenGLESTextureCacheFlush(self.coreVideoTextureCache!, 0)
    }
    
}
