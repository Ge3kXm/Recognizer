//
//  OCRViewController.swift
//  DocsSDK
//
//  Created by maxiao on 2019/6/10.
//

import UIKit
import SnapKit
import SwiftyJSON
import RxSwift

class OCRViewController: UIViewController {
    // 当前编辑状态
    enum OCRState {
        case edit
        case contrast
        case clip
    }

    // 预处理图片上下文，避免每次都去创建提高性能
    struct OCRPreProcessedImageContext {
        let cgImage: CGImage
        let ciFilter: CIFilter?
    }

    // 目前项目这些都没规范起来，先写在此处
    struct OCRVCConfig {
        static let screenWidth       = UIScreen.main.bounds.width
        static let screenHeight      = UIScreen.main.bounds.height
        static let cancelButtonColor = UIColor(red: 236/255.0, green: 103/255.0, blue: 85/255.0, alpha: 1)
    }

    private var contentImageView: UIImageView!
    private var clipView: OCRClipView!
    private var originalImage: UIImage!
    private var clippedImage: UIImage?
    private var processedImage: UIImage?

    private var fileToken: String?
    private var preProcessedImageCtx: OCRPreProcessedImageContext?
    private var currentState: OCRState       = .clip
    private var disposeBag                   = DisposeBag()

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    private lazy var editorToolbar: OCREditToolbar = {
        let bar = OCREditToolbar(cancelCallback: { [weak self] (_) in
            self?.cancelOCR()
        }, clipCallback: { [weak self] (_) in
            self?.changeToOriImage()
            self?.changeToolbar(state: .clip)
        }, rotateCallback: { [weak self] (_) in
            self?.rotateImage()
        }, contrastCallback: { [weak self] (_) in
            self?.setupContrast()
            self?.changeToolbar(state: .contrast)
            self?.setContrast(value: 0.5)
        }, exportCallback: { [weak self] (_) in
            self?.exportImage()
        })
        bar.isHidden = true
        return bar
    }()

    private lazy var clipToolbar: OCRClipToolbar = {
        let bar = OCRClipToolbar(doneCallback: { [weak self] (_) in
            self?.clipImage()
            self?.changeToolbar(state: .edit)
        }, cancelCallback: { [weak self] (_) in
            self?.navigationController?.dismiss(animated: true, completion: nil)
        })
        return bar
    }()

    private lazy var contrastToolbar: OCRContrastToolbar = {
        let bar = OCRContrastToolbar(doneCallback: { [weak self] (_) in
            self?.changeToolbar(state: .edit)
        }, cancelCallback: { [weak self] (_) in
            self?.contentImageView.image = self?.clippedImage
            self?.processedImage = nil
            self?.changeToolbar(state: .edit)
        }, valueCallback: { [weak self] (value) in
            self?.setContrast(value: value)
        })
        bar.isHidden = true
        return bar
    }()

    init(image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        originalImage = image
        clippedImage  = image
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    private func setupSubviews() {
        view.backgroundColor = .black

        let width  = OCRVCConfig.screenWidth
        let scale  = originalImage.size.height / originalImage.size.width
        var height: CGFloat
        if width * scale > 500 {
            height = 500
            originalImage = ImageUtil.scaleImage(originalImage,
                                                 to: CGSize(width: 3024, height: 4032))
        } else {
            height = width * scale
        }
        let y      = (OCRVCConfig.screenHeight - height) / 2

        contentImageView = UIImageView(frame: CGRect(x: 0, y: y, width: width, height: height))
            .construct({
            $0.contentMode              = .scaleAspectFit
            $0.image                    = originalImage
            $0.isUserInteractionEnabled = true
        })

        clipView = OCRClipView(imgFrame: contentImageView.bounds,
                               points: getPoints())
        contentImageView.addSubview(clipView)

        view.addSubview(contentImageView)
        view.addSubview(clipToolbar)
        view.addSubview(editorToolbar)
        view.addSubview(contrastToolbar)
    }

    private func setupLayout() {

        clipToolbar.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(52 + Display.bottomSafeAreaHeight)
        }

        editorToolbar.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(52 + Display.bottomSafeAreaHeight)
        }

