import Foundation
import FoundationNetworking

struct MyClaims: Claims {
                 var iss: String
                 var  aud: String
                 var  exp: Date  
                 var iat: Date 
                 var scope: String}

public extension String {
    @discardableResult
    func shell(_ args: String...) -> String
    {
        let (task,pipe) = (Process(),Pipe())
        task.executableURL = URL(fileURLWithPath: self)
        (task.arguments,task.standardOutput) = (args,pipe)
        do    { try task.run() }
        catch { print("Unexpected error: \(error).") }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: String.Encoding.utf8) ?? ""
    }
}
public func GCEGetNotebookName()->(String,String){
 
var notebookName:String = ""
var notebookFileid:String = ""
let urllist = URL(string: "http://172.28.0.2:9000/api/sessions")
var request = URLRequest(url: urllist!)
request.httpMethod = "GET"
request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type: text/html; charset=utf-8")
let semaphorel = DispatchSemaphore(value: 0)
let taskl = URLSession.shared.dataTask(with: request) {
  data, response, error in
    // Do something
      if let data = data{     
if let ArrayDictionary = try? JSONSerialization.jsonObject(with: 
 data, options: []) as? [[String: Any ]] {  
   notebookName = ArrayDictionary[0]["name"] as! String
   notebookFileid = ArrayDictionary[0]["path"] as! String
                                         }
    }    
    if let httpResponse = response as? HTTPURLResponse {
    print(httpResponse.statusCode)
    }
    semaphorel.signal()
  }
taskl.resume()
 semaphorel.wait() 
 return (notebookName,notebookFileid)
}

func GCEGetAccessToken(privateKey: Data, emailName: String, signedJWT: String)->Data
{
let debugMyCode:Bool = true
let semaphore = DispatchSemaphore(value: 0)
let parameters: [String: String] = [
    "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
    "assertion":  signedJWT]

let url = URL(string: "https://oauth2.googleapis.com/token")

var request = URLRequest(url: url!)
request.httpMethod = "POST"

request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type: text/html; charset=utf-8") 



request.httpBody = parameters
    .map { (key, value) in
        return "\(key)=\(value)"
    }
    .joined(separator: "&")
    .data(using: .utf8)




var dataReturned:Data = Data()

let task = URLSession.shared.dataTask(with: request) { 

  data, response, error in
    // Do something
      if let data = data {      
      dataReturned = data}   
                                                                   
    if let httpResponse = response as? HTTPURLResponse {
    if (debugMyCode) {print(httpResponse.statusCode)}
    }
    semaphore.signal()
  
} // URL
task.resume()
 semaphore.wait()
 return dataReturned
}

func GCEGetFile(fileid: String,  authorizationToken: String) -> Data
{
let urllistdown = URL(string: "https://www.googleapis.com/drive/v3/files/" + fileid + "?alt=media")
   var request = URLRequest(url: urllistdown!)
   request.httpMethod = "GET"
   var downloadedData:Data = Data()
   let authorizationTokenWithBearerString = "Bearer " + authorizationToken
   request.setValue(authorizationTokenWithBearerString, forHTTPHeaderField: "Authorization") 
  
   let semaphoredown  = DispatchSemaphore(value: 0)
   let taskdown = URLSession.shared.dataTask(with: request) { 
   data, response, error in
    // Do something
      if let data = data{ downloadedData = data}
      if let httpResponse = response as? HTTPURLResponse {
      print(httpResponse.statusCode)
           }
    semaphoredown.signal()
    }//url
   taskdown.resume()
   semaphoredown.wait()
   return downloadedData
 }// end of function 


 func GCEGAT(myjson: [String:String])->String {





//
let ce = myjson["client_email"]!
let myClaims =  MyClaims(iss: ce,
                 aud: "https://oauth2.googleapis.com/token",
                 exp: Date(timeIntervalSinceNow:3600),
                 iat: Date(timeIntervalSinceNow:0),
                 scope: "https://www.googleapis.com/auth/drive")

let myheader = Header(typ:"JWT")

var jwt = JWT(header: myheader, 
claims: myClaims)




let secret:Data=myjson["private_key"]!.data(using: .utf8)!


let signedJWT:String = try! jwt.sign(using: .rs256(privateKey: secret))

let dataReturned = GCEGetAccessToken(privateKey: secret,emailName: ce, signedJWT: signedJWT)

var myjsonToken: [String: String] = [:]
if let jsonToken1 = try? JSONSerialization.jsonObject(with: 
 dataReturned, options: []) as? [String: Any   ] {
for (key,value) in jsonToken1 {
    //print("key=  \(key) value = \(value)")
    //print("type \(type(of: value))")
    if (value is String) {myjsonToken[key] = (value as! String)}
    if (value           is NSNumber) {myjsonToken[key] = String((value as! Int     ))}
}
}

let authorizationTokenValue:String=myjsonToken["access_token"]! 
return authorizationTokenValue
}

