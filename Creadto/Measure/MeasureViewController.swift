//
//  MeasureViewController.swift
//  Creadto
//
//  Created by 이상진 on 2022/12/30.
//

import UIKit
import SceneKit

class MeasureViewController: UIViewController {
    
    private let sceneView = SCNView()
    private var scene : SCNScene!
    
    private var left_customTableView : CustomTableView!
    private var right_customTableView : CustomTableView!
    
    lazy var _measureData = setupData()
    
    private let jsonURL : URL
    
    private var memberName = ["Front\nFace\n", "Neck\n", "Front\ntorso\n", "Chest\n", "Waist\n",
                      "Hip\n", "Thigh\n", "Mid\nThigh\n", "Knee\n", "Calf\n",
                      "Ankle\n", "Mid\nFace\n", "Neck\nto Chest\n","Front\ntorso\n", "Front\nCenter\n"]
    private var memberName2 = ["Armpit\n", "Armhole\n", "Knee\nlocation\n","Knee\nheight\n", "Side\nface\n",
                       "Shoulder\n", "Arm\n","Wrist\n", "Upper\narm\n", "Elbow\nmeasurement\n",
                       "Elbow\nlength\n", "Vertical\ntorso\n", "Vertical\nhip\n", "Hip\n", "Back\n",]
    
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
        //setLight()
        //setCamera()
        _setupData()
        sceneView.scene = scene
        
        view.addSubview(sceneView)
        
