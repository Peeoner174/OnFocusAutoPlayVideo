//
//  NITVideoContainer.swift
//  OnFocusAutoPlayVideo
//
//  Created by MSI on 02.06.2020.
//  Copyright © 2020 MSI. All rights reserved.
//

import UIKit
import AVFoundation

class VideoContainer {
    
    // MARK: - Properties
    var url: String
    
    let player: AVPlayer
    let playerItem: AVPlayerItem
    
    private(set) var playOn: Bool?
    
    // MARK: - Init
    init(player: AVPlayer, item: AVPlayerItem, url: String) {
        self.player = player
        self.playerItem = item
        self.url = url
        self.playOn = true
        
        player.replaceCurrentItem(with: playerItem)
    }
    
    // MARK: - Public methods
    public func playVideo() {
        player.isMuted = VideoPlayerManager.shared.mute
        playerItem.preferredPeakBitRate = Double(VideoPlayerManager.shared.preferredPeakBitRate)
        
        if playerItem.status == .readyToPlay {
            player.play()
            playOn = true
        }
    }
    
    public func pauseVideo() {
        player.isMuted = VideoPlayerManager.shared.mute
        playerItem.preferredPeakBitRate = Double(VideoPlayerManager.shared.preferredPeakBitRate)
        
        player.pause()
        playOn = false
    }
    
    public func stopVideo() {
        player.seek(to: .zero)
        self.pauseVideo()
    }
    
    public func setPlaybackSegment(playbackSegment: VideoPlayerManager.PlaybackSegment) {
        if let startTime = playbackSegment.startTime {
            self.player.seek(to: CMTime(seconds: startTime, preferredTimescale: 600))
        }
        if let endTime = playbackSegment.endTime {
            self.playerItem.forwardPlaybackEndTime = CMTime(seconds: endTime, preferredTimescale: 600)
        }
    }
}

// MARK: - NSDiscardableContent
// Conforming to NSDiscardableContent causes the conforming type not to get automatically evicted from an NSCache upon backgrounding
// https://stackoverflow.com/questions/13163480/nscache-and-background/13579963#13579963
extension VideoContainer: NSDiscardableContent {
    public func beginContentAccess() -> Bool { return true }
    
    public func endContentAccess() { }
    
    public func discardContentIfPossible() { }
    
    public func isContentDiscarded() -> Bool { return false }
}

// MARK: - NSCopying
extension VideoContainer: NSCopying {
    
    func copy(with zone: NSZone? = nil) -> Any {
        let playerItemCopy = playerItem.copy() as! AVPlayerItem
        let playerCopy = AVPlayer(playerItem: playerItemCopy)
        playerItemCopy.seek(to: playerItem.currentTime(), completionHandler: nil)
        let copy = VideoContainer(player: playerCopy, item: playerItemCopy, url: url)
        return copy
    }
}