        contrastToolbar.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(106 + Display.bottomSafeAreaHeight)
        }
    }
}

extension OCRViewController {

    private func cancelOCR() {
        let alertController = UIAlertController(title: "",
                                                message: "确认退出吗？",
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "取消",
                                                style: .cancel,
                                                handler: { (_) in
        }))
        alertController.addAction(UIAlertAction(title: "确认",
                                                style: .default,
                                                handler: { (_) in
            self.navigationController?.dismiss(animated: true, completion: nil)
        }))
        present(alertController, animated: true)
    }

    private func setupContrast() {
        guard let cgImage = clippedImage?.cgImage else { return }
        let ciImage = CIImage(cgImage: cgImage)
        let ciFilter = CIFilter(name: "CIColorControls")
        ciFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        preProcessedImageCtx = OCRPreProcessedImageContext(cgImage: cgImage, ciFilter: ciFilter)
    }

    private func getPoints() -> [CGPoint] {
        guard let nsPoints = OCRProcessor.nativeScan(originalImage) as? [NSValue] else {
            return []
        }
        let imgHeight = CGFloat(originalImage.size.height * originalImage.scale)
        let imgWidth = CGFloat(originalImage.size.width * originalImage.scale)
        var points: [CGPoint] = []
        nsPoints.forEach { (value) in
            let point = value.cgPointValue
            let realX = contentImageView.frame.width / imgWidth * point.x
            let realY = contentImageView.frame.height / imgHeight * point.y
            points.append(CGPoint(x: realX, y: realY))
        }
        return points
    }

    private func changeToOriImage() {
        processedImage = nil
        clippedImage = nil
        contentImageView.image = originalImage
    }

    private func changeToolbar(state: OCRState) {
        editorToolbar.isHidden = true
        clipToolbar.isHidden = true
        contrastToolbar.isHidden = true

        switch state {
        case .edit:
            editorToolbar.isHidden = false
        case .clip:
            clipToolbar.isHidden = false
            clipView.isHidden = false
        case .contrast:
            contrastToolbar.isHidden = false
        }
    }
}

extension OCRViewController {

    private func clipImage() {
        guard let points = clipView.cornerPoints, let image = originalImage else { return }
        var pts: [CGPoint] = []
        let imgHeight = CGFloat(image.size.height * image.scale)
        let imgWidth = CGFloat(image.size.width * image.scale)
        points.forEach { (point) in
            let realX = point.x / (contentImageView.frame.width / imgWidth)
            let realY = point.y / (contentImageView.frame.height / imgHeight)
            pts.append(CGPoint(x: realX, y: realY))
        }
        clippedImage = OCRProcessor.crop(with: image, area: pts)
        contentImageView.image = clippedImage
        clipView.isHidden = true
    }

    private func rotateImage() {
        var image: UIImage
        if let img = processedImage { //处理图片后再回来旋转
            processedImage = img.rotate(radians: -Float.pi / 2)
            clippedImage = processedImage!
            image = processedImage!
        } else if let img = clippedImage { //没有处理图片直接旋转
            clippedImage = img.rotate(radians: -Float.pi / 2)
            image = clippedImage!
        } else {
            return
        }

        contentImageView.image = image
    }

