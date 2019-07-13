//
//  FilesViewController.swift
//  awesomeOCR
//
//  Created by maRk'sTheme on 2019/7/1.
//  Copyright © 2019 maRk. All rights reserved.
//

import UIKit

class FilesViewController: UIViewController {

    var data: [[String: String]] = []
    var label: UILabel!

    @IBOutlet weak var tableView: UITableView!

    override func awakeFromNib() {
        super.awakeFromNib()
        view.backgroundColor = .white
        
        navigationItem.title = "文件"

        tableView.delegate = self
        tableView.dataSource = self

        label = UILabel().construct({
            $0.text = "没有文档哟～"
            $0.font = UIFont.systemFont(ofSize: 16)
            $0.textColor = .gray
            $0.textAlignment = .center
            $0.sizeToFit()
        })

        view.addSubview(label)

        label.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-50)
        }

        tableView.separatorStyle = .none
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        data = FileService.getFiles() ?? []
        label.isHidden = data.count > 0
        tableView.isHidden = !label.isHidden
        tableView.reloadData()
    }
}

extension FilesViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        data.remove(at: indexPath.row)
        FileService.save(files: data)
        tableView.reloadData()
        label.isHidden = data.count > 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "删除"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = (tableView.dequeueReusableCell(withIdentifier: "fileListCell", for: indexPath) as? FileListCell)!
        let dic = data[indexPath.row]
        cell.titleLabel.text = dic["title"]
        cell.timeLabel.text = dic["time"]
        return cell
    }
}

extension FilesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc1 = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FileDetailViewController") as! FileDetailViewController
        vc1.content = data[indexPath.row]["content"]
        vc1.index = indexPath.row
        navigationController?.pushViewController(vc1, animated: true)
    }
}
