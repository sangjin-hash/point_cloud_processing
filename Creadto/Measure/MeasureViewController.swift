//
//  MeasureViewController.swift
//  Creadto
//
//  Created by 이상진 on 2022/12/30.
//

import UIKit
import SwiftUI
import SceneKit

class MeasureViewController: UIViewController {
    
    private let sceneView = SCNView()
    private var scene : SCNScene!
    
    private var left_customTableView : CustomTableView!
    private var right_customTableView : CustomTableView!
    
    lazy var _measureData = setupData()
    
    private let jsonURL : URL
    
    private var memberName = ["Height\n", "Front\ntorso\n", "Chest\n", "Waist\n"]
    private var memberName2 = ["Armpit\n", "Armhole\n", "Knee\nlocation\n", "Knee\nheight\n"]
    
//    private var memberName = ["Height\n","Front\nFace\n", "Neck\n", "Front\ntorso\n", "Chest\n", "Waist\n",
//                      "Hip\n", "Thigh\n", "Mid\nThigh\n", "Knee\n", "Calf\n",
//                      "Ankle\n", "Mid\nFace\n", "Neck\nto Chest\n","Front\ntorso\n", "Front\nCenter\n"]
//    private var memberName2 = ["Armpit\n", "Armhole\n", "Knee\nlocation\n","Knee\nheight\n", "Side\nface\n",
//                       "Shoulder\n", "Arm\n","Wrist\n", "Upper\narm\n", "Elbow\nmeasurement\n",
//                       "Elbow\nlength\n", "Vertical\ntorso\n", "Vertical\nhip\n", "Hip\n", "Back\n",]
    
    private let detailButton : UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setTitleColor(UIColor.white, for: UIControl.State.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.semibold)
        button.backgroundColor = UIColor(red: 0.14, green: 0.54, blue: 1.0, alpha: 1.0)
        button.layer.cornerRadius = 10
        button.setTitle("Details", for: UIControl.State.normal)
        button.addTarget(self, action: #selector(detailsTapped(_:)), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    init(jsonURL: URL) {
        self.jsonURL = jsonURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder){
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        _setupData()
        sceneView.scene = scene
        
        view.addSubview(sceneView)
        view.addSubview(detailButton)
        
        configureTableView()
        registerTableView()
        tableViewDelegate()
    }
    
    override func viewDidLayoutSubviews() {
        sceneView.frame = view.bounds
        
        let buttonHeight: CGFloat = 56
        let buttonSpacing: CGFloat = 20
        let buttonInsets = UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 20)
        
