import AVKit
import CoreImage
import Foundation

struct SampleBufferTransformer {
    func transform(videoSampleBuffer: CMSampleBuffer) -> CMSampleBuffer {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(videoSampleBuffer) else {
            print("Failed to get pixel buffer")
            fatalError()
        }
        
        let sourceImage = CIImage(cvImageBuffer: pixelBuffer)
        let filter = CIFilter(name: "CIColorInvert", parameters: [kCIInputImageKey: sourceImage])!
        let filteredImage = filter.outputImage!

        var pixelBufferOut: CVPixelBuffer? = nil
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        let attributes = CVBufferCopyAttachments(pixelBuffer, .shouldPropagate)!
        CVPixelBufferCreate(nil, width, height, pixelFormat, attributes, &pixelBufferOut)
        CVBufferPropagateAttachments(pixelBuffer, pixelBufferOut!)

        let filteredPixelBuffer = pixelBuffer

        let context = CIContext(options: [CIContextOption.outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])
        context.render(filteredImage, to: filteredPixelBuffer)

        let presentationTimestamp = CMSampleBufferGetPresentationTimeStamp(videoSampleBuffer)
        var timing = CMSampleTimingInfo(duration: CMTime.invalid, presentationTimeStamp: presentationTimestamp, decodeTimeStamp: CMTime.invalid)

        var processedSampleBuffer: CMSampleBuffer? = nil
        var formatDescription: CMFormatDescription? = nil
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil, imageBuffer: filteredPixelBuffer, formatDescriptionOut: &formatDescription)
        CMSampleBufferCreateReadyWithImageBuffer(allocator: nil, imageBuffer: filteredPixelBuffer, formatDescription: formatDescription!, sampleTiming: &timing, sampleBufferOut: &processedSampleBuffer)

        guard let newBuffer = CMSampleBufferGetImageBuffer(processedSampleBuffer!) else {
            print("failed to get pixel buffer")
            fatalError()
        }
        guard let result = try? newBuffer.mapToSampleBuffer(timestamp: (processedSampleBuffer!).presentationTimeStamp) else {
            fatalError()
        }

        return result
    }
}