func GCEWriteFileLocal(name: String, dd: Data)->String
{
let path = FileManager.default.currentDirectoryPath
let pathNBn = path.appendingPathComponent(name)
let URLpathNBn = URL(fileURLWithPath: pathNBn) 
do {
     try dd.write(to: URLpathNBn, options: .atomic)
   }
catch {print(error)}
return "OK"
}


func  GCEReadDirectory(authorizationToken: String, searchName:String)->[[String:String]]
{let query = "mimeType = \'application/vnd.google-apps.folder\' and name contains \'"+searchName+"\'"
//print(query)
let URLString = "https://www.googleapis.com/drive/v3/files?fields=kind,incompleteSearch,files(kind,id,name,mimeType,modifiedTime)&q=\(query)"
  //print(URLString)
  let encodedURL = URLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
  let urllist =  URL(string: encodedURL!)
  var request = URLRequest(url: urllist!)

//print("TRY REQUEST")
//print("REQUEST OK")
request.httpMethod = "GET"
let authorizationTokenWithBearerString = "Bearer " +  authorizationToken
request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type: text/html; charset=utf-8")
request.setValue(authorizationTokenWithBearerString, forHTTPHeaderField: "Authorization") 
//print("\(request.httpMethod ?? "") \(String(describing:request.url))")
 //       print("HEADERS \n \(String(describing:request.allHTTPHeaderFields))")

let semaphorel = DispatchSemaphore(value: 0)
//var filelistDictionary : [String:Any] = [:]
//var filelistArray: [Any] = []
var filelistArrayDictionary: [[String:String]] = []

let taskl = URLSession.shared.dataTask(with: request) {
  data, response, error in
    // Do something
    if let httpResponse = response as? HTTPURLResponse {
    print(httpResponse.statusCode)
    }
      if let data = data{
     
if let filelistDictionary = try? JSONSerialization.jsonObject(with: 
 data, options: []) as? [String: Any   ] {
for (key,value) in filelistDictionary {
    //print("key=  \(key) value = \(value)")
    //print("type \(type(of: value))")
    if value is Array<Any> {
                           //print("Array key = \(key)")
                            if let filelistArray = filelistDictionary[key]{
                            //print("Type \(type(of: filelistArray))")
                            //print(filelistArray)
                            filelistArrayDictionary = filelistArray as!  [[String:String]]
                             //print(filelistArrayDictionary)
                             
                           }
}
       }
//
    } 
    if let httpResponse = response as? HTTPURLResponse {
    print(httpResponse.statusCode)
    }
    semaphorel.signal()
  }}
taskl.resume()
 semaphorel.wait()

 return filelistArrayDictionary
 }


