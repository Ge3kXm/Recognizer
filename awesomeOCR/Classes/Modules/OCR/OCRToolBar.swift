//
//  OCRToolBar.swift
//  DocsSDK
//
//  Created by maxiao on 2019/6/10.
//

import UIKit
import SnapKit
import RxCocoa
import RxSwift

/////////////////////////////////////////////////////////////////////
typealias OCRClipToolbarCallback = (OCRClipToolbar) -> Void
class OCRClipToolbar: UIView {

    private var cancelButton: UIButton!
    private var desLabel: UILabel!
    private var doneButton: UIButton!

    private var doneCallback: OCRClipToolbarCallback?
    private var cancelCallback: OCRClipToolbarCallback?

    init(doneCallback: OCRClipToolbarCallback?,
         cancelCallback: OCRClipToolbarCallback?) {
        super.init(frame: .zero)
        self.doneCallback = doneCallback
        self.cancelCallback = cancelCallback
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        // 31 35 41
        backgroundColor = UIColor(displayP3Red: 31/255.0,
                                  green: 35/255.0,
                                  blue: 41/255.0,
                                  alpha: 1)

        cancelButton = UIButton().construct({
            $0.setBackgroundImage(UIImage(named: "ocr_close"), for: .normal)
            $0.addTarget(self,
                         action: #selector(cancelButtonClick(sender:)),
                         for: .touchUpInside)
        })

        desLabel = UILabel().construct({
            $0.font = UIFont.systemFont(ofSize: 16)
            $0.textColor = .white
            $0.text = "剪裁"
            $0.textAlignment = .center
            $0.sizeToFit()
        })

        doneButton = UIButton().construct({
            $0.setBackgroundImage(UIImage(named: "ocr_done"), for: .normal)
            $0.addTarget(self,
                         action: #selector(doneButtonClick(sender:)),
                         for: .touchUpInside)
        })

        addSubview(cancelButton)
        addSubview(desLabel)
        addSubview(doneButton)

        cancelButton.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(14)
            $0.width.equalTo(24)
            $0.height.equalTo(24)
        }

        desLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(cancelButton)
        }

        doneButton.snp.makeConstraints {
            $0.right.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(14)
            $0.width.equalTo(24)
            $0.height.equalTo(24)
        }
    }

    @objc
    private func cancelButtonClick(sender: UIButton) {
        guard let callback = cancelCallback else { return }
        callback(self)
    }

    @objc
    private func doneButtonClick(sender: UIButton) {
        guard let callback = doneCallback else { return }
        callback(self)
    }
}

/////////////////////////////////////////////////////////////////////
typealias OCREditToolbarCallback = (OCREditToolbar) -> Void
class OCREditToolbar: UIView {

    private var cancelButton: UIButton!
    private var clipButton: UIButton!
    private var rotateButton: UIButton!
    private var contrastButton: UIButton!
    private var exportButton: UIButton!

    private var cancelCallback: OCREditToolbarCallback?
    private var clipCallback: OCREditToolbarCallback?
    private var rotateCallback: OCREditToolbarCallback?
    private var contrastCallback: OCREditToolbarCallback?
    private var exportCallback: OCREditToolbarCallback?

    init(cancelCallback: OCREditToolbarCallback?,
         clipCallback: OCREditToolbarCallback?,
         rotateCallback: OCREditToolbarCallback?,
         contrastCallback: OCREditToolbarCallback?,
         exportCallback: OCREditToolbarCallback?) {
        super.init(frame: .zero)
        self.cancelCallback = cancelCallback
        self.clipCallback = clipCallback
        self.rotateCallback = rotateCallback
        self.contrastCallback = contrastCallback
        self.exportCallback = exportCallback
        setupSubviews()
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        // 31 35 41
        backgroundColor = UIColor(red: 31/255.0, green: 35/255.0, blue: 41/255.0, alpha: 1)
        cancelButton = UIButton().construct({
            $0.setTitle("取消", for: .normal)
            $0.addTarget(self,
                         action: #selector(cancelButtonClick(sender:)),
                         for: .touchUpInside)
        })

        clipButton = UIButton().construct({
            $0.setBackgroundImage(UIImage(named: "ocr_crop_nor"), for: .normal)
            $0.setBackgroundImage(UIImage(named: "ocr_crop_press"), for: .highlighted)
            $0.addTarget(self,
                         action: #selector(clipButtonClick(sender:)),
                         for: .touchUpInside)
        })

        rotateButton = UIButton().construct({
            $0.setBackgroundImage(UIImage(named: "ocr_rotate_nor"), for: .normal)
            $0.setBackgroundImage(UIImage(named: "ocr_rotate_press"), for: .highlighted)
            $0.addTarget(self,
                         action: #selector(rotateButtonClick(sender:)),
                         for: .touchUpInside)
        })

        contrastButton = UIButton().construct({
            $0.setBackgroundImage(UIImage(named: "ocr_contrast_nor"), for: .normal)
            $0.setBackgroundImage(UIImage(named: "ocr_contrast_press"), for: .highlighted)
            $0.addTarget(self,
                         action: #selector(contrastButtonClick(sender:)),
                         for: .touchUpInside)
        })

        exportButton = UIButton().construct({
            $0.setTitle("导出", for: .normal)
            $0.setTitleColor(.white, for: .normal)
            $0.layer.cornerRadius = 2
            $0.backgroundColor = .darkGray
            $0.addTarget(self,
                         action: #selector(exportButtonClick(sender:)),
                         for: .touchUpInside)
        })

        addSubview(cancelButton)
        addSubview(clipButton)
        addSubview(rotateButton)
        addSubview(contrastButton)
        addSubview(exportButton)
    }

