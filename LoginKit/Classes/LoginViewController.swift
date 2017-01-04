//
//  LoginViewController.swift
//  LoginKit
//
//  Created by Daniel Lozano Valdés on 12/8/16.
//  Copyright © 2016 danielozano. All rights reserved.
//

import UIKit

import Validator
import SkyFloatingLabelTextField

protocol LoginViewControllerDelegate: class {

    func didSelectLogin(_ viewController: UIViewController, email: String, password: String)
    func didSelectForgotPassword(_ viewController: UIViewController)
    func didSelectBack(_ viewController: UIViewController)

}

enum ValidationError: String, Error {

    case invalidEmail = "Email address is invalid"
    case passwordLength = "Password must be at least 8 characters"

    var message: String {
        return self.rawValue
    }

}

class LoginViewController: UIViewController, BackgroundMovable, KeyboardMovable {

    // MARK: - Properties

    weak var delegate: LoginViewControllerDelegate?

    var backgroundImage: UIImage?

    var loginAttempted = false

    var loginInProgress = false {
        didSet {
            loginButton.isEnabled = !loginInProgress
        }
    }

    // MARK: Keyboard movable
    var selectedField: UITextField?
    var offset: CGFloat = 0.0

    // MARK: Background Movable
    var movableBackground: UIView {
        get {
            return backgroundImageView
        }
    }

    // MARK: - Outlet's

    @IBOutlet var fields: Array<SkyFloatingLabelTextField> = []
    @IBOutlet weak var emailTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var passwordTextField: SkyFloatingLabelTextField!

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var backgroundImageView: UIImageView!

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setupValidation()
        customizeAppearance()
        initKeyboardMover()
        initBackgroundMover()
    }

    override func loadView() {
        self.view = viewFromNib()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        destroyKeyboardMover()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Setup

    func customizeAppearance() {
        if let backgroundImage = backgroundImage {
            backgroundImageView.image = backgroundImage
        }
    }

    // MARK: - Action's

    @IBAction func didSelectBack(_ sender: AnyObject) {
        delegate?.didSelectBack(self)
    }

    @IBAction func didSelectLogin(_ sender: AnyObject) {
        loginAttempted = true
        validateFields {
            delegate?.didSelectLogin(self, email: "", password: "")
        }
    }

    @IBAction func didSelectForgotPassword(_ sender: AnyObject) {
        delegate?.didSelectForgotPassword(self)
    }

}

// MARK: - Validation

extension LoginViewController {

    var emailRule: ValidationRulePattern {
        return ValidationRulePattern(pattern: EmailValidationPattern.standard, error: ValidationError.invalidEmail)
    }

    var lengthRule: ValidationRuleLength {
        return ValidationRuleLength(min: 8, error: ValidationError.passwordLength)
    }

    func setupValidation() {
        var emailRules = ValidationRuleSet<String>()
        emailRules.add(rule: emailRule)
        setupValidationOn(field: emailTextField, rules: emailRules)

        var passwordRules = ValidationRuleSet<String>()
        passwordRules.add(rule: lengthRule)
        setupValidationOn(field: passwordTextField, rules: passwordRules)
    }

    func setupValidationOn(field: SkyFloatingLabelTextField, rules: ValidationRuleSet<String>) {
        field.validationRules = rules
        field.validateOnInputChange(enabled: true)
        field.validationHandler = validationHandlerFor(field: field)
    }

    func validationHandlerFor(field: SkyFloatingLabelTextField) -> ((ValidationResult) -> Void) {
        return { result in
            switch result {
            case .valid:
                guard self.loginAttempted == true else {
                    break
                }
                field.errorMessage = nil
            case .invalid(let errors):
                guard self.loginAttempted == true else {
                    break
                }
                if let errors = errors as? [ValidationError] {
                    field.errorMessage = errors.first?.message
                }
            }
        }
    }

    func validateFields(success: () -> Void) {
        var errorFound = false
        for field in fields {
            let result = field.validate()
            switch result {
            case .valid:
                field.errorMessage = nil
            case .invalid(let errors):
                errorFound = true
                if let errors = errors as? [ValidationError] {
                    field.errorMessage = errors.first?.message
                }
            }
        }
        if !errorFound {
            success()
        }
    }

}

// MARK: - UITextField Delegate

extension LoginViewController : UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        selectedField = textField
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        selectedField = nil
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        let nextResponder = view.viewWithTag(nextTag) as UIResponder!

        if nextResponder != nil {
            nextResponder?.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            didSelectLogin(self)
        }
        
        return false
    }
    
}
