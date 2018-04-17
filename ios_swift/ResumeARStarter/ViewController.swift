//
//  ViewController.swift
//  ResumeAR
//
//  Created by Sanjeev Ghimire on 10/26/17.
//  Copyright © 2017 Sanjeev Ghimire. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision
import RxSwift
import RxCocoa
import SwiftyJSON
import VisualRecognitionV3
import PKHUD
import CoreML


class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var 👜 = DisposeBag()
    var faces: [Face] = []
    var bounds: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    var visualRecognition: VisualRecognition?
    var cloudantRestCall: CloudantRESTCall?
    var classifierIds: [String] = []
    
    let VERSION = "2017-12-07"
    
    var isTraining: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        bounds = sceneView.bounds
        //configure IBM cloud services required by this app
        self.configureCloudantAndVisualRecognition()
        
        let localModels = try? self.visualRecognition?.listLocalModels()
        if let count = localModels??.count, count > 0 {
            localModels??.forEach { classifierId in
                if(!self.classifierIds.contains(classifierId)){
                    self.classifierIds.append(classifierId)
                }
            }
            self.isTraining = false;
        }else{
        
            self.visualRecognition?.listClassifiers(){
            classifiers in
 
            
        // check to see if VR classifier has already been created.
        if(classifiers.classifiers.count == 0){
                /*
                 We will create 3 classifier by default during app load if not yet created:
                 1. Steve
                 2. Sanjeev
                 3. Scott
                 */
                let sanjeevZipPath: URL  = Bundle.main.url(forResource: Constant.sanjeevZip, withExtension: "zip")!
                let steveZipPath: URL = Bundle.main.url(forResource: Constant.steveZip, withExtension: "zip")!
                let scottZipPath: URL = Bundle.main.url(forResource: Constant.scottZip, withExtension: "zip")!
                let sanjeevNegativeZipPath: URL = Bundle.main.url(forResource: Constant.sanjeevNegativeZip, withExtension: "zip")!
                let steveNegativeZipPath: URL = Bundle.main.url(forResource: Constant.steveNegativeZip, withExtension: "zip")!
                let scottNegativeZipPath: URL = Bundle.main.url(forResource: Constant.scottNegativeZip, withExtension: "zip")!
            
                let failure = { (error: Error) in print(error) }
            
                //Steve classification
                var stevePos: [PositiveExample] = []
                let steveClassifier = PositiveExample.init(name: "Steve", examples: steveZipPath)
                stevePos.append(steveClassifier)
            self.visualRecognition?.createClassifier(name: "SteveMartinelli", positiveExamples: stevePos, negativeExamples: steveNegativeZipPath, failure: failure){
                    Classifier in
                    let userData = ["classificationId": Classifier.classifierID,
                                          "fullname": Constant.SteveName,
                                          "linkedin": Constant.SteveLI,
                                          "twitter": Constant.SteveTW,
                                          "facebook": Constant.SteveFB,
                                          "phone": Constant.StevePh,
                                          "location": Constant.SteveLoc]
                    
                self.cloudantRestCall?.updatePersonData(userData: JSON(userData)){ (resultJSON) in
                        if(!resultJSON["ok"].boolValue){
                            print("Error while saving user Data",userData)
                            return
                        }
                    }
                }
            
                //Sanjeev  Classification
                var sanjeevPos: [PositiveExample] = []
                let sanjeevClassifier = PositiveExample.init(name: "Sanjeev", examples: sanjeevZipPath)
                sanjeevPos.append(sanjeevClassifier)
            self.visualRecognition?.createClassifier(name: "SanjeevGhimire", positiveExamples: sanjeevPos, negativeExamples: sanjeevNegativeZipPath, failure: failure){
                    Classifier in
                    let userData = ["classificationId": Classifier.classifierID,
                                    "fullname": Constant.SanjeevName,
                                    "linkedin": Constant.SanjeevLI,
                                    "twitter": Constant.SanjeevTW,
                                    "facebook": Constant.SanjeevFB,
                                    "phone": Constant.SanjeevPh,
                                    "location": Constant.SanjeevLoc]
                    
                    self.cloudantRestCall?.updatePersonData(userData: JSON(userData)){ (resultJSON) in
                        if(!resultJSON["ok"].boolValue){
                            print("Error while saving user Data",userData)
                            return
                        }
                    }
                }
                // Scott classification
                var scottPos: [PositiveExample] = []
                let scottClassifier = PositiveExample.init(name: "Scott", examples: scottZipPath)
                scottPos.append(scottClassifier)
            self.visualRecognition?.createClassifier(name: "ScottDAngelo", positiveExamples: scottPos, negativeExamples: scottNegativeZipPath, failure: failure){
                    Classifier in
                    let userData = ["classificationId": Classifier.classifierID,
                                    "fullname": Constant.ScottName,
                                    "linkedin": Constant.ScottLI,
                                    "twitter": Constant.ScottTW,
                                    "facebook": Constant.ScottFB,
                                    "phone": Constant.ScottPh,
                                    "location": Constant.ScottLoc]
                    
                    self.cloudantRestCall?.updatePersonData(userData: JSON(userData)){ (resultJSON) in
                        if(!resultJSON["ok"].boolValue){
                            print("Error while saving user Data",userData)
                            return
                        }
                    }
                }
            }else {
                self.isTraining = classifiers.classifiers[0].status == "training"
            }
        }
        }
        
    }
 
    
    // Setup cloudant driver and visual recognition api
    func configureCloudantAndVisualRecognition() {
        // Retrieve plist
        guard let path = Bundle.main.path(forResource: "BMSCredentials", ofType: "plist"),
            let credentials = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
                return
        }
        
        // Retrieve credentials
        guard let vrApiKey = credentials["visualrecognitionApi_key"] as? String, !vrApiKey.isEmpty,
            let url = credentials["cloudantUrl"] as? String, !url.isEmpty else {
                return
        }
        
        self.visualRecognition = VisualRecognition.init(apiKey: vrApiKey, version: self.VERSION)
        self.cloudantRestCall = CloudantRESTCall.init(cloudantUrl: url)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
        
        Observable<Int>.interval(0.6, scheduler: SerialDispatchQueueScheduler(qos: .default))
            .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
            .flatMap{_ in self.makeClassificationReadyForAR()}            
            .flatMap{ self.faceObservation(isReady: $0) }
            .flatMap{ Observable.from($0)}
            .flatMap{ self.faceClassification(face: $0.observation, image: $0.image, frame: $0.frame) }
            .subscribe { [unowned self] event in
                guard let element = event.element else {
                    print("No element available")
                    return
                }
                self.updateNode(classes: element.classes, position: element.position, frame: element.frame)
            }.disposed(by: 👜)
        
        Observable<Int>.interval(0.6, scheduler: SerialDispatchQueueScheduler(qos: .default))
            .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
            .subscribe { [unowned self] _ in
                
                self.faces.filter{ $0.updated.isAfter(seconds: 1.5) && !$0.hidden }.forEach{ face in
                    //print("Hide node: \(face.name)")
                    DispatchQueue.main.async{ face.node.hide() }
                }
            }.disposed(by: 👜)
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        👜 = DisposeBag()
        sceneView.session.pause()
    }
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        switch camera.trackingState {
        case .limited(.initializing):
            PKHUD.sharedHUD.contentView = PKHUDProgressView(title: "Initializing", subtitle: nil)
            PKHUD.sharedHUD.show()
        case .notAvailable:
            print("Not available")
        default:
            PKHUD.sharedHUD.hide()
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    
    // MARK: - Face detections
    private func faceObservation(isReady: Bool) -> Observable<[(observation: VNFaceObservation, image: CIImage, frame: ARFrame)]> {
        return Observable<[(observation: VNFaceObservation, image: CIImage, frame: ARFrame)]>.create{ observer in
            if(!isReady){
                print("Training is still in progress")
                self.updateNodeWithStillInTraining()
                observer.onCompleted()
                return Disposables.create()
            }
            
            guard let frame = self.sceneView.session.currentFrame else {
                print("No frame available")
                observer.onCompleted()
                return Disposables.create()
            }
            
            // Create and rotate image
            let image = CIImage.init(cvPixelBuffer: frame.capturedImage).rotate
            let facesRequest = VNDetectFaceRectanglesRequest { request, error in
                guard error == nil else {
                    print("Face request error: \(error!.localizedDescription)")
                    observer.onCompleted()
                    return
                }
                guard let observations = request.results as? [VNFaceObservation] else {
                    print("No face observations")
                    observer.onCompleted()
                    return
                }
                // Map response
                let response = observations.map({ (face) -> (observation: VNFaceObservation, image: CIImage, frame: ARFrame) in
                    return (observation: face, image: image, frame: frame)
                })
                observer.onNext(response)
                observer.onCompleted()
                
            }
            try? VNImageRequestHandler(ciImage: image).perform([facesRequest])
            
            return Disposables.create()
        }
    }
    
    
    private func faceClassification(face: VNFaceObservation, image: CIImage, frame: ARFrame) -> Observable<(classes: [ClassifiedImage], position: SCNVector3, frame: ARFrame)> {
        return Observable<(classes: [ClassifiedImage], position: SCNVector3, frame: ARFrame)>.create{ observer in
            
            // Determine position of the face
            let boundingBox = self.transformBoundingBox(face.boundingBox)
            guard let worldCoord = self.normalizeWorldCoord(boundingBox) else {
                print("No feature point found")
                observer.onCompleted()
                return Disposables.create()
            }
            
            // Create Classification request
            let pixel = image.cropImage(toFace: face)
            //convert the cropped image to UI image
            let uiImage: UIImage = self.convert(cmage: pixel)
         
            let failure = { (error: Error) in print(error) }
            self.visualRecognition?.classifyWithLocalModel(image: uiImage, classifierIDs: self.classifierIds, threshold: 0, failure: failure) { classifiedImages in
                  print(classifiedImages)
                  observer.onNext((classes: classifiedImages.images, position: worldCoord, frame: frame))
                  observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    
    /// Transform bounding box according to device orientation
    ///
    /// - Parameter boundingBox: of the face
    /// - Returns: transformed bounding box
    private func transformBoundingBox(_ boundingBox: CGRect) -> CGRect {
        var size: CGSize
        var origin: CGPoint
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight:
            size = CGSize(width: boundingBox.width * bounds.height,
                          height: boundingBox.height * bounds.width)
        default:
            size = CGSize(width: boundingBox.width * bounds.width,
                          height: boundingBox.height * bounds.height)
        }
        
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            origin = CGPoint(x: boundingBox.minY * bounds.width,
                             y: boundingBox.minX * bounds.height)
        case .landscapeRight:
            origin = CGPoint(x: (1 - boundingBox.maxY) * bounds.width,
                             y: (1 - boundingBox.maxX) * bounds.height)
        case .portraitUpsideDown:
            origin = CGPoint(x: (1 - boundingBox.maxX) * bounds.width,
                             y: boundingBox.minY * bounds.height)
        default:
            origin = CGPoint(x: boundingBox.minX * bounds.width,
                             y: (1 - boundingBox.maxY) * bounds.height)
        }
        
        return CGRect(origin: origin, size: size)
    }
    
    /// In order to get stable vectors, we determine multiple coordinates within an interval.
    ///
    /// - Parameters:
    ///   - boundingBox: Rect of the face on the screen
    /// - Returns: the normalized vector
    private func normalizeWorldCoord(_ boundingBox: CGRect) -> SCNVector3? {
        
        var array: [SCNVector3] = []
        Array(0...2).forEach{_ in
            if let position = determineWorldCoord(boundingBox) {
                array.append(position)
            }
            //usleep(12000) // .012 seconds
        }
        
        if array.isEmpty {
            return nil
        }
        
        return SCNVector3.center(array)
    }
    
    
    /// Determine the vector from the position on the screen.
    ///
    /// - Parameter boundingBox: Rect of the face on the screen
    /// - Returns: the vector in the sceneView
    private func determineWorldCoord(_ boundingBox: CGRect) -> SCNVector3? {
        let arHitTestResults = sceneView.hitTest(CGPoint(x: boundingBox.midX, y: boundingBox.midY), types: [.featurePoint])
        
        // Filter results that are to close
        if let closestResult = arHitTestResults.filter({ $0.distance > 0.10 }).first {
            //            print("vector distance: \(closestResult.distance)")
            return SCNVector3.positionFromTransform(closestResult.worldTransform)
        }
        return nil
    }
    
    
    // updating node when not ready for visual recogntion aka training in progress.
    private func updateNodeWithStillInTraining(){
        let node = SCNNode.init(withText: "Training in progress", position: SCNVector3.init(0, 0, 0))
        DispatchQueue.main.async {
            self.sceneView.scene.rootNode.addChildNode(node)
            node.show()
        }
    }
    
    private func updateNode(classes: [ClassifiedImage], position: SCNVector3, frame: ARFrame) {
        guard let classifiedImage = classes.first else {
            print("No classification found")
            return
        }
        
        // get the classifier result with best score
        var personWithHighScore: ClassifierResult? = nil
        var highestScore: Double = 0.0
        classifiedImage.classifiers.forEach { classifierResult in
            let score: Double = (classifierResult.classes.first?.score)!
            if(score > highestScore){
                highestScore = score
                personWithHighScore = classifierResult
            }
        }
        
        let name = personWithHighScore?.name
        let classifierId = personWithHighScore?.classifierID
        // Filter for existent face
        let results = self.faces.filter{ $0.name == name && $0.timestamp != frame.timestamp }
            .sorted{ $0.node.position.distance(toVector: position) < $1.node.position.distance(toVector: position) }
        
        // Create new face
        //note:: texture
        guard let existentFace = results.first else {
            self.cloudantRestCall?.getResumeInfo(classificationId: classifierId!) { (resultJSON) in
                let node = SCNNode.init(withJSON: resultJSON["docs"][0], position: position)
                DispatchQueue.main.async {
                    self.sceneView.scene.rootNode.addChildNode(node)
                    node.show()
                }
                let face = Face.init(name: name!, node: node, timestamp: frame.timestamp)
                self.faces.append(face)
            }
            return
        }
        // Update existent face
        DispatchQueue.main.async {
            
            // Filter for face that's already displayed
            if let displayFace = results.filter({ !$0.hidden }).first  {
                let distance = displayFace.node.position.distance(toVector: position)
                if(distance >= 0.03 ) {
                    displayFace.node.move(position)
                }
                displayFace.timestamp = frame.timestamp
                
            } else {
                existentFace.node.position = position
                existentFace.node.show()
                existentFace.timestamp = frame.timestamp
            }
        }
    }
    
    func convert(cmage:CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
    
   
    private func makeClassificationReadyForAR() -> Observable<Bool>{
        return Observable<Bool>.create{ observer in
        //get all the classifier id
        // check if visual recognition is not ready yet.
          
        if(!self.classifierIds.isEmpty){
            observer.onNext(true)
            observer.onCompleted()
            return Disposables.create()
        }
            
            
        let localModels = try? self.visualRecognition?.listLocalModels()
            if let count = localModels??.count, count > 0 {
                localModels??.forEach { classifierId in
                if(!self.classifierIds.contains(classifierId)){
                    self.classifierIds.append(classifierId)
                }
            }
            observer.onNext(true)
            observer.onCompleted()
            return Disposables.create()
        }
          
    
        self.visualRecognition?.listClassifiers(){ classifiers in
            let count: Int = classifiers.classifiers.count
            if(count == 0 || classifiers.classifiers[0].status == "training"){
                print("Still in Training phase")
                observer.onNext(false)
                observer.onCompleted()
            }
            
            if(count > 0 && classifiers.classifiers[0].status == "ready"){
                classifiers.classifiers.forEach{
                    classifier in
                    if(!self.classifierIds.contains(classifier.classifierID)){
                        self.classifierIds.append(classifier.classifierID)
                    }
                    self.visualRecognition?.updateLocalModel(classifierID: classifier.classifierID)
                }
                observer.onNext(true)
                observer.onCompleted()
            }
            
        }
         return Disposables.create()
        }
    }
    
    
}

