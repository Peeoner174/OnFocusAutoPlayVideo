//
//  NITVideoPlayerManager.swift
//  OnFocusAutoPlayVideo
//
//  Created by MSI on 02.06.2020.
//  Copyright © 2020 MSI. All rights reserved.
//

import UIKit
import AVFoundation

class VideoPlayerManager: NSObject {
    
    //MARK: - Singleton
    static let shared = VideoPlayerManager()

    // MARK: - Public properties
    
    /// ON/OFF sound of video
    var mute: Bool = false
    
    /// Replay video after reach end
    var loopVideo: Bool = true
    
    /// For lower bitrate of video
    let preferredPeakBitRate = 10000
    
    /// Play specified segment of video
    typealias PlaybackSegment = (startTime: Double?, endTime: Double?)
    var playbackSegment: PlaybackSegment?
    
    // MARK: - Private properties
    
    /// Video url for currently playing video
    private var videoURL: String?
    
    /// Cache of player and player item
    private var videoCache = NSCache<NSString, VideoContainer>()
    
    /// Current AVPlayerLayer that is playing video
    private var currentLayer: AVPlayerLayer?
    
    /// Context observer
    static private var playerViewControllerKVOContext = 0
    
    /// For removing observers for player items that are not being played.
    private var observingURLs = Dictionary<String, Bool>()
    
    // MARK: - Inits
    override private init() {
        super.init()
        videoCache.delegate = self
    }
    
    // MARK: - Public methods
    
    /// Create and caching videocontainer
    /// Load video by url if it not exist in videoCache
    ///
    /// - Parameter url: Path of video.
    public func setupVideoFor(url: String) {
        guard self.videoCache.object(forKey: url as NSString) == nil else { return }
        guard let URL = URL(string: url) else { return }
        
        let asset = AVURLAsset(url: URL)
        
        let playableKey = "playable"
        let requestedKeys = [playableKey]
        asset.loadValuesAsynchronously(forKeys: requestedKeys) { [weak self] in
            guard let self = self else { return }
            
            var error: NSError? = nil
            
            let status = asset.statusOfValue(forKey: playableKey, error: &error)
            switch status {
            case .loaded:
                break
            case .failed, .cancelled:
                print("Failed to load video asset successfully")
                return
            default:
                print("Unkown state of video asset")
                return
            }
            let player = AVPlayer()
            let item = AVPlayerItem(asset: asset)
            DispatchQueue.main.async {
                let videoContainer = VideoContainer(player: player, item: item, url: url)
                self.setPlaybackSegment(for: videoContainer)
                self.videoCache.setObject(videoContainer, forKey: url as NSString)
                
                // Try to play video again in case when playvideo method was called, but
                // video asset was not obtained
                if self.videoURL == url, let layer = self.currentLayer {
                    self.playVideo(withLayer: layer, url: url)
                }
            }
        }
    }
    
    /// Play video if ready
    ///
    /// - Parameter layer: Layer on this will be play video
    /// - Parameter url: Url of video
    public func playVideo(withLayer layer: AVPlayerLayer, url: String) {
        videoURL = url
        currentLayer = layer
        
        if let videoContainer = self.videoCache.object(forKey: url as NSString) {
            layer.player = videoContainer.player
            videoContainer.playVideo()
            addObservers(url: url, videoContainer: videoContainer, playerLayer: layer)
        }
        DispatchQueue.main.async {
            if let videoContainer = self.videoCache.object(forKey: url as NSString),
                videoContainer.player.currentItem?.status == .readyToPlay  {
                videoContainer.playVideo()
            }
        }
    }
    
    public func pauseVideo(forLayer layer: AVPlayerLayer, url: String) {
        videoURL = nil
        currentLayer = nil
        
        if let videoContainer = self.videoCache.object(forKey: url as NSString) {
            videoContainer.pauseVideo()
            removeObserverFor(url: url)
        }
    }
    
    public func stopVideo(forLayer layer: AVPlayerLayer, url: String) {
        videoURL = nil
        currentLayer = nil
        
        if let videoContainer = self.videoCache.object(forKey: url as NSString) {
            videoContainer.stopVideo()
            removeObserverFor(url: url)
        }
    }
    
    public func removeVideoLayerFor(cell: AutoPlayVideoLayerContainer) {
        if let url = cell.videoURL {
            removeFromSuperLayer(layer: cell.videoLayer, url: url)
        }
    }
    
    public func getVideoFromCash(byUrl url: String) -> VideoContainer? {
        return self.videoCache.object(forKey: url as NSString)
    }
    
    // MARK: - Private methods
    
