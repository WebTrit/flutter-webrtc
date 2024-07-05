import UIKit
import AVFoundation
import CallKit

@objc public class DTMFPlayer: NSObject {

    var _engine: AVAudioEngine
    var _player:AVAudioPlayerNode
    
    public override init() {
        _engine = AVAudioEngine();
        _player = AVAudioPlayerNode();
        _engine.attach(_player);
        _engine.connect(_player, to:_engine.mainMixerNode, format:nil);
        try? _engine.start();
    
        super.init()
        NotificationCenter.default.addObserver(self,
                selector: #selector(handleInterruption),
                name: NSNotification.Name.AVAudioEngineConfigurationChange,
                object: nil
             )
    }
    
    @objc func handleInterruption(notification: Notification) {
        print(notification)
        _engine.attach(_player);
        _engine.connect(_player, to:_engine.mainMixerNode, format:nil);
        try? _engine.start();
    }
    
    @objc public func playTone(digits: String)
    {
       
        let audioSession = AVAudioSession.sharedInstance()
        let sampleRate = Float(audioSession.sampleRate)
        
        
        if let tones = DTMF.tonesForString(digits) {
            let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Double(sampleRate), channels: 2, interleaved: false)!
            
            var allSamples = [Float]()
            for tone in tones {
                let samples = DTMF.generateDTMF(tone, markSpace: MarkSpaceType(Float(100), Float(20)), sampleRate: sampleRate)
                allSamples.append(contentsOf: samples)
            }
            
            let frameCount = AVAudioFrameCount(allSamples.count)
            let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
            
            buffer.frameLength = frameCount
            let channelMemory = buffer.floatChannelData!
            for channelIndex in 0 ..< Int(audioFormat.channelCount) {
                let frameMemory = channelMemory[channelIndex]
                memcpy(frameMemory, allSamples, Int(frameCount) * MemoryLayout<Float>.size)
            }
            
            if _engine.isRunning {
                _player.scheduleBuffer(buffer, at:nil,completionHandler:nil)
                _player.play()
                print("played")
            }
           
    }
  }
  
}
