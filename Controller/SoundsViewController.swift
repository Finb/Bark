//
//  SoundsViewController.swift
//  Bark
//
//  Created by huangfeng on 2020/9/14.
//  Copyright © 2020 Fin. All rights reserved.
//

import UIKit
import Material
import AVKit

class SoundsViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = Color.grey.lighten5
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "\(SoundCell.self)")
        return tableView
    }()
    let audios:[AVURLAsset] = {
        var urls = Bundle.main.urls(forResourcesWithExtension: "caf", subdirectory: nil) ?? []
        urls.sort { (u1, u2) -> Bool in
            u1.lastPathComponent.localizedStandardCompare(u2.lastPathComponent) == ComparisonResult.orderedAscending
        }
        let audios = urls.map { (url) -> AVURLAsset in
            let asset = AVURLAsset(url: url)
            return asset
        }
        return audios
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("notificationSound")
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        let header = UILabel()
        header.fontSize = 12
        header.text = "    \(NSLocalizedString("previewSound"))"
        header.textColor = Color.darkText.secondary
        header.frame = CGRect(x: 0, y: 0, width: 0, height: 40)
        self.tableView.tableHeaderView = header
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audios.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "\(SoundCell.self)") as? SoundCell ?? SoundCell()
        cell.nameLabel.text = audios[indexPath.row].url.deletingPathExtension().lastPathComponent
        cell.durationLabel.text = "\(String(format: "%.2g", CMTimeGetSeconds(audios[indexPath.row].duration))) second(s)";
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var soundID:SystemSoundID = 0
        AudioServicesCreateSystemSoundID(audios[indexPath.row].url as CFURL, &soundID)
        AudioServicesPlaySystemSoundWithCompletion(soundID) {
            AudioServicesDisposeSystemSoundID(soundID)
        }
    }
}
