//
//  HomeListViewController.swift
//  StackdVersion1
//
//  Created by Sky Xu on 4/2/18.
//  Copyright © 2018 Sky Xu. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import MediaPlayer
import CoreData
import Kingfisher

class HomeListViewController: UIViewController, OpenedViewDelegate {
    
    @IBOutlet weak var backFromPopupView: UIView!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var archiveBtn: UIButton!
    @IBOutlet weak var centerX: NSLayoutConstraint!
    @IBOutlet weak var popupComeFrom: UILabel!
    @IBOutlet weak var popupSource: UILabel!
    var initialIndexPath: IndexPath? = nil
    
    var selectedIndex: IndexPath?
    let coreDataStack = CoreDataStack.instance
    var selected: AllItem!
    var allItems: [AllItem]? {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let longpress = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognized(_:)))
        tableView.addGestureRecognizer(longpress)
        centerX.constant = -1000
        self.tableView.dragInteractionEnabled = true
        
        self.navigationController?.navigationBar.isHidden = true
        self.tableView.sectionHeaderHeight = 150
        
        let nibCell = UINib(nibName: "SharedTableViewCell", bundle: Bundle.main)
        tableView.register(nibCell, forCellReuseIdentifier: "regularcell")
        
        let nibCell2 = UINib(nibName: "YoutubeTableViewCell", bundle: Bundle.main)
        tableView.register(nibCell2, forCellReuseIdentifier: "youtubecell")
        
        backFromPopupView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissXis)))
//        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissXis)))

        deleteBtn.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        archiveBtn.addTarget(self, action: #selector(archiveTapped), for: .touchUpInside)
        
        self.allItems = fetchAll(AllItem.self, route: .allItem)
    }
    
   @objc func longPressGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        let longPress = gestureRecognizer as! UILongPressGestureRecognizer
        let state = longPress.state
        var locationInView = longPress.location(in: tableView)
//        this is the indexpath of the start of drag
        var indexPath = tableView.indexPathForRow(at: locationInView)
        
        switch state{
        case UIGestureRecognizerState.began:
            if indexPath != nil {
                self.initialIndexPath = indexPath
                
            }
        case UIGestureRecognizerState.changed:
            break
        case .ended:
            if ((indexPath != nil) && (indexPath != self.initialIndexPath)) {
//                print(indexPath!, initialIndexPath!)
                let movedObject = self.allItems![initialIndexPath!.row]
                let beMovedObject = self.allItems![indexPath!.row]
                self.allItems?.remove(at: initialIndexPath!.row)
                self.allItems?.insert(movedObject, at: indexPath!.row)
                movedObject.rearrangedRow = Int64(indexPath!.row)
                beMovedObject.rearrangedRow = Int64(indexPath!.row)
                self.coreDataStack.saveTo(context: self.coreDataStack.privateContext)
            }
        case .cancelled:
            break
        case .failed:
            break
        case .possible:
            break
        }
        
    }
    
    
    
    func changeXis() {
        centerX.constant = 0
    }
    
    @objc func dismissXis() {
        self.centerX.constant = 1000
    }
    
    //    delete from coredata
    @objc func deleteTapped() {
        centerX.constant = -1000
        if let index = self.selectedIndex {
            self.allItems?.remove(at: index.row)
            tableView.deleteRows(at: [index], with: .automatic)
        }
        
        self.coreDataStack.privateContext.delete(self.selected)
        self.coreDataStack.saveTo(context: self.coreDataStack.privateContext)
        configureDeletedModal()
    }
    
    //    set selected item's coredata archive to be true
    @objc func archiveTapped() {
        centerX.constant = 1000
        self.selected?.setValue(true, forKey: "archived")
        self.coreDataStack.saveTo(context: self.coreDataStack.privateContext)
        self.configureArchivedModal()
        if let index = self.selectedIndex {
            self.allItems?.remove(at: index.row)
            tableView.deleteRows(at: [index], with: .automatic)
        }
    }
    
    func configureArchivedModal() {
        guard let successView = Bundle.main.loadNibNamed("FadingAlertView", owner: self, options: nil)![0] as? FadingAlertView else { return }
        successView.configureView(title: "Saved to Stacked", at: self.view.center)
        self.view.addSubview(successView)
        successView.hide()
    }
    
    func configureDeletedModal() {
        guard let successView = Bundle.main.loadNibNamed("FadingAlertView", owner: self, options: nil)![0] as? FadingAlertView else { return }
        successView.configureView(title: "Deleted", at: self.view.center)
        self.view.addSubview(successView)
        successView.hide()
    }
}

