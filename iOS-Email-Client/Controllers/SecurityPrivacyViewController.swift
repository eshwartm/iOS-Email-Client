//
//  SecurityPrivacyViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 12/6/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import LocalAuthentication
import PasscodeLock

class SecurityPrivacyViewController: UITableViewController {

    struct PrivacyOption {
        var label: Privacy
        var pick: String?
        var isOn: Bool?
        var hasFlow: Bool
        var detail: String?
        var isEnabled = true
    }
    
    enum Privacy {
        case pincode
        case changePin
        case autoLock
        case biometric
        case twoFactor
        case receipts
        
        var description: String {
            switch(self) {
            case .pincode:
                return String.localize("USE_PIN")
            case .changePin:
                return String.localize("CHANGE_PIN")
            case .autoLock:
                return String.localize("AUTO_LOCK")
            case .twoFactor:
                return String.localize("TWO_FACTOR")
            case .receipts:
                return String.localize("READ_RECEIPTS")
            case .biometric:
                return ""
            }
        }
    }
    
    var isPinControl = false
    var options = [PrivacyOption]()
    var defaults = CriptextDefaults()
    var generalData: GeneralSettingsData!
    var myAccount: Account!
    
    override func viewDidLoad() {
        navigationItem.title = String.localize("PRIVACY_AND_SECURITY")
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        let nib = UINib(nibName: "SettingsOptionTableCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "privacycell")
        tableView.estimatedRowHeight = UITableView.automaticDimension
        if isPinControl {
            initializePinOptions()
        } else {
            initializePrivacyOptions()
        }
        applyTheme()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.toggleOptions()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        tableView.backgroundColor = .clear
        self.view.backgroundColor = theme.overallBackground
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
    
    func initializePinOptions() {
        let pinCode = PrivacyOption(label: .pincode, pick: nil, isOn: true, hasFlow: false, detail: String.localize("PIN_DETAIL"), isEnabled: true)
        let changePin = PrivacyOption(label: .changePin, pick: nil, isOn: nil, hasFlow: true, detail: nil, isEnabled: true)
        let autolock = PrivacyOption(label: .autoLock, pick: "1 minute", isOn: nil, hasFlow: false, detail: nil, isEnabled: true)
        options.append(pinCode)
        options.append(changePin)
        options.append(autolock)
        if (biometricType != .none) {
            let biometrics = PrivacyOption(label: .biometric, pick: nil, isOn: true, hasFlow: false, detail: nil, isEnabled: true)
            options.append(biometrics)
        }
        toggleOptions()
    }
    
    func initializePrivacyOptions() {
        let twoFactor = PrivacyOption(label: .twoFactor, pick: nil, isOn: true, hasFlow: false, detail: String.localize("TWO_FACTOR_DETAIL"), isEnabled: true)
        let receipts = PrivacyOption(label: .receipts, pick: nil, isOn: true, hasFlow: false, detail: String.localize("RECEIPTS_DETAIL"), isEnabled: true)
        options.append(receipts)
        options.append(twoFactor)
        toggleOptions()
    }
    
    func toggleOptions() {
        self.options = options.map { (option) -> PrivacyOption in
            var newOption = option
            switch(option.label) {
            case .pincode:
                newOption.isOn = defaults.hasPIN
            case .changePin:
                newOption.isEnabled = defaults.hasPIN
            case .autoLock:
                newOption.isEnabled = defaults.hasPIN
                newOption.pick = defaults.lockTimer
            case .twoFactor:
                newOption.isEnabled = !generalData.loading2FA
                newOption.isOn = generalData.isTwoFactor
            case .receipts:
                newOption.isEnabled = !generalData.loadingReceipts
                newOption.isOn = generalData.hasEmailReceipts
            case .biometric:
                newOption.isEnabled = defaults.hasPIN && biometricType != .none
                newOption.isOn = defaults.hasFaceID || defaults.hasFingerPrint
            }
            return newOption
        }
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "privacycell") as! SettingsOptionCell
        let option = options[indexPath.row]
        cell.fillFields(option: option)
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        switch(option.label) {
        case .biometric:
            cell.optionTextLabel.text = biometricType == .faceID ? String.localize("UNLOCK_FACE") : String.localize("UNLOCK_TOUCH")
        default:
            break
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let option = options[indexPath.row]
        guard option.isEnabled else {
            return
        }
        switch(option.label) {
        case .pincode:
            let isOn = !(option.isOn ?? false)
            guard isOn else {
                self.defaults.removePasscode()
                self.toggleOptions()
                return
            }
            self.presentPasscodeController(state: .set)
        case .changePin:
            self.presentPasscodeController(state: .change)
        case .autoLock:
            self.openPicker()
        case .receipts:
            let isOn = !(option.isOn ?? false)
            self.setReadReceipts(enable: isOn)
        case .twoFactor:
            let isOn = !(option.isOn ?? false)
            self.setTwoFactor(enable: isOn)
        case .biometric:
            let isOn = !(option.isOn ?? false)
            switch(self.biometricType) {
            case .none:
                break
            case .touchID:
                self.defaults.fingerprintUnlock = isOn
            case .faceID:
                self.defaults.faceUnlock = isOn
            }
            self.toggleOptions()
        }
        
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }
    
    func presentPasscodeController(state: PasscodeLockViewController.LockState) {
        let configuration = PasscodeConfig()
        let passcodeVC = CustomPasscodeViewController(state: state, configuration: configuration, animateOnDismiss: true)
        self.navigationController?.pushViewController(passcodeVC, animated: true)
    }
    
    func openPicker(){
        let pickerPopover = OptionsPickerUIPopover()
        pickerPopover.options = [
            PIN.time.immediately.rawValue,
            PIN.time.oneminute.rawValue,
            PIN.time.fiveminutes.rawValue,
            PIN.time.fifteenminutes.rawValue,
            PIN.time.onehour.rawValue,
            PIN.time.oneday.rawValue
        ]
        pickerPopover.onComplete = { [weak self] option in
            if let stringValue = option {
                self?.defaults.lockTimer = stringValue
                self?.defaults.lockTimer = stringValue
                self?.toggleOptions()
            }
        }
        self.presentPopover(popover: pickerPopover, height: 295)
    }
    
    func setReadReceipts(enable: Bool){
        let initialValue = self.generalData.hasEmailReceipts
        self.generalData.hasEmailReceipts = enable
        self.generalData.loadingReceipts = true
        self.toggleOptions()
        APIManager.setReadReceipts(enable: enable, token: myAccount.jwt) { (responseData) in
            guard case .Success = responseData else {
                self.showAlert(String.localize("SOMETHING_WRONG"), message: String.localize("UNABLE_RECEIPTS"), style: .alert)
                self.generalData.hasEmailReceipts = initialValue
                self.toggleOptions()
                return
            }
            self.toggleOptions()
        }
    }
    
    func setTwoFactor(enable: Bool){
        guard !enable || generalData.recoveryEmailStatus == .verified else {
            presentRecoveryPopover()
            return
        }
        let initialValue = self.generalData.isTwoFactor
        self.generalData.isTwoFactor = enable
        self.generalData.loading2FA = true
        APIManager.setTwoFactor(isOn: enable, token: myAccount.jwt) { (responseData) in
            self.generalData.loading2FA = false
            if case .Conflicts = responseData {
                self.presentRecoveryPopover()
                self.toggleOptions()
                return
            }
            guard case .Success = responseData else {
                self.showAlert(String.localize("SOMETHING_WRONG"), message: "\(String.localize("UNABLE_TO")) \(enable ? String.localize("ENABLE") : String.localize("DISABLE")) \(String.localize("TWO_FACTOR_RETRY"))", style: .alert)
                self.generalData.isTwoFactor = initialValue
                self.toggleOptions()
                return
            }
            if (self.generalData.isTwoFactor) {
                self.presentTwoFactorPopover()
            }
            self.toggleOptions()
        }
    }
    
    func presentRecoveryPopover() {
        let popover = GenericAlertUIPopover()
        let attributedRegular = NSMutableAttributedString(string: String.localize("TO_ENABLE_2FA_1"), attributes: [NSAttributedString.Key.font: Font.regular.size(15)!])
        let attributedSemibold = NSAttributedString(string: String.localize("TO_ENABLE_2FA_2"), attributes: [NSAttributedString.Key.font: Font.semibold.size(15)!])
        attributedRegular.append(attributedSemibold)
        popover.myTitle = String.localize("RECOVERY_NOT_SET")
        popover.myAttributedMessage = attributedRegular
        popover.myButton = String.localize("GOT_IT")
        self.presentPopover(popover: popover, height: 310)
    }
    
    func presentTwoFactorPopover() {
        let popover = GenericAlertUIPopover()
        popover.myTitle = String.localize("2FA_ENABLED")
        popover.myMessage = String.localize("NEXT_TIME_2FA")
        popover.myButton = String.localize("GOT_IT")
        self.presentPopover(popover: popover, height: 263)
    }
    
    enum BiometricType {
        case none
        case touchID
        case faceID
    }
    
    var biometricType: BiometricType {
        get {
            let context = LAContext()
            var error: NSError?
            
            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                print(error?.localizedDescription ?? "")
                return .none
            }
            
            if #available(iOS 11.0, *) {
                switch context.biometryType {
                case .none:
                    return .none
                case .touchID:
                    return .touchID
                case .faceID:
                    return .faceID
                @unknown default:
                    return .none
                }
            } else {
                return  .touchID
            }
        }
    }
}

extension SecurityPrivacyViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let nav = self.navigationController else {
            return false
        }
        if(nav.viewControllers.count > 1){
            return true
        }
        return false
    }
}
