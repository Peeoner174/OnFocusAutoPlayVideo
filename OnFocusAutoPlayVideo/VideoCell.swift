//
//  VideoCell.swift
//  OnFocusAutoPlayVideo
//
//  Created by MSI on 02.06.2020.
//  Copyright © 2020 MSI. All rights reserved.
//

import UIKit
import AVFoundation

class VideoCell: UITableViewCell, AutoPlayVideoLayerContainer {
    
    // MARK: - NITAutoPlayVideoLayerContainer
    
    var videoURL: String? {
        didSet {
            if let videoURL = self.videoURL {
                VideoPlayerManager.shared.setupVideoFor(url: videoURL)
            }
            self.videoLayer.isHidden = videoURL == nil
        }
    }
    
    var videoLayer: AVPlayerLayer = AVPlayerLayer()
    
    // MARK: - Outlets
    
    @IBOutlet weak var previewImageView: UIImageView!
    
    // MARK: - Setup methods
    
    func configure(model: TableViewCellModel) {
        previewImageView.image = UIImage(named: model.imageName)
        self.videoURL = model.videoURL
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        setVideoLayerOn(imageView: previewImageView)
    }
    
    private func setVideoLayerOn(imageView: UIImageView) {
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoLayer.frame = CGRect(x: 0, y: 0, width: imageView.frame.width, height: imageView.frame.height)
        imageView.layer.addSublayer(videoLayer)
    }
}
