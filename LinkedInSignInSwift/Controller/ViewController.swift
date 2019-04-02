
import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var imgViewProfilePic: UIImageView!
    @IBOutlet var lblFirstName: UILabel!
    @IBOutlet var lblLastName: UILabel!
    @IBOutlet var lblEmailAddress: UILabel!
    @IBOutlet var btnSign: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func btnSignIn(_ sender: Any) {
        if !btnSign.isSelected{
            let ctrl = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LinkedInAuthorizationVC") as! LinkedInAuthorizationVC
            ctrl.delegate = self
            self.present(ctrl, animated: true, completion: nil)
        }else{
            imgViewProfilePic.image = nil
            lblFirstName.text = ""
            lblLastName.text = ""
            lblEmailAddress.text = ""
            btnSign.isSelected = false
        }
    }
    
    func setUpUserProfile(userProfile:[String:AnyHashable]?){
        lblFirstName.text = userProfile?["firstName"] as? String
        lblLastName.text = userProfile?["lastName"] as? String
        lblEmailAddress.text = userProfile?["email"] as? String
        do{
            if let url = URL.init(string: userProfile?["profilePicture"] as! String){
                let data = try Data(contentsOf: url)
                imgViewProfilePic.image = UIImage(data: data)
            }
        }catch{
            print(error.localizedDescription)
        }
    }
}

extension ViewController:LinkedInAuthorizationVCDelegate{
    func retriveLinkedInUserProfile(userProfile: [String : AnyHashable]?) {
        setUpUserProfile(userProfile: userProfile)
        btnSign.isSelected = true
    }
}