        var buttonFrame = CGRect.zero
        buttonFrame.size.width = CGFloat(1) / CGFloat(2) * (view.bounds.width - buttonInsets.left - buttonInsets.right - CGFloat(1) * buttonSpacing)
        buttonFrame.size.height = buttonHeight
        buttonFrame.origin.x = view.bounds.width / 2 - buttonFrame.size.width / 2
        buttonFrame.origin.y = view.bounds.height - view.safeAreaInsets.bottom - buttonInsets.bottom - buttonHeight
        detailButton.frame = buttonFrame
    }
    
    private func setupData() -> Measurement {
        let _data = try! Data(contentsOf: jsonURL)
        return try! JSONDecoder().decode(Measurement.self, from: _data)
    }
    
    private func setupView(){
        scene = try! SCNScene(url: jsonURL.deletingLastPathComponent().appendingPathComponent("Mesh.ply"))
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor.white
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        sceneView.pointOfView = cameraNode
        cameraNode.position  = SCNVector3(0,0.3,2)
    }
    
    private func configureTableView() {
        left_customTableView = CustomTableView()
        right_customTableView = CustomTableView()
        left_customTableView.translatesAutoresizingMaskIntoConstraints = false
        right_customTableView.translatesAutoresizingMaskIntoConstraints = false
        
        left_customTableView.layer.cornerRadius = 10.0
        right_customTableView.layer.cornerRadius = 10.0
        
        view.addSubview(left_customTableView)
        view.addSubview(right_customTableView)
        
        left_customTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 0).isActive = true
        left_customTableView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        left_customTableView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        left_customTableView.heightAnchor.constraint(equalToConstant: 320).isActive = true
        
        right_customTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 0).isActive = true
        right_customTableView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        right_customTableView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        right_customTableView.heightAnchor.constraint(equalToConstant: 320).isActive = true
    }
    
    private func tableViewDelegate() {
        left_customTableView.delegate = self
        left_customTableView.dataSource = self
        
        right_customTableView.delegate = self
        right_customTableView.dataSource = self
    }
    
    private func registerTableView() {
        left_customTableView.register(CustomTableViewCell.classForCoder(), forCellReuseIdentifier: "cellIdentifier")
        right_customTableView.register(CustomTableViewCell.classForCoder(), forCellReuseIdentifier: "cellIdentifier")
    }
    
    @objc
    private func detailsTapped(_ sender: UIButton){
        let vc = UIHostingController(rootView: DetailsView())
        self.present(vc, animated: true)
    }
    
    private func _setupData() {
        let _data = try! Data(contentsOf: jsonURL)
        let jsonData = try! JSONDecoder().decode(Measurement.self, from: _data)
        
        // mock data
        memberName[0] += _measureData.X_Measure_1000 == nil ? "-" : (String(_measureData.X_Measure_1000!) + "cm")
        memberName[1] += _measureData.X_Measure_1003 == nil ? "_" : (String(_measureData.X_Measure_1003!) + "cm")
        memberName[2] += _measureData.X_Measure_1004 == nil ? "_" : (String(_measureData.X_Measure_1004!) + "cm")
        memberName[3] += _measureData.X_Measure_1005 == nil ? "_" : (String(_measureData.X_Measure_1005!) + "cm")

        memberName2[0] += _measureData.X_Measure_2001 == nil ? "_" : (String(_measureData.X_Measure_2001!) + "cm")
        memberName2[1] += _measureData.X_Measure_2002 == nil ? "_" : (String(_measureData.X_Measure_2002!) + "cm")
        memberName2[2] += _measureData.X_Measure_2101 == nil ? "_" : (String(_measureData.X_Measure_2101!) + "cm")
        memberName2[3] += _measureData.X_Measure_2102 == nil ? "_" : (String(_measureData.X_Measure_2102!) + "cm")
        
        if _measureData.X_Measure_1000 != nil { DetailsData.data[0].value = String(_measureData.X_Measure_1000!) + "cm" }
        if _measureData.X_Measure_1001 != nil { DetailsData.data[1].value = String(_measureData.X_Measure_1001!) + "cm" }
        if _measureData.X_Measure_1002 != nil { DetailsData.data[2].value = String(_measureData.X_Measure_1002!) + "cm" }
        if _measureData.X_Measure_1003 != nil { DetailsData.data[3].value = String(_measureData.X_Measure_1003!) + "cm" }
        if _measureData.X_Measure_1004 != nil { DetailsData.data[4].value = String(_measureData.X_Measure_1004!) + "cm" }
        if _measureData.X_Measure_1005 != nil { DetailsData.data[5].value = String(_measureData.X_Measure_1005!) + "cm" }
        if _measureData.X_Measure_1006 != nil { DetailsData.data[6].value = String(_measureData.X_Measure_1006!) + "cm" }
        if _measureData.X_Measure_1007 != nil { DetailsData.data[7].value = String(_measureData.X_Measure_1007!) + "cm" }
        if _measureData.X_Measure_1008 != nil { DetailsData.data[8].value = String(_measureData.X_Measure_1008!) + "cm" }
        if _measureData.X_Measure_1009 != nil { DetailsData.data[9].value = String(_measureData.X_Measure_1009!) + "cm" }
        if _measureData.X_Measure_1010 != nil { DetailsData.data[10].value = String(_measureData.X_Measure_1010!) + "cm" }
        if _measureData.X_Measure_1011 != nil { DetailsData.data[11].value = String(_measureData.X_Measure_1011!) + "cm" }
        
        if _measureData.X_Measure_1101 != nil { DetailsData.data[12].value = String(_measureData.X_Measure_1101!) + "cm" }
        if _measureData.X_Measure_1102 != nil { DetailsData.data[13].value = String(_measureData.X_Measure_1102!) + "cm" }
        if _measureData.X_Measure_1103 != nil { DetailsData.data[14].value = String(_measureData.X_Measure_1103!) + "cm" }
        if _measureData.X_Measure_1104 != nil { DetailsData.data[15].value = String(_measureData.X_Measure_1104!) + "cm" }
        
        if _measureData.X_Measure_2001 != nil { DetailsData.data[16].value = String(_measureData.X_Measure_2001!) + "cm" }
        if _measureData.X_Measure_2002 != nil { DetailsData.data[17].value = String(_measureData.X_Measure_2002!) + "cm" }
        if _measureData.X_Measure_2101 != nil { DetailsData.data[18].value = String(_measureData.X_Measure_2101!) + "cm" }
        if _measureData.X_Measure_2102 != nil { DetailsData.data[19].value = String(_measureData.X_Measure_2102!) + "cm" }
        
        if _measureData.X_Measure_3001 != nil { DetailsData.data[20].value = String(_measureData.X_Measure_3001!) + "cm" }
        if _measureData.X_Measure_3002 != nil { DetailsData.data[21].value = String(_measureData.X_Measure_3002!) + "cm" }
        if _measureData.X_Measure_3003 != nil { DetailsData.data[22].value = String(_measureData.X_Measure_3003!) + "cm" }
        if _measureData.X_Measure_3004 != nil { DetailsData.data[23].value = String(_measureData.X_Measure_3004!) + "cm" }
        if _measureData.X_Measure_3005 != nil { DetailsData.data[24].value = String(_measureData.X_Measure_3005!) + "cm" }
        if _measureData.X_Measure_3006 != nil { DetailsData.data[25].value = String(_measureData.X_Measure_3006!) + "cm" }
        if _measureData.X_Measure_3101 != nil { DetailsData.data[26].value = String(_measureData.X_Measure_3101!) + "cm" }
        if _measureData.X_Measure_3102 != nil { DetailsData.data[27].value = String(_measureData.X_Measure_3102!) + "cm" }
        if _measureData.X_Measure_3103 != nil { DetailsData.data[28].value = String(_measureData.X_Measure_3103!) + "cm" }
        if _measureData.X_Measure_3104 != nil { DetailsData.data[29].value = String(_measureData.X_Measure_3104!) + "cm" }
        if _measureData.X_Measure_3105 != nil { DetailsData.data[30].value = String(_measureData.X_Measure_3105!) + "cm" }
    }
    
}

