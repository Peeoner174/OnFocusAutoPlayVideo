//
//  NITVideoPlayerProtocols.swift
//  OnFocusAutoPlayVideo
//
//  Created by MSI on 02.06.2020.
//  Copyright © 2020 MSI. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

/// Video will be added like layer on UIView that realized this protocol
protocol AutoPlayVideoLayerContainer: UIView {
    var videoURL: String? { get set }
    var videoLayer: AVPlayerLayer { get set }
}

protocol AutoPlayVideoLayerContainerDelegate: UIScrollView {
    typealias VideoContainerMeta = (IndexPath?, AutoPlayVideoLayerContainer)
    var visibleVideoLayerContainers: [VideoContainerMeta] { get }
    
    func rectOfContainer(_ containerMeta: VideoContainerMeta) -> CGRect?
    
    /// Use on scrollViewDidScroll, viewDidAppear, enterForeground
    func playFocusedVideo()
    
    /// Use on viewDidDissapear, enterBackground
    func pauseVideo()
    
    /// Use on viewDidDissapear, enterBackground
    func stopVideo()
}

extension AutoPlayVideoLayerContainerDelegate {
    func pauseVideo() {
        visibleVideoLayerContainers.forEach {
            VideoPlayerManager.shared.pauseVideo(forLayer: $0.1.videoLayer, url: $0.1.videoURL!)
        }
    }
    
    func stopVideo() {
        visibleVideoLayerContainers.forEach {
            VideoPlayerManager.shared.stopVideo(forLayer: $0.1.videoLayer, url: $0.1.videoURL!)
        }
    }
    
    func playFocusedVideo() {
        var focusVideoContainer: AutoPlayVideoLayerContainer?
        
        for videoContainerMeta in visibleVideoLayerContainers {
            let videoContainer = videoContainerMeta.1
            let videoURL = videoContainer.videoURL!
            
            if focusVideoContainer == nil {
                guard let rect = rectOfContainer(videoContainerMeta) else { continue }
                if bounds.contains(rect) {
                    VideoPlayerManager.shared.playVideo(withLayer: videoContainer.videoLayer, url: videoURL)
                    focusVideoContainer = videoContainer
                } else {
                    VideoPlayerManager.shared.pauseVideo(forLayer: videoContainer.videoLayer, url: videoURL)
                }
            } else {
                VideoPlayerManager.shared.pauseVideo(forLayer: videoContainer.videoLayer, url: videoURL)
            }
        }
    }
}

extension UITableView: AutoPlayVideoLayerContainerDelegate {
    var visibleVideoLayerContainers: [VideoContainerMeta] {
        return indexPathsForVisibleRows?.compactMap {
            guard
                let cell = cellForRow(at: $0),
                let videoLayerContainer = cell as? AutoPlayVideoLayerContainer,
                let _ = videoLayerContainer.videoURL else {
                    return nil
            }
            return ($0, videoLayerContainer)
            } ?? []
    }
    
    func rectOfContainer(_ containerMeta: VideoContainerMeta) -> CGRect? {
        guard let indexPath = containerMeta.0 else { return nil }
        return rectForRow(at: indexPath)
    }
}

extension UICollectionView: AutoPlayVideoLayerContainerDelegate {
    var visibleVideoLayerContainers: [VideoContainerMeta] {
        return indexPathsForVisibleItems.compactMap {
            guard
                let cell = cellForItem(at: $0),
                let videoLayerContainer = cell as? AutoPlayVideoLayerContainer,
                let _ = videoLayerContainer.videoURL else {
                    return nil
            }
            return ($0, videoLayerContainer)
        }
    }
    
    func rectOfContainer(_ containerMeta: VideoContainerMeta) -> CGRect? {
        guard let indexPath = containerMeta.0 else { return nil }
        return layoutAttributesForItem(at: indexPath)?.frame
    }
}

