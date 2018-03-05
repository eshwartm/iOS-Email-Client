//
//  EmailDetailViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/27/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class EmailDetailViewController: UITableViewController{
    var emailData = EmailDetailData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailData.mockEmails()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 98
        
        for index in 0...emailData.emails.count - 1{
            let nib = UINib(nibName: "EmailDetailTableCell", bundle: nil)
            tableView.register(nib, forCellReuseIdentifier: "emailDetail\(index)")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "emailDetail\(indexPath.row)") as! EmailTableViewCell
        let email = emailData.emails[indexPath.row]
        cell.setContent(email.preview, email.content, isExpanded: email.isExpanded)
        cell.myHeight = email.myHeight
        cell.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emailData.emails.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableCell(withIdentifier: "emailTableHeaderView")
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableCell(withIdentifier: "emailTableFooterView")
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat(78)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(56)
    }
}

extension EmailDetailViewController: EmailTableViewCellDelegate{
    func tableViewCellDidLoadContent(_ cell: EmailTableViewCell, _ height: Int) {
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        let email = emailData.emails[indexPath.row]
        email.myHeight = height
        tableView.reloadData()
    }
    
    func tableViewCellDidTap(_ cell: EmailTableViewCell) {
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        let email = emailData.emails[indexPath.row]
        email.isExpanded = !email.isExpanded
        email.myHeight = 0
        cell.toggleCell(email.isExpanded)
        if(!email.isExpanded){
            tableView.reloadData()
        }
    }
}
