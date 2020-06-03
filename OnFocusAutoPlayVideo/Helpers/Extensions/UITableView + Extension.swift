//
//  UITableView + Extension.swift
//  OnFocusAutoPlayVideo
//
//  Created by MSI on 02.06.2020.
//  Copyright © 2020 MSI. All rights reserved.
//

import UIKit

extension UITableView {
    
    // MARK: Cells
    
    /// Returns a reusable table-view cell object and adds it to the table.
    ///
    /// - Parameters:
    ///   - cellType: type for casting cell
    ///   - indexPath: index path specifying the location of the cell
    ///
    ///  -  Return cell. If casting fail return nil for release version and fatalError for debug version
    func dequeueReusableCell<T: UITableViewCell>(_ cellType: T.Type = T.self, forIndexPath indexPath: IndexPath) -> T {
        guard let cell = self.dequeueReusableCell(withIdentifier: cellType.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }
        return cell
    }
    
    func registerCells(classes: [UITableViewCell.Type]) {
        
        for cl in classes {
            let cellName = cl.reuseIdentifier
            let cellNib = UINib(nibName: cellName, bundle: nil)
            self.register(cellNib, forCellReuseIdentifier: cellName)
        }
    }
}