extension HomeListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let items = self.allItems {
            return items.count
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {

        return true
    }
 
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let rowHeight = CGFloat(120)
        return rowHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) ->
        UITableViewCell {
//        cell.delegate = self
        var genericCell: UITableViewCell?
        let item = self.allItems![indexPath.row]
        let type = item.cellType!
        self.selectedIndex = indexPath
        switch type {
        case "podcast":
            if let cell = tableView.dequeueReusableCell(withIdentifier: "regularcell", for: indexPath) as? SharedTableViewCell {
                genericCell = cell
                cell.duration.text = item.duration
                cell.sourceLabel.text = "apple.itunes.com"
                let img = UIImage(named: "listen_small")
                cell.sourceLogo.image = img
                cell.sourceTitle.text = item.title
                
            }
        case "safari":
            if let cell = tableView.dequeueReusableCell(withIdentifier: "regularcell", for: indexPath) as? SharedTableViewCell {
                genericCell = cell
                let duration = item.duration?.formatDurationForArticle()
                cell.duration.text = duration
                cell.sourceLabel.text = item.urlStr?.getSafariSource()
                let img = UIImage(named: "read_small")
                cell.sourceLogo.image = img
                cell.sourceTitle.text = item.title
            }
        case "youtube":
            if let cell = tableView.dequeueReusableCell(withIdentifier: "youtubecell", for: indexPath) as? YoutubeTableViewCell {
                genericCell = cell
                cell.duration.text = item.duration
                cell.sourceLabel.text = "www.youtube.com"
                cell.sourceImg.kf.indicatorType = .activity
                let url = URL(string: item.videoThumbnail!)
                cell.sourceImg.kf.setImage(with: url, options: [.cacheSerializer(FormatIndicatedCacheSerializer.jpeg), .cacheSerializer(FormatIndicatedCacheSerializer.png)])
                let img = UIImage(named: "watch_small")
                cell.sourceLogo.image = img
                cell.sourceTitle.text = item.title
            }
        default:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "regularcell", for: indexPath) as? SharedTableViewCell {
               genericCell = cell
            }
        }
       
        return genericCell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selected = self.allItems![indexPath.row]
        let url = selected.urlStr!
        let selectedType = selected.cellType!
        self.selectedIndex = indexPath
        switch selectedType {
        case "podcast":
            self.popupSource.text = selected.urlStr?.getSafariSource()
            self.popupComeFrom.text = selected.title
            PrepareForPresentingViews.shared.redirectToPodcast(url)
        case "youtube":
            self.popupSource.text = selected.urlStr?.getSafariSource()
            self.popupComeFrom.text = selected.title
            PrepareForPresentingViews.shared.openInApp(url, viewController: self, navigationController: self.navigationController)
        case "safari":
            self.popupSource.text = selected.urlStr?.getSafariSource()
            self.popupComeFrom.text = selected.title
            PrepareForPresentingViews.shared.openInApp(url, viewController: self, navigationController: self.navigationController)
        default:
            print("exception in didselect")
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 150)
        let customizedHeaderView = CustomHeaderView(frame: frame)
        customizedHeaderView.customedHeaderDelegate = self
        
        return customizedHeaderView
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let tagAction = self.toogleTag(forRowAtIndexPath: indexPath)
        let deleteAction = self.toogleDelete(forRowAtIndexPath: indexPath)
        let topAction = self.toogleTop(forRowAtIndexPath: indexPath)
        let bottomAction = self.toogleBottom(forRowAtIndexPath: indexPath)
        let swipeConfig = UISwipeActionsConfiguration(actions: [deleteAction, tagAction, bottomAction, topAction])
        swipeConfig.performsFirstActionWithFullSwipe = false
        return swipeConfig
    }
    
    func toogleTag(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "Tag") { (action, view, completionHandler: (Bool) -> Void) in
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            let tagVC = storyboard.instantiateViewController(withIdentifier: "tagVC") as! TagsViewController
            tagVC.selected = self.allItems?[indexPath.row]
            self.navigationController?.pushViewController(tagVC, animated: false)
//            (tagVC, animated: false, completion: nil)
            completionHandler(true)
        }
        
        action.image = #imageLiteral(resourceName: "tag")
        action.backgroundColor = .lightGray
        return action
    }
    
    func toogleDelete(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .destructive, title: "Delete") { [unowned self] (action, view, completionHandler: (Bool) -> Void) in
                let removeItem = self.allItems![indexPath.row]
                self.allItems?.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                self.coreDataStack.privateContext.delete(removeItem)
                self.coreDataStack.saveTo(context: self.coreDataStack.privateContext)

                completionHandler(true)
        }
        action.image = #imageLiteral(resourceName: "popup_delete")
        action.backgroundColor = .lightGray
        return action
    }

    func toogleTop(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "Top") { [unowned self] (action, view, completionHandler: (Bool) -> Void) in
            let movedObject = self.allItems![indexPath.row]
            let beMovedObject = self.allItems![0]
            self.allItems?.remove(at: indexPath.row)
            self.allItems?.insert(movedObject, at: 0)
            movedObject.rearrangedRow = Int64(0)
            beMovedObject.rearrangedRow = Int64(indexPath.row)
            self.coreDataStack.saveTo(context: self.coreDataStack.privateContext)
            
            completionHandler(true)
        }
        
        action.image = #imageLiteral(resourceName: "top")
        action.backgroundColor = .lightGray
        return action
    }

    func toogleBottom(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "Bottom") { [unowned self] (action, view, completionHandler: (Bool) -> Void) in
            let movedObject = self.allItems![indexPath.row]
            let bottomIndex = (self.allItems?.count)! - 1
            let beMovedObject = self.allItems![bottomIndex]
            self.allItems?.remove(at: indexPath.row)
            self.allItems?.insert(movedObject, at: bottomIndex)
            movedObject.rearrangedRow = Int64(bottomIndex)
            beMovedObject.rearrangedRow = Int64(indexPath.row)
            self.coreDataStack.saveTo(context: self.coreDataStack.privateContext)
            
            completionHandler(true)
        }
        action.image = #imageLiteral(resourceName: "bottom")
        action.backgroundColor = .lightGray
        return action
    }
}

extension HomeListViewController: HeaderActionDelegate {
    func filterTapped() {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "filterVC") as! FilterViewController
       self.navigationController?.pushViewController(vc, animated: true)
    }
}
