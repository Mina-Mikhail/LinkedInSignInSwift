
import UIKit
import WebKit

protocol LinkedInAuthorizationVCDelegate:class {
    func retriveLinkedInUserProfile(userProfile: [String:AnyHashable]?)
}

class LinkedInAuthorizationVC: UIViewController {

    // MARK: -IBOutlet Properties
    
    @IBOutlet weak var viewForWebView: UIView!
    
    //MARK: - Vars and Objects
    
    var wbView:WKWebView?
    weak var delegate:LinkedInAuthorizationVCDelegate?
    var dicUserProfile:[String:String] = [:]
    
    // MARK: - Constants
    
    let linkedInKey = "81ph76a9lu4j29"
    let linkedInSecret = "0GgdmOXLu7iHNmso"
    let callBackURL = "https://com.elsner.linkedin.oauth/oauth"
    let authorizationEndPoint = "https://www.linkedin.com/oauth/v2/authorization"
    let accessTokenEndPoint = "https://www.linkedin.com/oauth/v2/accessToken"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        wbView = WKWebView.init(frame: CGRect(x: 0, y: 0, width: viewForWebView.frame.size.width, height: viewForWebView.frame.size.height))
        viewForWebView.addSubview(wbView!)
        wbView?.navigationDelegate = self
        clearWebViewDataStore()
    }
    
    //MARK: - Other Method
    
    func clearWebViewDataStore(){
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                print("[WebCacheCleaner] Record \(record) deleted")
            }
            self.startAuthorization()
        }
    }
    
    func startAuthorization(){
        // Specify the response type which should always be "code".
        let responseType = "code"
        
        // Set the redirect URL. Adding the percent escape characthers is necessary.
        let redirectURL = callBackURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)
        
        // Create a random string based on the time intervale (it will be in the form linkedin12345679).
        let state = "linkedin\(Date().timeIntervalSince1970)"
        
        // Set preferred scope.
        let scope = "r_liteprofile,r_emailaddress"
        
        // Create the authorization URL string.
        var authorizationURL = "\(authorizationEndPoint)?"
        authorizationURL += "response_type=\(responseType)&"
        authorizationURL += "client_id=\(linkedInKey)&"
        authorizationURL += "redirect_uri=\(redirectURL!)&"
        authorizationURL += "state=\(state)&"
        authorizationURL += "scope=\(scope)"

        // Create a URL request and load it in the web view.
        let url:URL = URL(string: authorizationURL)!
        let request = URLRequest(url: url)
        wbView?.load(request)
    }
    
    func requestForAccessToken(authorizationCode: String) {
        
        let grantType = "authorization_code"
        
        let redirectURL = callBackURL.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.alphanumerics)
        
        // Set the POST parameters.
        var postParams = "grant_type=\(grantType)&"
        postParams += "code=\(authorizationCode)&"
        postParams += "redirect_uri=\(redirectURL!)&"
        postParams += "client_id=\(linkedInKey)&"
        postParams += "client_secret=\(linkedInSecret)"
        
        // Convert the POST parameters into a NSData object.
        let postData = postParams.data(using: String.Encoding.utf8)
        
        // Initialize a mutable URL request object using the access token endpoint URL string.
        let request = NSMutableURLRequest(url: NSURL(string: accessTokenEndPoint)! as URL)
        
        // Indicate that we're about to make a POST request.
        request.httpMethod = "POST"
        
        // Set the HTTP body using the postData object created above.
        request.httpBody = postData
        
        // Add the required HTTP header field.
        request.addValue("application/x-www-form-urlencoded;", forHTTPHeaderField: "Content-Type")
        
        // Initialize a NSURLSession object.
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        // Make the request.
        let task: URLSessionDataTask = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            // Get the HTTP status code of the request.
            let statusCode = (response as! HTTPURLResponse).statusCode
            
            if statusCode == 200 {
                // Convert the received JSON data into a dictionary.
                do {
                    let dataDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
                    let accessToken = (dataDictionary as! [String:Any]) ["access_token"] as! String
                    self.requestForLiteProfile(accessToken: accessToken)
                }
                catch {
                    print("Could not convert JSON data into a dictionary.")
                }
            }
        }
        task.resume()
    }
    
    func requestForLiteProfile(accessToken:String){
        
        // Initialize a mutable URL request object.
        let targetUrl = "https://api.linkedin.com/v2/me?projection=(id,firstName,lastName,profilePicture(displayImage~:playableStreams))"
        let url = URL.init(string: targetUrl)
        var request = URLRequest.init(url: url!)
        
        // Indicate that this is a GET request.
        request.httpMethod = "GET"
        
        // Add the access token as an HTTP header field.
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // Initialize a URLSession object.
        let session = URLSession.init(configuration: .default)
        
        // Make the request.
        let task = session.dataTask(with: request) { (data, response, error) in
            let statusCode = (response as! HTTPURLResponse).statusCode
            if statusCode == 200 {
                do {
                    let dataDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
                    if let jsonDic = dataDictionary as? [String:AnyHashable]{
                        self.setUpUserProfile(userProfile: jsonDic)
                    }
                    self.requestForEmailAddress(accessToken: accessToken)
                }catch{
                    print("Could not convert JSON data into a dictionary.")
                }
            }
        };task.resume()
    }
    
    func requestForEmailAddress(accessToken:String){
        
        // Initialize a mutable URL request object.
        let targetUrl = "https://api.linkedin.com/v2/emailAddress?q=members&projection=(elements*(handle~))"
        let url = URL.init(string: targetUrl)
        var request = URLRequest.init(url: url!)
        
        // Indicate that this is a GET request.
        request.httpMethod = "GET"
        
        // Add the access token as an HTTP header field.
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // Initialize a URLSession object.
        let session = URLSession.init(configuration: .default)
        
        // Make the request.
        let task = session.dataTask(with: request) { (data, response, error) in
            let statusCode = (response as! HTTPURLResponse).statusCode
            if statusCode == 200 {
                do {
                    let dataDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
                    DispatchQueue.main.async {
                        self.dismiss(animated: true, completion: {
                            if let jsonDic = dataDictionary as? [String:AnyHashable]{
                                self.setUpUserEmail(userEmail: jsonDic)
                            }
                        })
                    }
                }catch{
                    print("Could not convert JSON data into a dictionary.")
                }
            }
        };task.resume()
    }
    
    func setUpUserProfile(userProfile:[String:AnyHashable]){
        
        dicUserProfile["firstName"] = ""
        dicUserProfile["lastName"] = ""
        dicUserProfile["profilePicture"] = ""

        if let firstName = userProfile["firstName"] as? [String:AnyHashable]{
            if let localized = firstName["localized"] as? [String:AnyHashable]{
                if let en_US = localized["en_US"] as? String{
                    dicUserProfile["firstName"] = en_US
                }
            }
        }
        
        if let lastName = userProfile["lastName"] as? [String:AnyHashable]{
            if let localized = lastName["localized"] as? [String:AnyHashable]{
                if let en_US = localized["en_US"] as? String{
                    dicUserProfile["lastName"] = en_US
                }
            }
        }
        
        if let profilePicture = userProfile["profilePicture"] as? [String:AnyHashable]{
            if let displayImage = profilePicture["displayImage~"] as? [String:AnyHashable]{
                if let elements = displayImage["elements"] as? [[String:AnyHashable]]{
                    if elements.count > 0{
                        if let identifiers = elements.first?["identifiers"] as? [[String:AnyHashable]]{
                            if identifiers.count>0{
                                if let pictureUrl = identifiers.first?["identifier"] as? String{
                                    dicUserProfile["profilePicture"] = pictureUrl
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func setUpUserEmail(userEmail:[String:AnyHashable]){
        dicUserProfile["email"] = ""
        
        if let elements = userEmail["elements"] as? [[String:AnyHashable]]{
            if elements.count>0{
                if let handle = elements.first?["handle~"] as? [String:AnyHashable]{
                    if let emailAddress = handle["emailAddress"] as? String{
                        dicUserProfile["email"] = emailAddress
                    }
                }
            }
        }
        
        self.delegate?.retriveLinkedInUserProfile(userProfile: self.dicUserProfile)
    }
    
    //MARK: - Action Method
    @IBAction func onClosePress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onReloadPress(_ sender: Any) {
        startAuthorization()
    }
}

extension LinkedInAuthorizationVC: WKUIDelegate,WKNavigationDelegate{
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    
        let request = navigationAction.request
        let url = request.url!
    
        if request.url?.host == "com.elsner.linkedin.oauth" {
            if url.absoluteString.range(of: "code") != nil
            {
                let urlParts = url.absoluteString.components(separatedBy: "?")
                let code = urlParts[1].components(separatedBy: "=")[1]
                
                requestForAccessToken(authorizationCode: code)
            }
        }
        decisionHandler(WKNavigationActionPolicy.allow)
    }
    
}
