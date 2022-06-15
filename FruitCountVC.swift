//
//  FruitCountVC.swift
//  GheeWhiz
//
//  Created by Minni on 13/01/20.
//  Copyright © 2020 Minni. All rights reserved.
//

import UIKit
import SideMenu
import Alamofire
import CoreData

class FruitCountVC: UIViewController {
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var fruitCountLabel: UILabel!
    @IBOutlet weak var filterView: UIView!
    @IBOutlet weak var filterLabel: UILabel!
    @IBOutlet weak var myCountLabel: UILabel!
    @IBOutlet weak var todayLabel: UILabel!
    @IBOutlet weak var myCountSwitch: UISwitch!
    @IBOutlet weak var todaySwitch: UISwitch!
    @IBOutlet weak var fruitCountTableView: UITableView!
    var fruitCountModel : A_AllCountModel?
    var saveFruitCountModel : A_AllCountModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDefaultUI()
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        
        if Utils.Is_Internet_Connection_Available(){
            checkIfFruitCountDataIsSynced()
        } else {
            getFruitCountFromDB()
        }
    }
    func setDefaultUI() {
        
        if self.view != nil {
      
        headerView.addShadow()
        filterView.addShadow()
        
        fruitCountLabel.text = NSLocalizedString("Fruit_Count", comment: "")
        fruitCountLabel.textColor = UIColor(named: "ButtonGreen")
        fruitCountLabel.font = UIFont(name: Constants.APPFONT, size: 18.0)
        
        filterLabel.text = NSLocalizedString("Filters", comment: "")
        filterLabel.textColor = UIColor(named: "BlackColor")
        filterLabel.font = UIFont(name: Constants.APPFONT, size: 12.0)
        
        myCountLabel.text = NSLocalizedString("MyCount", comment: "")
        myCountLabel.textColor = UIColor(named: "BlackColor")
        myCountLabel.font = UIFont(name: Constants.APPFONT, size: 13.0)
        
        todayLabel.text = NSLocalizedString("Today", comment: "")
        todayLabel.textColor = UIColor(named: "BlackColor")
        todayLabel.font = UIFont(name: Constants.APPFONT, size: 13.0)
        
        fruitCountTableView.delegate = self
        fruitCountTableView.dataSource = self
        
        myCountSwitch.isOn = true
        todaySwitch.isOn = true
        myCountSwitch.addTarget(self, action: #selector(myCountSwitchChanged), for: UIControl.Event.valueChanged)
        todaySwitch.addTarget(self, action: #selector(todaySwitchChanged), for: UIControl.Event.valueChanged)
        }
        
    }
    // MARK: - Methods
    func filterResultByDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let nowString = formatter.string(from: Date())
        let filteredItems = self.fruitCountModel?.allFruitList?.filter{ item in return
            Utility.sharedInstance().convertDateFormaterForFilter(date: item.createdDate ?? "") == nowString }
        self.fruitCountModel?.allFruitList = filteredItems
        self.fruitCountTableView.reloadData()
        
    }
    func filterResultAddingByMe() {
        let filteredItems = self.fruitCountModel?.allFruitList?.filter{ item in return item.employeeName == Utils.regUser?.user?.employeeName }
        self.fruitCountModel?.allFruitList = filteredItems
        self.fruitCountTableView.reloadData()
        
    }
    func loadDataInTableView() {
        if self.todaySwitch.isOn && self.myCountSwitch.isOn{
            self.filterResultAddingByMe()
            self.filterResultByDate()
        }
        else if self.todaySwitch.isOn {
            self.filterResultByDate()
        }
        else if self.myCountSwitch.isOn {
            self.filterResultAddingByMe()
        }
        self.fruitCountTableView.reloadData()
    }
    func getFruitCountList() {
        
        let headers = [
            "Content-Type": "application/json",
            "Cache-Control": "no-cache",
            "Authorization": "Bearer " + ObjcKeys.accessToken
        ]
        
        let url =  ObjcKeys.baseURL + "Orchard/getAllAppleCount"
        
        WebServiceHelper.callWebService(WSUrl: url, WSMethod: .get, WSParams: [:], WSHeader: headers, isLoader: true) { (iData, iError) in
            
            if let _ = iData as? String {
                
                
            }  else {
                if let error = iError {
                    print("aErrorObj===\(error.description)")
                    print("no data found")
                    
                }  else {
                    
                    if  let iDictResponse = iData as? NSDictionary {
                        print("fruitcount response is ===", iDictResponse)
                        if (iDictResponse.object(forKey: "statusCode") as! Int == 200) {
                            
                            self.fruitCountModel = A_AllCountModel.init(object: iDictResponse)
                            self.saveFruitCountModel = A_AllCountModel.init(object: iDictResponse)
                            self.syncFruitCountList()
                            if let FirstSync = UserDefaults.standard.string(forKey: "FirstSync") {
                                print(FirstSync)
                                if (FirstSync == "") {
                                    self.syncFruitCountNotesList()
                                }
                            } else {
                                self.syncFruitCountNotesList()
                            }
                            if (self.fruitCountTableView != nil) {
                                self.loadDataInTableView()
                            }
                        }
                        else {
                            Utility.sharedInstance().showAlert(msg: Constants.APPNAME, viewController: (Constants.APPDELEGATE.window?.rootViewController)!, titleMessage: iDictResponse.object(forKey: "message") as! String)
                        }
                    }
                    else {
                        
                    }
                }
            }
        }
        
    }
    // MARK: - IBAction Methods
    @objc func todaySwitchChanged(todaySwitch: UISwitch) {
        if todaySwitch.isOn {
            self.fruitCountModel?.allFruitList = self.saveFruitCountModel?.allFruitList
            self.filterResultByDate()
            if myCountSwitch.isOn {
                self.filterResultAddingByMe()
            }
        }
        else {
            print ("OFF")
            if myCountSwitch.isOn {
                self.fruitCountModel?.allFruitList = self.saveFruitCountModel?.allFruitList
                self.filterResultAddingByMe()
            } else {
                if Utils.Is_Internet_Connection_Available(){
                    getFruitCountList()
                } else {
                    getFruitCountFromDB()
                }
            }
        }
        
    }
    @objc func myCountSwitchChanged(myCountSwitch: UISwitch) {
        if myCountSwitch.isOn {
            print("ON")
            self.fruitCountModel?.allFruitList = self.saveFruitCountModel?.allFruitList
            self.filterResultAddingByMe()
            if todaySwitch.isOn {
                self.filterResultByDate()
            }
        }
        else {
            print ("OFF")
            if todaySwitch.isOn {
                self.fruitCountModel?.allFruitList = self.saveFruitCountModel?.allFruitList
                self.filterResultByDate()
            } else {
                if Utils.Is_Internet_Connection_Available(){
                    getFruitCountList()
                } else {
                    
                    getFruitCountFromDB()
                }
                
            }
        }
    }
    @IBAction func addButtonAction(_ sender: UIButton) {
        let scanOrCodeVC = Constants.STORYBOARD.instantiateViewController(withIdentifier: "ScanOrCodeVC") as! ScanOrCodeVC
        scanOrCodeVC.screenName = "FruitCountVC"
        self.navigationController?.pushViewController(scanOrCodeVC, animated: true)
    }
    // MARK: - Core Database Methods
    func getFruitCountFromDB(){
        let fruitCountArray : NSMutableArray = CoreDataBaseHelper.getFruitCountFromDatabase()
        let dic1 : [String:Any] = ["data": fruitCountArray as Any]
        self.fruitCountModel = A_AllCountModel.init(object: dic1)
        self.saveFruitCountModel = A_AllCountModel.init(object: dic1)
        if (self.fruitCountTableView != nil) {
            self.loadDataInTableView()
        }
    }
    func checkIfFruitCountDataIsSynced() {
        let listOfItems = CoreDataBaseHelper.getListOfUnsyncedData(entityNameStr: "FruitCount")
        if listOfItems.count>0{
            let  fruitCount = listOfItems as! [FruitCount]
            for fruititem in fruitCount {
                if (fruititem.appleCountSyncID == "") {
                    syncSaveApiCall(fruit: fruititem, Update: false)
                } else {
                    if fruititem.isUpdate == true {
                        syncSaveApiCall(fruit: fruititem, Update: true)
                    }
                }
            }
        }
        getFruitCountList()
    }
    func syncSaveApiCall(fruit: FruitCount, Update: Bool) {
        
        let headers = [
            "Content-type": "application/json",
            "cache-control": "no-cache",
            "Authorization": "Bearer " + ObjcKeys.accessToken
        ]
        var url:String = ""
        var parameters = [String : Any]()
        var method: HTTPMethod
        if Update == true {
            
            parameters = [
                "AppleCountID":fruit.appleCountID,
                "CropYear": fruit.cropYear,
                "TreeID":fruit.treeID,
                "AppleCount":fruit.appleCount,
                "Clump":fruit.clump,
                ] as [String : Any]
            url =  ObjcKeys.baseURL + "Orchard/updateAppleCount"
            method = .put
            
        } else {
            parameters = [
                "AppleCountID":0,
                "CropYear": fruit.cropYear,
                "TreeID":fruit.treeID,
                "AppleCount":fruit.appleCount,
                "Clump":fruit.clump,
                ] as [String : Any]
            
            url =  ObjcKeys.baseURL + "Orchard/saveAppleCount"
            method = .post
        }
        WebServiceHelper.callWebService(WSUrl: url, WSMethod: method, WSParams: parameters, WSHeader: headers, isLoader: true) { (iData, iError) in
            if let _ = iData as? String {
                
            } else {
                if let error = iError {
                    print("aErrorObj===\(error.description)")
                    print("no data found")
                    
                } else {
                    
                    if  let iDictResponse = iData as? NSDictionary {
                        print("save Api response is ===", iDictResponse)
                        if (iDictResponse.object(forKey: "statusCode") as! Int == 200) {
                            if Update == true {
                                CoreDataBaseHelper.isUpdatedWithDict(entityNameStr: "FruitCount", keyID: "appleCountID", keyIDValue: Int(fruit.appleCountID))
                            } else {
                                let dictArray = iDictResponse.object(forKey: "data") as! NSArray
                                if (dictArray.count>0) {
                                    let dict = dictArray[0] as! NSDictionary
                                    fruit.appleCountID = Int16(dict.object(forKey: "appleCountID") as! Int)
                                    fruit.appleCountSyncID = dict.object(forKey: "appleCountSyncID") as? String
                                    CoreDataBaseHelper.updateFruitCountDataWithDict(dict: dict, appleCountID: Int(fruit.appleCountID))
                                }
                            }
                            
                        }
                    }
                }
            }
        }
    }
    func syncFruitCountList() {
        
        let context = Constants.APPDELEGATE.persistentContainer.viewContext
        if  self.fruitCountModel?.allFruitList?.count != 0 {
            for result in self.fruitCountModel?.allFruitList ?? [] {
                // Save local Database
                let entity = NSEntityDescription.entity(forEntityName: "FruitCount", in: context)
                let fruitCount = NSManagedObject(entity: entity!, insertInto: context)
               
                let queryString = String(format:"appleCountID = %d", result.appleCountID ?? 0)
                if (result.appleCountID != 0) {
                    if CoreDataBaseHelper.someEntityExists(queryStr: queryString, entityNameStr: "FruitCount") {
                        
                    } else {
                        fruitCount.setValue(result.appleCount, forKey: "appleCount")
                        fruitCount.setValue(result.appleCountSyncID, forKey: "appleCountSyncID")
                        fruitCount.setValue(result.appleCountID, forKey: "appleCountID")
                        fruitCount.setValue(result.blockID, forKey: "blockID")
                        fruitCount.setValue(result.clump, forKey: "clump")
                        fruitCount.setValue(result.cropYear, forKey: "cropYear")
                        fruitCount.setValue(result.employeeName, forKey: "employeeName")
                        fruitCount.setValue(result.photoURL, forKey: "photoURL")
                        fruitCount.setValue(result.row, forKey: "row")
                        fruitCount.setValue(result.treeID, forKey: "treeID")
                        fruitCount.setValue(result.createdDate, forKey: "createdDate")
                        fruitCount.setValue(false, forKey: "isUpdate")
                        do {
                            try context.save()
                            
                        } catch {
                            print("Failed saving")
                        }
                    }
                }
            }
            
        }
        
    }
    func syncFruitCountNotesList() {
        if  self.fruitCountModel?.allFruitList?.count != 0 {
            for result in self.fruitCountModel?.allFruitList ?? [] {
                CoreDataBaseHelper.syncNotesListFromApi(hostTableId: result.appleCountID ?? 0, hostTableName: "AppleCount")
            }
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
        
}
extension FruitCountVC : UITableViewDelegate,UITableViewDataSource
{
    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return  self.fruitCountModel?.allFruitList?.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var iCell: FruitCountCell! = tableView.dequeueReusableCell(withIdentifier: Constants.TBLCELL_FruitCountCell, for: indexPath) as? FruitCountCell
        if (iCell == nil) {
            iCell = FruitCountCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: Constants.TBLCELL_FruitCountCell)
        }
        //        let iCell : FruitCountCell = tableView.dequeueReusableCell(withIdentifier: Constants.TBLCELL_FruitCountCell, for: indexPath) as! FruitCountCell
        
        iCell.selectionStyle = .none
        
        iCell.blockLbl.text = NSLocalizedString("Block", comment: "")
        iCell.blockLbl.textColor = UIColor(named: "darkGreyColor")
        iCell.blockLbl.font = UIFont(name: Constants.APPFONT, size: 13.0)
        
        iCell.rowLbl.text = NSLocalizedString("Row", comment: "")
        iCell.rowLbl.textColor = UIColor(named: "darkGreyColor")
        iCell.rowLbl.font = UIFont(name: Constants.APPFONT, size: 13.0)
        
        iCell.treeLbl.text = NSLocalizedString("TreeID", comment: "")
        iCell.treeLbl.textColor = UIColor(named: "darkGreyColor")
        iCell.treeLbl.font = UIFont(name: Constants.APPFONT, size: 13.0)
        
        iCell.blockLblValue.text = self.fruitCountModel?.allFruitList![indexPath.row].blockID
        iCell.blockLblValue.textColor = UIColor(named: "BlackColor")
        iCell.blockLblValue.font = UIFont(name: Constants.APPFONT, size: 13.0)
        
        iCell.rowLblValue.text = self.fruitCountModel?.allFruitList![indexPath.row].row
        iCell.rowLblValue.textColor = UIColor(named: "BlackColor")
        iCell.rowLblValue.font = UIFont(name: Constants.APPFONT, size: 13.0)
        
        iCell.treeLblValue.text = String(format: "%ld", self.fruitCountModel?.allFruitList![indexPath.row].treeID ?? 0)
        iCell.treeLblValue.textColor = UIColor(named: "BlackColor")
        iCell.treeLblValue.font = UIFont(name: Constants.APPFONT, size: 13.0)
        
        iCell.usernameLbl.text = self.fruitCountModel?.allFruitList![indexPath.row].employeeName?.capitalized
        iCell.usernameLbl.textColor = UIColor(named: "RedColor")
        iCell.usernameLbl.font = UIFont(name: Constants.APPFONT, size: 14.0)
        
        iCell.fruitCountLbl.text = String(format: "%ld", self.fruitCountModel?.allFruitList![indexPath.row].appleCount ?? 0)
        iCell.fruitCountLbl.textColor = UIColor(named: "ButtonGreen")
        iCell.fruitCountLbl.font = UIFont(name: Constants.APPFONT_BOLD, size: 16.0)
        
        iCell.userImageView.image = UIImage(named: "User_Icon")
        iCell.userImageView.circledButton()
        let icon = self.fruitCountModel?.allFruitList![indexPath.row].photoURL ?? ""
        Alamofire.request(icon).responseData { (response) in
            if response.error == nil {
                // Show the downloaded image
                if let data = response.data {
                    let image = UIImage(data: data)
                    let resizeImage = Utility.sharedInstance().resizeImage(image: image!, targetSize: CGSize(width: 55.0, height: 55.0))
                    iCell.userImageView.image = resizeImage
                    
                }
            }
        }
        return iCell
    }
    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return  102
        
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let fruitCountEntryVC = Constants.STORYBOARD.instantiateViewController(withIdentifier: "FruitCountEntryVC") as! FruitCountEntryVC
        fruitCountEntryVC.allFruitCount = self.fruitCountModel?.allFruitList![indexPath.row]
        fruitCountEntryVC.isUpdate = true
        self.navigationController?.pushViewController(fruitCountEntryVC, animated: true)
        
    }
    
}

/*
 // MARK: - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
 // Get the new view controller using segue.destination.
 // Pass the selected object to the new view controller.
 }
 */