func GCECreateFolder(parentfolderid: String, NotebookName: String, authorizationToken: String) -> String
{let urlu = URL(string: "https://www.googleapis.com/drive/v3/files?")
var request = URLRequest(url: urlu!)
var mylocation = ""
var myFolderId = ""
request.httpMethod = "POST"
let metaData: [String: Any] = [
    "name": NotebookName,
    "parents":  [parentfolderid],
    "mimeType": "application/vnd.google-apps.folder"
]
let authorizationTokenWithBearerString = "Bearer " + authorizationToken
let jsonMetaData = try? JSONSerialization.data(withJSONObject: metaData) 
request.setValue("application/json", forHTTPHeaderField: "Content-Type") 
request.setValue(authorizationTokenWithBearerString, forHTTPHeaderField: "Authorization") 
request.setValue("\(jsonMetaData!.count)", forHTTPHeaderField: "Content-Length")

request.httpBody = jsonMetaData!


let semaphoreupload = DispatchSemaphore(value: 0)
let taskupload = URLSession.shared.dataTask(with: request) { 
  data, response, error in
    // Do something
      if let data = data  {
         if let filelistDictionary = try? JSONSerialization.jsonObject(with: 
               data, options: []) as? [String: String   ] {
               
               myFolderId = filelistDictionary["id"]!}
              
      }
      if let httpResponse = response as? HTTPURLResponse {
      //print(httpResponse.statusCode)
      if let location = httpResponse.allHeaderFields["Location"] as? String
         {mylocation = location}        
      }
    semaphoreupload.signal()
}//url
   taskupload.resume()
   semaphoreupload.wait()
   return myFolderId
}



func GCELocalFileRead(atPath: String)->Data
{
var newdd: Data=Data()
let path = FileManager.default.currentDirectoryPath
let pathNBt = path.appendingPathComponent(atPath)
let URLpathNBt = URL(fileURLWithPath: pathNBt) 
do {
     try newdd = Data(contentsOf: URLpathNBt)
   }
catch {print(error)}
return newdd
}
func GCEPostUpload(name: String, folderid: String, authCode: String, uploadData: Data)->String
{
  var mylocation: String = ""
var myFolderId: String = ""
let urlu = URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable")
var request = URLRequest(url: urlu!)

request.httpMethod = "POST"
let metaData: [String: Any] = [
    "name": name,
    "parents":  [folderid]
]
let jsonMetaData = try? JSONSerialization.data(withJSONObject: metaData) 
request.setValue("application/json", forHTTPHeaderField: "Content-Type") 
request.setValue("Bearer "+authCode, forHTTPHeaderField: "Authorization") 
request.setValue("\(jsonMetaData!.count)", forHTTPHeaderField: "Content-Length")
request.setValue("image/jpeg", forHTTPHeaderField: "X-Upload-Content-Type")
request.setValue("\(uploadData.count)", forHTTPHeaderField: "X-Upload-Content-Length")
request.httpBody = jsonMetaData!



let semaphoreupload = DispatchSemaphore(value: 0)
let taskupload = URLSession.shared.dataTask(with: request) { 
  data, response, error in
    // Do something
      if let data = data {
        //print(dataString)       
         if let filelistDictionary = try? JSONSerialization.jsonObject(with: 
               data, options: []) as? [String: String   ] {               
               myFolderId = filelistDictionary["id"]!}
              
      }
           
      if let httpResponse = response as? HTTPURLResponse {
      //print(httpResponse.statusCode)
      for (a,b) in httpResponse.allHeaderFields {
                                                 //print(a,b)
                                                }
      if let location = httpResponse.allHeaderFields["Location"] as? String
          {mylocation = location}     
      }
    semaphoreupload.signal()
}//url
   taskupload.resume()
   semaphoreupload.wait()

//print ("Location = \(mylocation) Folder = \(myFolderId)")
return mylocation
}
func GCEPut (location: String, newdd: Data)->Data
{


//*
let urlup = URL(string: location)
var request = URLRequest(url: urlup!)
request.httpMethod = "PUT"
request.setValue("\(newdd.count)", forHTTPHeaderField: "Content-Length")
request.httpBody = newdd
var returnData:Data = Data()
//                   
let semaphoreuploadput = DispatchSemaphore(value: 0)
let taskuploadput = URLSession.shared.dataTask(with: request) { 
  data, response, error in
    // Do something
      if let data = data {returnData = data}
    
      if let httpResponse = response as? HTTPURLResponse {
      print(httpResponse.statusCode)
      
      }
    semaphoreuploadput.signal()
}//url
   taskuploadput.resume()
   semaphoreuploadput.wait()
return returnData
}


