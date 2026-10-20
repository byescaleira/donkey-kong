import Foundation
import Metal

#if canImport(MetalFX)
    import MetalFX
#endif

public final class SpatialUpscaler {
    public private(set) var isAvailable: Bool

    #if canImport(MetalFX)
        private var scaler: (any MTLFXSpatialScaler)?
        private var inputSize = Vector2Int(x: 0, y: 0)
        private var outputSize = Vector2Int(x: 0, y: 0)
        private var format: MTLPixelFormat = .invalid
    #endif

    public init(device: any MTLDevice) {
        #if canImport(MetalFX)
            isAvailable = MTLFXSpatialScalerDescriptor.supportsDevice(device)
        #else
            isAvailable = false
        #endif
    }

    public func encode(
        commandBuffer: any MTLCommandBuffer, device: any MTLDevice, input: any MTLTexture,
        output: any MTLTexture
    ) -> Bool {
        #if canImport(MetalFX)
            let requestedInput = Vector2Int(x: input.width, y: input.height)
            let requestedOutput = Vector2Int(x: output.width, y: output.height)
            guard
                let scaler = scaler(
                    device: device, input: requestedInput, output: requestedOutput,
                    format: input.pixelFormat)
            else { return false }
            scaler.colorTexture = input
            scaler.outputTexture = output
            scaler.encode(commandBuffer: commandBuffer)
            return true
        #else
            return false
        #endif
    }

    #if canImport(MetalFX)
        private func scaler(
            device: any MTLDevice, input: Vector2Int, output: Vector2Int, format: MTLPixelFormat
        ) -> (any MTLFXSpatialScaler)? {
            guard isAvailable, !input.isEmpty, !output.isEmpty else { return nil }
            if let scaler, inputSize == input, outputSize == output, self.format == format {
                return scaler
            }

            let descriptor = MTLFXSpatialScalerDescriptor()
            descriptor.inputWidth = input.x
            descriptor.inputHeight = input.y
            descriptor.outputWidth = output.x
            descriptor.outputHeight = output.y
            descriptor.colorTextureFormat = format
            descriptor.outputTextureFormat = format
            descriptor.colorProcessingMode = .perceptual

            guard let made = descriptor.makeSpatialScaler(device: device) else {
                isAvailable = false
                scaler = nil
                return nil
            }
            scaler = made
            inputSize = input
            outputSize = output
            self.format = format
            return made
        }
    #endif
}