extension MeasureViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case left_customTableView :
            return memberName.count
        case right_customTableView :
            return memberName2.count
        default :
            fatalError("Invalid table")
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case left_customTableView :
            let cell = left_customTableView.dequeueReusableCell(withIdentifier: "cellIdentifier", for: indexPath) as! CustomTableViewCell
            cell.measurementLabel.text = memberName[indexPath.row]
            
            let subString = memberName[indexPath.row].split(separator: "\n")
            let attributedString = NSMutableAttributedString(string: cell.measurementLabel.text!)
            attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: (cell.measurementLabel.text! as NSString).range(of: String(subString.last!)))
            attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: (cell.measurementLabel.text! as NSString).range(of: String(subString.last!)))
            cell.measurementLabel.attributedText = attributedString
            
            return cell
        case right_customTableView :
            let cell = right_customTableView.dequeueReusableCell(withIdentifier: "cellIdentifier", for: indexPath) as! CustomTableViewCell
            cell.measurementLabel.text = memberName2[indexPath.row]
            
            let subString = memberName2[indexPath.row].split(separator: "\n")
            let attributedString = NSMutableAttributedString(string: cell.measurementLabel.text!)
            attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: (cell.measurementLabel.text! as NSString).range(of: String(subString.last!)))
            attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: (cell.measurementLabel.text! as NSString).range(of: String(subString.last!)))
            cell.measurementLabel.attributedText = attributedString
            
            return cell
        default :
            fatalError("Invalid table")
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
}

// mock data
struct _Data {
    
}

