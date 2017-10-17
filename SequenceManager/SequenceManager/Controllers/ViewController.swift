//
//  ViewController.swift
//  SequenceManager
//
//  Created by Hu on 2017/8/22.
//  Copyright © 2017年 xx. All rights reserved.
//

import Cocoa
import SWXMLHash

//沙盘资源

let ROOTMODULE_RESOURCE_PATH = Bundle.main.bundlePath + "/Contents/Resources/ModuleTemplate/Sand/RootModule"

let SUBMODULE_RESOURCE_PATH = Bundle.main.bundlePath + "/Contents/Resources/ModuleTemplate/Sand/SubModule"

let CONNECTMODULE_RESOURCE_PATH = Bundle.main.bundlePath + "/Contents/Resources/ModuleTemplate/Sand/ConnectModule"

let ICONMODULE_RESOURCE_PATH = Bundle.main.bundlePath + "/Contents/Resources/ModuleTemplate/Sand/IconModule"

let BACKBUTTON_RESOURCE_PATH = Bundle.main.bundlePath + "/Contents/Resources/ModuleTemplate/Sand/BackButton"

//区位资源

let TRAFFIC_RESOURCE_PATH = Bundle.main.bundlePath + "/Contents/Resources/ModuleTemplate/Traffic/TrafficModule"

let TRAFFICROOT_RESOURCE_PATH = Bundle.main.bundlePath + "/Contents/Resources/ModuleTemplate/Traffic/RootModule"

let TRAFFICSUB_RESOURCE_PATH = Bundle.main.bundlePath + "/Contents/Resources/ModuleTemplate/Traffic/SubModule"

let TRAFFICROOTFOLDER_RESOURCE_PATH = Bundle.main.bundlePath + "/Contents/Resources/ModuleTemplate/Traffic/Folder/Root"

let TRAFFICSUBFOLDER_RESOURCE_PATH = Bundle.main.bundlePath + "/Contents/Resources/ModuleTemplate/Traffic/Folder/Sub"

class ViewController: NSViewController,NSWindowDelegate,NSApplicationDelegate{
    
    let mainWindow = NSWindowController()
    
    var i = 0
    
    @IBOutlet weak var textField: NSTextField!
    
    let moduleFileManager = ModuleFileManger.shareInstance
    
    let xmlTool = XMLParserTool()
    
    
    var dataSource:[SequenceModule] = {
        
        return []
    }()
    
    @IBOutlet weak var moduleListOutlineView: NSOutlineView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.moduleListOutlineView.expandItem(nil, expandChildren: true)
        
        let menu = NSMenu()
        menu.delegate = self
        self.moduleListOutlineView.menu = menu
        