    private func setupLayout() {
        cancelButton.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(12)
            $0.width.equalTo(66)
            $0.height.equalTo(28)
        }

        rotateButton.snp.makeConstraints {
            $0.width.height.equalTo(24)
            $0.centerY.equalTo(cancelButton)
            $0.centerX.equalToSuperview()
        }

        clipButton.snp.makeConstraints {
            $0.right.equalTo(rotateButton.snp_left).offset(-30)
            $0.width.height.equalTo(24)
            $0.centerY.equalTo(rotateButton.snp_centerY)
        }

        contrastButton.snp.makeConstraints {
            $0.left.equalTo(rotateButton.snp_right).offset(30)
            $0.width.height.equalTo(24)
            $0.centerY.equalTo(rotateButton.snp_centerY)
        }

        exportButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.height.equalTo(28)
            $0.width.equalTo(66)
            $0.right.equalToSuperview().offset(-16)
        }
    }

    @objc
    private func cancelButtonClick(sender: UIButton) {
        guard let callback = cancelCallback else { return }
        callback(self)
    }

    @objc
    private func clipButtonClick(sender: UIButton) {
        guard let callback = clipCallback else { return }
        callback(self)
    }

    @objc
    private func rotateButtonClick(sender: UIButton) {
        guard let callback = rotateCallback else { return }
        callback(self)
    }

    @objc
    private func contrastButtonClick(sender: UIButton) {
        guard let callback = contrastCallback else { return }
        callback(self)
    }

    @objc
    private func exportButtonClick(sender: UIButton) {
        guard let callback = exportCallback else { return }
        callback(self)
    }
}

/////////////////////////////////////////////////////////////////////
typealias OCRContrastToolbarCallback = (OCRContrastToolbar) -> Void
typealias OCRContrastValueCallback   = (Float) -> Void
class OCRContrastToolbar: UIView {

    private var topContentView: UIView!
    private var bottomContentView: UIView!
    private var valueLabel: UILabel!
    private var slider: UISlider!
    private var cancelButton: UIButton!
    private var desLabel: UILabel!
    private var doneButton: UIButton!
    private var disposeBag = DisposeBag()

    private var doneCallback: OCRContrastToolbarCallback?
    private var cancelCallback: OCRContrastToolbarCallback?
    private var valueCallback: OCRContrastValueCallback?

    init(doneCallback: OCRContrastToolbarCallback?,
         cancelCallback: OCRContrastToolbarCallback?,
         valueCallback: OCRContrastValueCallback?) {
        super.init(frame: .zero)
        self.doneCallback = doneCallback
        self.cancelCallback = cancelCallback
        self.valueCallback = valueCallback
        setupSubviews()
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {

        topContentView = UIView().construct({
            $0.backgroundColor = .black
        })

        bottomContentView = UIView().construct({
            $0.backgroundColor = UIColor(red: 31/255.0, green: 35/255.0, blue: 41/255.0, alpha: 1)
        })

        valueLabel = UILabel().construct({
            $0.textColor = .white
            $0.font = UIFont.systemFont(ofSize: 14)
            $0.text = "0.50"
            $0.sizeToFit()
            $0.textAlignment = .center
        })

        slider = UISlider().construct({
            $0.thumbTintColor = .white
            $0.minimumTrackTintColor = .white
            $0.maximumTrackTintColor = .darkGray
            $0.value = 0.5
            $0.setValue(0.5, animated: false)
        })

        slider.rx.value.skip(1).subscribe(onNext: { [weak self] (value) in
            self?.valueLabel.text = String(format: "%.2f", value)
            guard let callback = self?.valueCallback else { return }
            callback(value)
        })
        .disposed(by: disposeBag)

        cancelButton = UIButton().construct({
            $0.setBackgroundImage(UIImage(named: "ocr_close"), for: .normal)
            $0.addTarget(self,
                         action: #selector(cancelButtonClick(sender:)),
                         for: .touchUpInside)
        })

        desLabel = UILabel().construct({
            $0.text = "对比度"
            $0.font = UIFont.systemFont(ofSize: 16)
            $0.textColor = .white
            $0.sizeToFit()
            $0.textAlignment = .center
        })

        doneButton = UIButton().construct({
            $0.setBackgroundImage(UIImage(named: "ocr_done"), for: .normal)
            $0.addTarget(self,
                         action: #selector(doneButtonClick(sender:)),
                         for: .touchUpInside)
        })

        addSubview(topContentView)
        addSubview(bottomContentView)

        topContentView.addSubview(valueLabel)
        topContentView.addSubview(slider)
        bottomContentView.addSubview(cancelButton)
        bottomContentView.addSubview(desLabel)
        bottomContentView.addSubview(doneButton)
    }

    private func setupLayout() {
        topContentView.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
            $0.height.equalTo(54)
        }

        bottomContentView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(topContentView.snp_bottom)
        }

        valueLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-45)
        }

        slider.snp.makeConstraints {
            $0.left.equalToSuperview().offset(20)
            $0.right.equalToSuperview().offset(-20)
            $0.height.equalTo(10)
            $0.center.equalToSuperview()
        }

        cancelButton.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(14)
            $0.width.equalTo(24)
            $0.height.equalTo(24)
        }

        desLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(cancelButton)
        }

        doneButton.snp.makeConstraints {
            $0.right.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(14)
            $0.width.equalTo(24)
            $0.height.equalTo(24)
        }
    }

    @objc
    private func cancelButtonClick(sender: UIButton) {
        guard let callback = cancelCallback else { return }
        callback(self)
    }

    @objc
    private func doneButtonClick(sender: UIButton) {
        guard let callback = doneCallback else { return }
        callback(self)
    }
}