func GCEReadDirectoryforFiles(authorizationToken: String, searchName: String,folder: String)->[[String:String]]
{let query = "name contains \'" + searchName + "\' and \'"  + folder + "\' in parents" 
let URLString = "https://www.googleapis.com/drive/v3/files?fields=kind,incompleteSearch,files(kind,id,name,mimeType,modifiedTime)&q=\(query)"
  //print(URLString)
  let encodedURL = URLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
  let urllist =  URL(string: encodedURL!)
//print("TRY REQUEST")
var request = URLRequest(url: urllist!)
//print("REQUEST OK")
request.httpMethod = "GET"
let authorizationTokenWithBearerString = "Bearer " +  authorizationToken
request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type: text/html; charset=utf-8")
request.setValue(authorizationTokenWithBearerString, forHTTPHeaderField: "Authorization") 
//print("\(request.httpMethod ?? "") \(String(describing:request.url))")
 //       print("HEADERS \n \(String(describing:request.allHTTPHeaderFields))")

let semaphorel = DispatchSemaphore(value: 0)
//var filelistDictionary : [String:Any] = [:]
//var filelistArray: [Any] = []
var filelistArrayDictionary: [[String:String]] = []

let taskl = URLSession.shared.dataTask(with: request) {
  data, response, error in
    // Do something
    if let httpResponse = response as? HTTPURLResponse {
   print(httpResponse.statusCode)
    }
      if let data = data{
     
if let filelistDictionary = try? JSONSerialization.jsonObject(with: 
 data, options: []) as? [String: Any   ] {
for (key,value) in filelistDictionary {
    //print("key=  \(key) value = \(value)")
    //print("type \(type(of: value))")
    if value is Array<Any> {
                            //print("Array key = \(key)")
                            if let filelistArray = filelistDictionary[key]{
                            //print("Type \(type(of: filelistArray))")
                            //print(filelistArray)
                            filelistArrayDictionary = filelistArray as!  [[String:String]]
                            // print(filelistArrayDictionary)
                             
                           }
}
       }
//
    } 
    if let httpResponse = response as? HTTPURLResponse {
       print(httpResponse.statusCode)
    }
    semaphorel.signal()
  }}
taskl.resume()
 semaphorel.wait()

 return filelistArrayDictionary
 }

func GCEFindLatestFileId(searchName:String, FileIds:[[String:String]])->String
{
let string = "2019-01-14T00:00:00.000Z"               
let utcTimezone = TimeZone(abbreviation: "UTC")!
let dfs = DateFormatter()
dfs.timeZone = utcTimezone
dfs.locale = Locale(identifier: "en_gb")
dfs.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
dfs.calendar = Calendar(identifier: Calendar.Identifier.iso8601)
let basedate = dfs.date(from: string)!
  var datebase = basedate
  var returnvalue: String = ""
for item in FileIds
 {
   if item["name"] == searchName
   {
     //print("\(item["modifiedTime"]!) \(item["id"]!)")
     if dfs.date(from: item["modifiedTime"]!)! > datebase
     {
     
       datebase = dfs.date(from: item["modifiedTime"]!)!
       
     }
   }
    
 }
 for item in FileIds
 {
   if item["name"] == searchName
   {
     if dfs.date(from: item["modifiedTime"]!)! == datebase
     {
       returnvalue = (item["id"]!)
     }
   }
 }
return returnvalue
}