        //关闭按钮直接退出程序
        NSApp.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(closeWindow), name: .NSWindowWillClose, object: mainWindow)
        
        //关闭窗口,不退出程序
        
    }
    
    func closeWindow(){
    
        NSApp.terminate(self)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        
        return true
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func openSavePanel() -> NSSavePanel{
        
        let panel = NSSavePanel()
        
        panel.directoryURL = NSURL(string: moduleFileManager.getDesktopPath()) as URL?
        
        panel.allowsOtherFileTypes = true
        
        panel.canCreateDirectories = true
        
        return panel
    
    }
    @IBAction func clearDataSource(_ sender: NSButton) {
        
        self.dataSource.removeAll()
        self.moduleListOutlineView.reloadData()
    }
    ///添加模块
    @IBAction func addSubModule(_ sender: NSButton) {
        
        i = 0
        
        if self.textField.stringValue.isEmpty {
            return
        }
        
        let module = SequenceModule(self.textField.stringValue)
        
        module.isLeaf = true
        
        guard self.dataSource.count != 0 else {
            
            self.dataSource.append(module)
            
            self.moduleListOutlineView.reloadData()
            
            return
        }
        
        
        guard let selectModuleItem = self.moduleListOutlineView.item(atRow: self.moduleListOutlineView.selectedRow) as? SequenceModule else {
            
            self.dataSource.append(module)
            
            self.moduleListOutlineView.reloadData()
            
            return
        }
        
        selectModuleItem.isLeaf = false
        
        selectModuleItem.leafModules.append(module)
        
        module.parentModule = selectModuleItem
        
        self.moduleListOutlineView.reloadData()
        
        
    }
    
    //生成沙盘文件夹
    @IBAction func saveModule(_ sender: Any) {
        
        let panel = self.openSavePanel()
        
        panel.begin { (result) in
            
            if result == NSFileHandlingPanelOKButton {
                
                let path = panel.url!.path
                
                self.moduleFileManager.createDirectory(path)
                
                self.moduleFileManager.copyFile(from: ROOTMODULE_RESOURCE_PATH, to: path + "/模块")
                
                self.createSandModule(sourceArray: self.dataSource, savePath: path, parentModule: nil)
                
            }
        }
        
    }
    
    //创建沙盘模块
    private func createSandModule(sourceArray array:Array<SequenceModule>, savePath path:String, parentModule sequenceModuel:SequenceModule?) ->Void{
        
        let modulePath = path + "/模块/subs/模块"
        
        let sequenceFilePath = path + "/序列帧/沙盘/"
        
        guard array.count != 0 else {
            
            return
        }
        
        
        
        for item in array {
            
            //模块路径
            item.modulePath = modulePath + "/\(String(format:"%.2d",i))B.\(item.moduleID)"
            
            //创建沙盘场景模块
            
            self.createModuleAndAddID(from: SUBMODULE_RESOURCE_PATH, to: item.modulePath, AndItemID: item.moduleID)
            
            self.moduleFileManager.createDirectory(sequenceFilePath + "\(item.moduleID)")
            
            self.xmlTool.changeXMLRootElementProperty(targetXMLPath: item.modulePath + "/datafile.xml", addProperty: "序列帧/沙盘/" + item.moduleID)
            
            if let parentModuel = sequenceModuel {
                
                //衔接文件名
                let fileName = "\(parentModuel.moduleID)" + "到" + "\(item.moduleID)"
                
                //添加衔接点
                
                self.createModuleAndAddName(from: ICONMODULE_RESOURCE_PATH, to: parentModuel.modulePath + "/subs/模块/01/00.\(item.moduleID)", AndItemName: item.moduleID)
                
                //创建衔接模块
                
                self.createModuleAndAddID(from: CONNECTMODULE_RESOURCE_PATH, to: modulePath + "/\(String(format:"%.2d",i))A.\(fileName)", AndItemID: fileName)
                
//                self.xmlTool.changeXMLRootElementProperty(targetXMLPath: modulePath + "/\(String(format:"%.2d",i))A.\(fileName)/datafile.xml", addProperty: "序列帧/沙盘/" + fileName)
                let transSequencePath = "序列帧/沙盘/" + fileName
                
                
                let transXMLString = "<root sequenceFile='\(transSequencePath.encode!)' fps='50' decelerationRate='0.010000' loopHorizontal='NO' changeOffset='{8, 0}' maximumZoomScale='1.500000' hotspotDirectory='hotspots' compassDataFile='compass/compassdatafile.xml' loopVertical='NO' minimumZoomScale='1.000000'>\n <gate entranceFrame='0' moduleID='\(parentModuel.moduleID.encode!)' direction='1' preloaded='0' allowNavigation='YES'>\n </gate>\n <gate entranceFrame='-1' moduleID='\(item.moduleID.encode!)' direction='4' preloaded='0' allowNavigation='YES'>\n </gate>\n </root>"
                
                self.xmlTool.createXMLFile(xmlString: transXMLString, savePath: modulePath + "/\(String(format:"%.2d",i))A.\(fileName)/datafile.xml")
                
                //创建衔接序列帧路径
                self.moduleFileManager.createDirectory(sequenceFilePath + "\(fileName)")
                
                //添加返回按钮
                self.createModuleAndAddName(from: BACKBUTTON_RESOURCE_PATH, to: item.modulePath + "/subs/装饰/返回", AndItemName: parentModuel.moduleID)
                
            }
            
            
            i = i + 1
            
            if !item.isLeaf {
                
                self.createSandModule(sourceArray: item.leafModules, savePath: path, parentModule: item)
            }
            
        }
        
    }
    //生成区位文件夹
    
    @IBAction func saveTrafficModule(_ sender: NSButton) {
        
        let panel = self.openSavePanel()
        
        panel.begin { (result) in
            
            if result == NSFileHandlingPanelOKButton {
                
                let path = panel.url!.path
                
                self.moduleFileManager.createDirectory(path)
                
                self.moduleFileManager.copyFile(from: TRAFFIC_RESOURCE_PATH, to: path + "/模块")
                
                let modulePath = path + "/序列帧/区位"
                
                self.moduleFileManager.createDirectory(modulePath)
                
                self.createTracficModule(sourceArray:self.dataSource, savePath: path,parentModule:nil)
                
                self.createTrafficSequenceFloder(source:self.dataSource, savePath: modulePath,parentModule:nil)
                
            }
        }
        
    }
    
    //创建区位模块
    private func createTracficModule(sourceArray array:Array<SequenceModule>, savePath path:String,parentModule parentMod:SequenceModule?){
        
        let modulePath = path + "/模块/subs/模块"
        
        guard array.count != 0 else {
            
            return
        }
        
        for item in array {
            
            var j = 0
            
            j = array.index(of: item)!
            
            if let parentModule = parentMod {
                
                let moduleFolderPath = parentModule.modulePath + "/subs/模块/\(String(format:"%.2d",j))" + item.moduleID
                
                self.createModuleAndAddID(from: TRAFFICSUB_RESOURCE_PATH, to: moduleFolderPath, AndItemID: item.moduleID)
                
                //指定模块路径
                
                self.appointModuleSequence(modulePath: moduleFolderPath, sequencePath: item.moduleID, parentModuleID: parentModule.moduleID)
                
            }else{
                
                let itemPath = modulePath + "/\(String(format:"%.2d",j))" + item.moduleID
                
                self.createModuleAndAddID(from: TRAFFICROOT_RESOURCE_PATH, to: itemPath, AndItemID: item.moduleID)
                
                item.modulePath = itemPath
                
                self.createTracficModule(sourceArray: item.leafModules, savePath: path, parentModule: item)
                //背景
                self.createModuleAndAddID(from: TRAFFICSUB_RESOURCE_PATH, to: itemPath + "/subs/背景", AndItemID: "")
                
                self.appointModuleSequence(modulePath: itemPath + "/subs/背景", sequencePath: "背景", parentModuleID: item.moduleID)
                
                //logo
                self.createModuleAndAddID(from: TRAFFICSUB_RESOURCE_PATH, to: itemPath + "/subs/装饰/subs/logo", AndItemID: "")
                
                self.appointModuleSequence(modulePath: itemPath + "/subs/装饰/subs/logo", sequencePath: "logo", parentModuleID: item.moduleID)
                
                if item.isLeaf {
                    
                    let moduleFolderPath = itemPath + "/subs/模块/\(String(format:"%.2d",j))" + item.moduleID
                    
                    self.createModuleAndAddID(from: TRAFFICSUB_RESOURCE_PATH, to: moduleFolderPath, AndItemID: item.moduleID)
                    
                    //指定模块路径
                    
                    self.appointModuleSequence(modulePath: moduleFolderPath, sequencePath: item.moduleID, parentModuleID: item.moduleID)
                    
                }
            }
            
            
/**            if item.isLeaf {
                
                if let parentModule = parentMod {
                    
                    let moduleFolderPath = parentModule.modulePath + "/subs/模块/02.内容/subs/模块/\(String(format:"%.2d",j))" + item.moduleID
                    
                    self.createModuleAndAddID(from: TRAFFICSUB_RESOURCE_PATH, to: moduleFolderPath, AndItemID: item.moduleID)
                    
                    //指定模块路径
                    
                    self.appointModuleSequence(modulePath: moduleFolderPath, sequencePath: item.moduleID, parentModuleID: parentModule.moduleID)
                }else{
                    
                    
                    let moduleFolderPath = modulePath + "/\(String(format:"%.2d",j))" + item.moduleID
                    
                    self.createModuleAndAddID(from: TRAFFICSUB_RESOURCE_PATH, to: moduleFolderPath, AndItemID: item.moduleID)
                    
                    //指定模块路径
                    
                    self.appointModuleSequence(modulePath: moduleFolderPath, sequencePath: item.moduleID, parentModuleID: nil)
                
                }
                
            }else{
                
                let itemPath = modulePath + "/\(String(format:"%.2d",j))" + item.moduleID
                
                self.createModuleAndAddID(from: TRAFFICROOT_RESOURCE_PATH, to: itemPath, AndItemID: item.moduleID)
                
                item.modulePath = itemPath
                
                self.createTracficModule(sourceArray: item.leafModules, savePath: path, parentModule: item)
                
                //主模块导入
                
                self.xmlTool.changeXMLRootElementProperty(targetXMLPath: itemPath + "/subs/模块/01.导入/datafile.xml", addProperty: "序列帧/区位/\(item.moduleID)/导入")
                //背景
                
                self.xmlTool.changeXMLRootElementProperty(targetXMLPath: itemPath + "/subs/模块/02.内容/subs/背景/datafile.xml", addProperty: "序列帧/区位/\(item.moduleID)/背景")
                
                //logo
                self.createModuleAndAddID(from: TRAFFICSUB_RESOURCE_PATH, to: itemPath + "/subs/模块/02.内容/subs/装饰/subs/logo", AndItemID: "")
                
                self.appointModuleSequence(modulePath: itemPath + "/subs/模块/02.内容/subs/装饰/subs/logo", sequencePath:"logo", parentModuleID: nil)
                
                
            }
**/
            
        }
    }
    
    private func appointModuleSequence(modulePath path:String,sequencePath sequence:String, parentModuleID parentID:String?){
        
        var sequencePath = "序列帧/区位"
        
        if let str = parentID {
            
            if sequence == "logo" || sequence == "背景"{
                
                sequencePath = sequencePath + "/\(str)"
                
            }else{
                
                sequencePath = sequencePath + "/\(str)" + "/模块"
                
            }
        }
        
        //导入
        
        self.xmlTool.changeXMLRootElementProperty(targetXMLPath: path + "/subs/模块/01.导入/datafile.xml", addProperty: sequencePath + "/\(sequence)/导入" )
        
        //内容
        
        self.xmlTool.changeXMLRootElementProperty(targetXMLPath: path + "/subs/模块/02.内容/datafile.xml", addProperty: sequencePath + "/\(sequence)/内容" )
    }
    
    //创建区位序列文件
    private func createTrafficSequenceFloder(source folderSource:Array<SequenceModule>,savePath path:String,parentModule parentMod:SequenceModule?){
        
        if folderSource.count == 0 {
            
            return
        }
        
        
        for item in folderSource {
            
            if let parentModule = parentMod {
                
                self.moduleFileManager.copyFile(from: TRAFFICSUBFOLDER_RESOURCE_PATH, to: parentModule.modulePath + "/模块" + "/\(item.moduleID)")
                
            }else{
                
                let itemPath = path + "/" + item.moduleID
                
                self.moduleFileManager.copyFile(from: TRAFFICROOTFOLDER_RESOURCE_PATH, to: itemPath )
                
                item.modulePath = itemPath
                
                self.createTrafficSequenceFloder(source: item.leafModules, savePath: path, parentModule: item)
                
                if item.isLeaf {
                    
                    self.moduleFileManager.copyFile(from: TRAFFICSUBFOLDER_RESOURCE_PATH, to: itemPath + "/模块" + "/\(item.moduleID)")
                }
            
            
            }
            
            
/**            if item.isLeaf {
                
                if let parentModule = parentMod {
                
                    self.moduleFileManager.copyFile(from: TRAFFICSUBFOLDER_RESOURCE_PATH, to: parentModule.modulePath + "/模块" + "/\(item.moduleID)")
                    
                }else{
                    
                    self.moduleFileManager.copyFile(from: TRAFFICSUBFOLDER_RESOURCE_PATH, to: path + "/\(item.moduleID)")
                }
                
            }else{
                
                let itemPath = path + "/" + item.moduleID
            
                self.moduleFileManager.copyFile(from: TRAFFICROOTFOLDER_RESOURCE_PATH, to: itemPath )
                
                item.modulePath = itemPath
                
                self.createTrafficSequenceFloder(source: item.leafModules, savePath: path, parentModule: item)
            
            }
**/
            
        }
    }
    
    private func createModuleAndAddID(from pathFrom:String,to pathTo:String,AndItemID item:String){
        
        //创建模块
        self.moduleFileManager.copyFile(from: pathFrom, to: pathTo)
        
        //命名模块ID
//        self.xmlTool.addXMLFileElement(targetXMLPath: pathTo + "/config.xml", addProperty: item)
        self.xmlTool.addXMLFileElement(targetXMLPath: pathTo + "/config.xml", addProperty: item, withElementName: "id")
        
    }
    
    private func createModuleAndAddName(from pathFrom:String,to pathTo:String,AndItemName item:String){
        
        //创建模块
        self.moduleFileManager.copyFile(from: pathFrom, to: pathTo)
        
        //命名模块Name
        //        self.xmlTool.addXMLFileElement(targetXMLPath: pathTo + "/config.xml", addProperty: item)
        self.xmlTool.addXMLFileElement(targetXMLPath: pathTo + "/config.xml", addProperty: item, withElementName: "name")
        
    }
    
    
}