        configureTableView()
        registerTableView()
        tableViewDelegate()
    }
    
    override func viewDidLayoutSubviews() {
        sceneView.frame = view.bounds
    }
    
    private func setupData() -> Measurement {
        let _data = try! Data(contentsOf: jsonURL)
        return try! JSONDecoder().decode(Measurement.self, from: _data)
    }
    
    private func _setupData() {
        let _data = try! Data(contentsOf: jsonURL)
        let jsonData = try! JSONDecoder().decode(Measurement.self, from: _data)
        
        // mock data
        memberName[0] += _measureData.X_Measure_1001 == nil ? "_" : (String(_measureData.X_Measure_1001!) + "cm")
        memberName[1] += _measureData.X_Measure_1002 == nil ? "_" : (String(_measureData.X_Measure_1002!) + "cm")
        memberName[2] += _measureData.X_Measure_1003 == nil ? "_" : (String(_measureData.X_Measure_1003!) + "cm")
        memberName[3] += _measureData.X_Measure_1004 == nil ? "_" : (String(_measureData.X_Measure_1004!) + "cm")
        memberName[4] += _measureData.X_Measure_1005 == nil ? "_" : (String(_measureData.X_Measure_1005!) + "cm")
        memberName[5] += _measureData.X_Measure_1006 == nil ? "_" : (String(_measureData.X_Measure_1006!) + "cm")
        memberName[6] += _measureData.X_Measure_1007 == nil ? "_" : (String(_measureData.X_Measure_1007!) + "cm")
        memberName[7] += _measureData.X_Measure_1008 == nil ? "_" : (String(_measureData.X_Measure_1008!) + "cm")
        memberName[8] += _measureData.X_Measure_1009 == nil ? "_" : (String(_measureData.X_Measure_1009!) + "cm")
        memberName[9] += _measureData.X_Measure_1010 == nil ? "_" : (String(_measureData.X_Measure_1010!) + "cm")
        memberName[10] += _measureData.X_Measure_1011 == nil ? "_" : (String(_measureData.X_Measure_1011!) + "cm")
        memberName[11] += _measureData.X_Measure_1101 == nil ? "_" : (String(_measureData.X_Measure_1101!) + "cm")
        memberName[12] += _measureData.X_Measure_1102 == nil ? "_" : (String(_measureData.X_Measure_1102!) + "cm")
        memberName[13] += _measureData.X_Measure_1103 == nil ? "_" : (String(_measureData.X_Measure_1103!) + "cm")
        memberName[14] += _measureData.X_Measure_1104 == nil ? "_" : (String(_measureData.X_Measure_1104!) + "cm")

        memberName2[0] += _measureData.X_Measure_2001 == nil ? "_" : (String(_measureData.X_Measure_2001!) + "cm")
        memberName2[1] += _measureData.X_Measure_2002 == nil ? "_" : (String(_measureData.X_Measure_2002!) + "cm")
        memberName2[2] += _measureData.X_Measure_2101 == nil ? "_" : (String(_measureData.X_Measure_2101!) + "cm")
        memberName2[3] += _measureData.X_Measure_2102 == nil ? "_" : (String(_measureData.X_Measure_2102!) + "cm")
        memberName2[4] += _measureData.X_Measure_3001 == nil ? "_" : (String(_measureData.X_Measure_3001!) + "cm")
        memberName2[5] += _measureData.X_Measure_3002 == nil ? "_" : (String(_measureData.X_Measure_3002!) + "cm")
        memberName2[6] += _measureData.X_Measure_3003 == nil ? "_" : (String(_measureData.X_Measure_3003!) + "cm")
        memberName2[7] += _measureData.X_Measure_3004 == nil ? "_" : (String(_measureData.X_Measure_3004!) + "cm")
        memberName2[8] += _measureData.X_Measure_3005 == nil ? "_" : (String(_measureData.X_Measure_3005!) + "cm")
        memberName2[9] += _measureData.X_Measure_3006 == nil ? "_" : (String(_measureData.X_Measure_3006!) + "cm")
        memberName2[10] += _measureData.X_Measure_3101 == nil ? "_" : (String(_measureData.X_Measure_3101!) + "cm")
        memberName2[11] += _measureData.X_Measure_3102 == nil ? "_" : (String(_measureData.X_Measure_3102!) + "cm")
        memberName2[12] += _measureData.X_Measure_3103 == nil ? "_" : (String(_measureData.X_Measure_3103!) + "cm")
        memberName2[13] += _measureData.X_Measure_3104 == nil ? "_" : (String(_measureData.X_Measure_3104!) + "cm")
        memberName2[14] += _measureData.X_Measure_3105 == nil ? "_" : (String(_measureData.X_Measure_3105!) + "cm")
    }
    
    private func setupView(){
        //scene = SCNScene(named:"Realistic_White_Male_Low_Poly.obj")
        scene = try! SCNScene(url: jsonURL.deletingLastPathComponent().appendingPathComponent("Mesh.ply"))
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor.white
    }
    
    private func setLight(){
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 50, z: 35)
        scene?.rootNode.addChildNode(lightNode)
        
        let back_lightNode = SCNNode()
        back_lightNode.light = SCNLight()
        back_lightNode.light?.type = .omni
        back_lightNode.position = SCNVector3(x: 0, y: 50, z: -35)
        scene?.rootNode.addChildNode(back_lightNode)
    }
    
    private func setCamera() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 90
        cameraNode.position = SCNVector3(x: 0, y: 40, z: 70)
        scene?.rootNode.addChildNode(cameraNode)
    }
    
    func configureTableView() {
        left_customTableView = CustomTableView()
        right_customTableView = CustomTableView()
        left_customTableView.translatesAutoresizingMaskIntoConstraints = false
        right_customTableView.translatesAutoresizingMaskIntoConstraints = false
        
        left_customTableView.layer.cornerRadius = 10.0
        right_customTableView.layer.cornerRadius = 10.0
        
        view.addSubview(left_customTableView)
        view.addSubview(right_customTableView)
        
        left_customTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 0).isActive = true
        left_customTableView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 80).isActive = true
        left_customTableView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        left_customTableView.heightAnchor.constraint(equalToConstant: 560).isActive = true
        
        right_customTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 0).isActive = true
        right_customTableView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 80).isActive = true
        right_customTableView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        right_customTableView.heightAnchor.constraint(equalToConstant: 560).isActive = true
    }
    
    func tableViewDelegate() {
        left_customTableView.delegate = self
        left_customTableView.dataSource = self
        
        right_customTableView.delegate = self
        right_customTableView.dataSource = self
    }
    
    func registerTableView() {
        left_customTableView.register(CustomTableViewCell.classForCoder(), forCellReuseIdentifier: "cellIdentifier")
        right_customTableView.register(CustomTableViewCell.classForCoder(), forCellReuseIdentifier: "cellIdentifier")
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
            return cell
        case right_customTableView :
            let cell = right_customTableView.dequeueReusableCell(withIdentifier: "cellIdentifier", for: indexPath) as! CustomTableViewCell
            cell.measurementLabel.text = memberName2[indexPath.row]
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