    private func exportImage() {

        let alertVC = UIAlertController(title: nil,
                                        message: nil,
                                        preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: "导出结果到文档", style: .default, handler: { (_) in
            self.startExportDoc()
        }))
        alertVC.addAction(UIAlertAction(title: "保存图片到本地", style: .default, handler: { (_) in
            self.startExportImage()
        }))
        alertVC.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { (_) in
            
        }))
        present(alertVC, animated: true, completion: nil)
    }

    private func setContrast(value: Float) {

        guard let ciFilter = preProcessedImageCtx?.ciFilter else { return }

        /** 暂时不用这些
         ciFilter.setValue(NSNumber(value: 2 * value), forKey: "inputSaturation")
         ciFilter.setValue(NSNumber(value: 2 * value - 1), forKey: "inputBrightness")
        */
        ciFilter.setValue(NSNumber(value: 2 * value), forKey: "inputContrast")

        let outputImage = ciFilter.outputImage
        let ciContext = CIContext(options: nil)

        guard let outp1mage = outputImage, let rect = outputImage?.extent else { return }
        let cgImgRef = ciContext.createCGImage(outp1mage, from: rect)

        guard let cg1mgRef = cgImgRef else { return }
        self.processedImage = UIImage(cgImage: cg1mgRef)
        self.contentImageView.image = self.processedImage
    }
}

extension OCRViewController {

    private func startExportImage() {
        SVProgressHUD.show(withStatus: "正在导出...")
        var image: UIImage
        if let img = processedImage {
            image = img
        } else if let img = clippedImage {
            image = img
        } else {
            image = originalImage
        }

        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc
    private func image(_: UIImage, didFinishSavingWithError error: NSError?, contextInfo info: Any) {
        SVProgressHUD.dismiss()
        if error != nil {
            SVProgressHUD.showError(withStatus: "保存失败!")
        } else {
            SVProgressHUD.showSuccess(withStatus: "保存成功!")
        }
    }

    private func startExportDoc() {
        SVProgressHUD.show(withStatus: "正在识别...")
        var image: UIImage
        if let img = processedImage {
            image = img
        } else if let img = clippedImage {
            image = img
        } else {
            image = originalImage
        }
        let imageData = image.jpegData(compressionQuality: 0.5)
        let base64String = imageData?.base64EncodedString()
    
        guard let imageString = base64String else {
            return
        }
        
        NetWorkService.reconize(image: imageString) { (result, error) in
            SVProgressHUD.dismiss()
            if let e = error {
                SVProgressHUD.showError(withStatus: e.localizedDescription)
                return
            }
            
            if let r = result {
                self.saveToNative(result: r)
            }
        }
    }

    private func saveToNative(result: String) {
        let alertController = UIAlertController(title: "",
                                                message: "导出",
                                                preferredStyle: .alert)
        alertController.addTextField { (tf) in
            tf.placeholder = "输入标题"
        }
        alertController.addAction(UIAlertAction(title: "取消",
                                                style: .cancel,
                                                handler: { (_) in
        }))
        alertController.addAction(UIAlertAction(title: "确认",
                                                style: .default,
                                                handler: { (ac) in
            let title = alertController.textFields?.first?.text ?? ""
            self.jumpToDetail(title: title, content: result)
        }))
        present(alertController, animated: true)
    }
    
    private func jumpToDetail(title: String, content: String) {
        var file: [String: String] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        file["title"] = title
        file["content"] = content.isEmpty ? "啥也没识别出来，可以换个体位再试试哟😅～" : content
        file["time"] = dateFormatter.string(from: Date())
        
        var array: [[String: String]] = []
        array.append(file)
        
        if var array = FileService.getFiles() {
            array.insert(file, at: 0)
            FileService.save(files: array)
        } else {
            FileService.save(files: array)
        }
        
        self.navigationController?.dismiss(animated: true, completion: nil)
        
        if let vc = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController {
            vc.selectedIndex = 1
            
            guard let fileVC = vc.viewControllers?.last as? UINavigationController else { return }
            
            let vc1 = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FileDetailViewController") as! FileDetailViewController
            vc1.content = content.isEmpty ? "啥也没识别出来😅～" : content
            vc1.index = 0
            fileVC.pushViewController(vc1, animated: true)
        }

        SVProgressHUD.showSuccess(withStatus: "保存成功!")
    }
}

extension UIImagePickerController {

    open override func popViewController(animated: Bool) -> UIViewController? {
        if viewControllers.count > 1 {
            return super.popViewController(animated: animated)
        } else {
            dismiss(animated: true, completion: nil)
            return viewControllers.first
        }
    }
}