extension ViewController:NSMenuDelegate{

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        menu.addItem(NSMenuItem.init(title: "删除", action: #selector(remove), keyEquivalent: ""))
        
    }
    
    func remove(menu:NSMenu) {
        
        guard let clickModule = self.moduleListOutlineView.item(atRow: self.moduleListOutlineView.clickedRow) as? SequenceModule else { return
        
        }
        
        if clickModule.parentModule == nil {//没有父模块
            
            if self.dataSource.contains(clickModule) {
                
                let index = self.dataSource.index(of: clickModule)
                
                self.dataSource.remove(at: index!)
                
            }
    
        }else{
            
            if (clickModule.parentModule?.leafModules.contains(clickModule))! {
                
                let index = clickModule.parentModule?.leafModules.index(of: clickModule)
                
                clickModule.parentModule?.leafModules.remove(at: index!)
                
                if clickModule.parentModule?.leafModules.count == 0 {
                    
                    clickModule.parentModule?.isLeaf = true
                }
                
            }
            
        
        }
        
        self.moduleListOutlineView.reloadData()
        
    }
}

//MARK: DataSource Delegate
extension ViewController:NSOutlineViewDataSource {
    
    public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        
        if let item = item as? SequenceModule {
            
            return item.leafModules.count
        }
        
        return dataSource.count
    }
    
    public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        
        if let item = item as? SequenceModule {
            
            return !item.isLeaf
        }
        
        return false
    }
    
    public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        
        if let item  = item as? SequenceModule {
            
            return item.leafModules[index]
        }
        
        return dataSource[index]
    }
}



//MARK: View Delegate
extension ViewController:NSOutlineViewDelegate{
    
    public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        var cell:NSTableCellView?
        
        cell = outlineView.make(withIdentifier: "Cell", owner: self) as? NSTableCellView
        
        if let item = item as? SequenceModule {
            
            cell?.textField?.stringValue = item.moduleID
            
        }
        
        return cell
        
    }
    
    //删除
    public func outlineView(_ outlineView: NSOutlineView, didRemove rowView: NSTableRowView, forRow row: Int) {
        
        
        
    }
    
    //点击列的表头
    public func outlineView(_ outlineView: NSOutlineView, didClick tableColumn: NSTableColumn) {
        
    }
    
    public func outlineView(_ outlineView: NSOutlineView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        
        return proposedSelectionIndexes
    }
    
    
}

