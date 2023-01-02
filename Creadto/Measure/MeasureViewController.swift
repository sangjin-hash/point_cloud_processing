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
        setLight()
        setCamera()
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
        memberName[0] += String(_measureData.X_Measure_1001)
        memberName[1] += String(_measureData.X_Measure_1002)
        memberName[2] += String(_measureData.X_Measure_1003)
        memberName[3] += String(_measureData.X_Measure_1004)
        memberName[4] += String(_measureData.X_Measure_1005)
        memberName[5] += String(_measureData.X_Measure_1006)
        memberName[6] += String(_measureData.X_Measure_1007)
        memberName[7] += String(_measureData.X_Measure_1008)
        memberName[8] += String(_measureData.X_Measure_1009)
        memberName[9] += String(_measureData.X_Measure_1010)
        memberName[10] += String(_measureData.X_Measure_1011)
        memberName[11] += String(_measureData.X_Measure_1101)
        memberName[12] += String(_measureData.X_Measure_1102)
        memberName[13] += String(_measureData.X_Measure_1103)
        memberName[14] += String(_measureData.X_Measure_1104)

        memberName2[0] += String(_measureData.X_Measure_2001)
        memberName2[1] += String(_measureData.X_Measure_2002)
        memberName2[2] += String(_measureData.X_Measure_2101)
        memberName2[3] += String(_measureData.X_Measure_2102)
        memberName2[4] += String(_measureData.X_Measure_3001)
        memberName2[5] += String(_measureData.X_Measure_3002)
        memberName2[6] += String(_measureData.X_Measure_3003)
        memberName2[7] += String(_measureData.X_Measure_3004)
        memberName2[8] += String(_measureData.X_Measure_3005)
        memberName2[9] += String(_measureData.X_Measure_3006)
        memberName2[10] += String(_measureData.X_Measure_3101)
        memberName2[11] += String(_measureData.X_Measure_3102)
        memberName2[12] += String(_measureData.X_Measure_3103)
        memberName2[13] += String(_measureData.X_Measure_3104)
        memberName2[14] += String(_measureData.X_Measure_3105)
    }
    
    private func setupView(){
        scene = SCNScene(named:"Realistic_White_Male_Low_Poly.obj")
        sceneView.allowsCameraControl = true
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