func GCEPatchUpload(name: String, fileId: String, authCode: String, uploadData: Data)->String
{



let urlu1 = URL(string:
 "https://www.googleapis.com/upload/drive/v3/files/\(fileId)?uploadType=resumable")
 var request = URLRequest(url: urlu1!)
var mylocation:String = ""
request.httpMethod = "PATCH"
//let jsonMetaData1 = try? JSONSerialization.data(withJSONObject: description) 
request.setValue("application/json", forHTTPHeaderField: "Content-Type") 
request.setValue("Bearer "+authCode, forHTTPHeaderField: "Authorization") 
/*
request.setValue("\(jsonMetaData1!.count)", forHTTPHeaderField: "Content-Length")
request.setValue("image/jpeg", forHTTPHeaderField: "X-Upload-Content-Type")
request.setValue("\(uploadData.count)", forHTTPHeaderField: "X-Upload-Content-Length")
request.httpBody = jsonMetaData1!
*/

////
//print("\(request.httpMethod ?? "") \(String(describing:request.url))")
       // let strup = String(decoding: request.httpBody!, as: UTF8.self)

       // print("HEADERS \n \(String(describing:request.allHTTPHeaderFields))")
//                   
let semaphoreuploadput1 = DispatchSemaphore(value: 0)
let taskuploadput1 = URLSession.shared.dataTask(with: request) { 
  data, response, error in
    // Do something
      if let data = data, let dataString = String(data: data, encoding: .utf8) {
      print(dataString)
      }
      if let httpResponse = response as? HTTPURLResponse {
      //print(httpResponse.statusCode)
      
/*for (a,b) in httpResponse.allHeaderFields { 
                                           //print(a,b)
                                          }
                                          */
      if let location = httpResponse.allHeaderFields["Location"] as? String
          {mylocation = location} 
      }
    semaphoreuploadput1.signal()
}//url
   taskuploadput1.resume()
   semaphoreuploadput1.wait()
   return mylocation
}





func GCECreateLocalDirectories(fullname: String)->String
{
let path = FileManager.default.currentDirectoryPath
let GCEPath = path.appendingPathComponent(fullname)
let URLGCEPath = URL(fileURLWithPath: GCEPath) 
if !FileManager.default.fileExists(atPath: URLGCEPath.path) {
    //print("Creating")
    do {
        try FileManager.default.createDirectory(atPath: URLGCEPath.path, withIntermediateDirectories: true, attributes: [:])
    } catch {
        print(error.localizedDescription);
    }
}
return "TRUE"
}

public func GCEPreExport(myjson:[String:String])->String
{

let AT=GCEGAT(myjson: myjson)

// Get NB name and file and copy from G-Drive to local drive 

var (NBn,NBf)=GCEGetNotebookName()

var FI = NBf.components(separatedBy: "=")
//print(FI[1])
var dd = GCEGetFile(fileid: FI[1],  authorizationToken: AT)
GCEWriteFileLocal(name: NBn , dd: dd)
return NBn
//print("/bin/ls".shell("-lh","/content"))
}

