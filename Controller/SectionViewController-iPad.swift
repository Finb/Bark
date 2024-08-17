//
//  SectionTableViewController-iPad.swift
//  Bark
//
//  Created by sidguan on 2024/6/23.
//  Copyright © 2024 Fin. All rights reserved.
//

import UIKit

import NSObject_Rx
import RxCocoa
import RxDataSources
import RxSwift

class SectionViewController_iPad: BaseViewController<SectionViewModel>, UITableViewDelegate {
    
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "\(UITableViewCell.self)")
        tableView.backgroundColor = BKColor.background.primary
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Bark"
        navigationItem.largeTitleDisplayMode = .automatic
    }
    
    override func makeUI() {
        self.view.addSubview(tableView)
        tableView.delegate = self
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func bindViewModel() {
        let output = viewModel.transform(input: SectionViewModel.Input())
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, SectionItem>> {
            _, tableView, _, item -> UITableViewCell in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(UITableViewCell.self)") else {
                return UITableViewCell()
            }
            
            if #available(iOS 14, *) {
                cell.backgroundConfiguration = UIBackgroundConfiguration.listPlainCell()
            }
            cell.selectionStyle = .gray
            cell.imageView?.image = item.image
            cell.imageView?.tintColor = BKColor.grey.darken4
            cell.textLabel?.text = item.title
            return cell
        }
        tableView.rx
            .itemSelected
            .flatMapLatest { indexPath -> Observable<IndexPath> in
                return Observable.just(indexPath)
            }
            .subscribe { indexPath in
                if #available(iOS 14, *) {
                    if indexPath.row == 0 {
                        self.splitViewController?.setViewController(
                            BarkNavigationController(rootViewController: HomeViewController(viewModel: HomeViewModel())), for: .secondary)
                    } else if indexPath.row == 1 {
                        self.splitViewController?.setViewController(
                            BarkNavigationController(rootViewController: MessageListViewController(viewModel: MessageListViewModel())), for: .secondary)
                    } else if (indexPath.row == 2) {
                        
                        self.splitViewController?.setViewController(
                            BarkNavigationController(rootViewController: MessageSettingsViewController(viewModel: MessageSettingsViewModel())), for: .secondary)
                    }
                } else {
                    // 正常应该走不到这里了
                }
                
            }.disposed(by: rx.disposeBag)
        output.items
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
    }

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