    private func setPlaybackSegment(for videoContainer: VideoContainer) {
        guard let playbackSegment = self.playbackSegment else {
            return
        }
        videoContainer.setPlaybackSegment(playbackSegment: playbackSegment)
    }
    
    private func setPlaybackSegment(player: AVPlayer, playerItem: AVPlayerItem) {
        guard let playbackSegment = self.playbackSegment else {
            return
        }
        if let startTime = playbackSegment.startTime {
            player.seek(to: CMTime(seconds: startTime, preferredTimescale: 600))
        }
        if let endTime = playbackSegment.endTime {
            playerItem.forwardPlaybackEndTime = CMTime(seconds: endTime, preferredTimescale: 600)
        }
    }
    
    private func removeFromSuperLayer(layer: AVPlayerLayer, url: String) {
        videoURL = nil
        currentLayer = nil
        if let videoContainer = self.videoCache.object(forKey: url as NSString) {
            videoContainer.pauseVideo()
            removeObserverFor(url: url)
        }
        layer.player = nil
    }
    
    private func currentVideoContainer() -> VideoContainer? {
        if let currentVideoUrl = videoURL {
            if let videoContainer = videoCache.object(forKey: currentVideoUrl as NSString) {
                return videoContainer
            }
        }
        return nil
    }
    
}

// MARK: - NSCacheDelegate
extension VideoPlayerManager: NSCacheDelegate {
    
    // Set observing urls false when objects are removed from cache
    
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        if let videoObject = obj as? VideoContainer {
            observingURLs[videoObject.url] = false
        }
    }
    
}

// MARK: - Register/remove observers

extension VideoPlayerManager {
    
    private func addObservers(url: String, videoContainer: VideoContainer, playerLayer: AVPlayerLayer) {
        if self.observingURLs[url] == false || self.observingURLs[url] == nil {
            
            videoContainer.player.currentItem?.addObserver(self,
                                                           forKeyPath: "status",
                                                           options: [.new, .initial],
                                                           context: &VideoPlayerManager.playerViewControllerKVOContext)
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.playerItemDidReachEnd(note:)),
                                                   name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                   object: videoContainer.player.currentItem)

            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.playVideo(note:)),
                                                   name: UIApplication.didBecomeActiveNotification,
                                                   object: nil)
            
            self.observingURLs[url] = true
        }
        
    }
    
    private func removeObserverFor(url: String) {
        if let videoContainer = self.videoCache.object(forKey: url as NSString) {
            if let currentItem = videoContainer.player.currentItem, observingURLs[url] == true {
                
                currentItem.removeObserver(self,
                                           forKeyPath: "status",
                                           context: &VideoPlayerManager.playerViewControllerKVOContext)
                
                NotificationCenter.default.removeObserver(self,
                                                          name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                          object: currentItem)
                
                NotificationCenter.default.removeObserver(self,
                                                          name: UIApplication.didEnterBackgroundNotification,
                                                          object: nil)
                
                observingURLs[url] = false
            }
        }
    }
}

// MARK: - Handlers observer notifications

extension VideoPlayerManager {
    
    @objc private func playVideo(note: NSNotification) {
        guard let currentLayer = self.currentLayer, let videoURL = self.videoURL else {
            return
        }
        playVideo(withLayer: currentLayer, url: videoURL)
    }
    
    @objc private func playerItemDidReachEnd(note: NSNotification) {
        guard let playerItem = note.object as? AVPlayerItem,
            let currentPlayer = currentVideoContainer()?.player,
            self.loopVideo else {
                return
        }
        if let currentItem = currentPlayer.currentItem, currentItem == playerItem {
            currentPlayer.seek(to: CMTime.zero)
            setPlaybackSegment(player: currentPlayer, playerItem: currentItem)
            currentPlayer.play()
        }
    }
    
    // Play video only when current videourl's player is ready to play
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        // Make sure the this KVO callback was intended for this view controller.
        guard context == &VideoPlayerManager.playerViewControllerKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        switch keyPath! {
        case "status":
            self.handleObserveValueForStatus(of: object, change: change)
        default:
            break
        }
    }
    
    private func handleObserveValueForStatus(of object: Any?, change: [NSKeyValueChangeKey : Any]?) {
        guard let statusValue = change?[NSKeyValueChangeKey.newKey] as? Int else {
            return
        }
        
        let status = AVPlayer.Status(rawValue: statusValue) ?? .unknown
        
        switch status {
        case .readyToPlay:
            guard let item = object as? AVPlayerItem, let currentItem = currentVideoContainer()?.player.currentItem else {
                return
            }
            if item == currentItem && currentVideoContainer()?.playOn == true {
                currentVideoContainer()?.playVideo()
            }
        case .failed:
            break
        case .unknown:
            break
        @unknown default:
            fatalError()
        }
    }
}