public func GCEPostExport(myjson:[String:String])->String
{
let AT=GCEGAT(myjson: myjson)
let (NBn,_)=GCEGetNotebookName()

// Check for pre-existing folder
let exportFolder = (("FastaiNotebook_"+NBn).components(separatedBy: "."))[0]
//print(exportFolder)
let xrd =  GCEReadDirectory(authorizationToken: AT, searchName: exportFolder )
let notebookId = GCEFindLatestFileId(searchName:exportFolder, FileIds: xrd)

if (notebookId == "") {print("Creating Folder")}
//Does not exist so create one. First find the file id of colab Notebooks

let xrdcl =  GCEReadDirectory(authorizationToken: AT, searchName: "Colab Notebooks" )
let ParentCLId = GCEFindLatestFileId(searchName:"Colab Notebooks", FileIds: xrdcl)
// And create one noting the File id
let latestFolder  = GCECreateFolder(parentfolderid: ParentCLId, NotebookName: exportFolder, authorizationToken: AT)

//print(xrdcl)

//print(ParentCLId)

//print(exportFolder)

// Find the local files generated by export

//print(exportFolder)
let Package = GCELocalFileRead(atPath: exportFolder+"/Package.swift")
let main =    GCELocalFileRead(atPath: exportFolder+"/Sources/"+exportFolder+"/"+exportFolder.components(separatedBy: "_")[1]+".swift")


//print(latestFolder)

// And copy to G
let GCEPuLP =  GCEPostUpload(name: "Package.swift", folderid: latestFolder, authCode: AT, uploadData: Package)
GCEPut(location: GCEPuLP, newdd: Package)
//And find their file id
let GCERDFF = GCEReadDirectoryforFiles(authorizationToken: AT, searchName: "Package.swift",folder: latestFolder)
let GPackageId = GCEFindLatestFileId(searchName:"Package.swift", FileIds: GCERDFF)


// and again



let GCEPuLm = GCEPostUpload(name: "main.swift", folderid: latestFolder, authCode: AT, uploadData: main)
let GCEputr = GCEPut(location: GCEPuLm, newdd: main)
let GCERDFFmain = GCEReadDirectoryforFiles(authorizationToken: AT, searchName: "main.swift",folder: latestFolder)
let GmainId = GCEFindLatestFileId(searchName:"main.swift", FileIds: GCERDFFmain)

// They may exist 
let RDP = GCEReadDirectoryforFiles(authorizationToken: AT, searchName: "Package.swift", folder: latestFolder)
let GPId = GCEFindLatestFileId(searchName:"Package.swift", FileIds: RDP)


let myPackagePatchLocation  = GCEPatchUpload(name: "Package.swift", fileId: GPackageId, authCode: AT, uploadData: Package)
let GCEpackager = GCEPut(location:  myPackagePatchLocation, newdd: Package)

//print(GmainId,xxx)

//print(GCEputr)
String(data:GCEputr, encoding: .utf8)
let xxx = try?(JSONSerialization.jsonObject(with: 
               GCEputr, options: []) as? [String: String  ] )!["id"]
print(GmainId,GPId,xxx!,GCEpackager)
String(data:GCEputr, encoding: .utf8)
return NBn
}
public func GCEImport(myjson:[String:String],importName:String)->String
{
//IMPORT
let AT=GCEGAT(myjson: myjson)
// Build directory  import FastaiNotebook_10_mixup_ls
//var importName = "FastaiNotebook_EarlyLife3"
let importNameList = importName.components(separatedBy: "_")
var importNameShort = ""
for (index,element) in importNameList.enumerated()
 {
   if (index > 0 )
    {
      importNameShort = importNameShort + element
      if (index < importNameList.count - 1) 
         {
           importNameShort = importNameShort + "_"
         }
    }
 }
//print(importNameShort)
let importFolderPath = importName + "/Sources/" + importName
//print (importFolderPath)



GCECreateLocalDirectories(fullname: importFolderPath)

// Now find G Folder for import  import FastaiNotebook_10_mixup_ls

let importFolderList = GCEReadDirectory(authorizationToken: AT, searchName: importName)
let importFolderId = GCEFindLatestFileId(searchName:importName, FileIds: importFolderList)
// File file ids for main and swift 
// And get them using GCEGetFile(fileid)
// And write them using (NBn: NBn , dd: dd)  GCEWriteFileLocal(name: String, dd:





// Now find G Folder for import  import FastaiNotebook_10_mixup_ls
//print(importFolderId)
// File file ids for main and swift 
// And get them using GCEGetFile(fileid)
// And write them using (NBn: NBn , dd: dd)  GCEWriteFileLocal(name: String, dd:

let packageFileList = GCEReadDirectoryforFiles(authorizationToken: AT, searchName: "Package.swift",folder: importFolderId)
let packageFileId = GCEFindLatestFileId(searchName:"Package.swift", FileIds: packageFileList)

let mainFileList = GCEReadDirectoryforFiles(authorizationToken: AT, searchName: "main.swift",folder: importFolderId)
let mainFileId = GCEFindLatestFileId(searchName:"main.swift", FileIds: mainFileList)

let packagedd = GCEGetFile(fileid: packageFileId,  authorizationToken: AT)
let maindd = GCEGetFile(fileid: mainFileId,  authorizationToken: AT)

GCEWriteFileLocal(name: importName + "/Package.swift" , dd: packagedd)
GCEWriteFileLocal(name: importName + "/Sources/" + importName + "/" + importNameShort + ".swift" , dd: maindd) 
return "OK"

//print("/bin/ls".shell("-lh","/content/FastaiNotebook_EarlyLife3/Sources/FastaiNotebook_EarlyLife3"))
}

