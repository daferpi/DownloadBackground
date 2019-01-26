import UIKit

class ViewController: UIViewController {

    private var backgroundTask: URLSessionDownloadTask?
    @IBOutlet weak var downloadedFiles: UILabel!

    @IBOutlet weak var progressView: UIProgressView!
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "MySession")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    @IBAction func startDownload(_ sender: Any) {
        let  url = URL(string: "https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4")!
        backgroundTask = session.downloadTask(with: url)
        backgroundTask?.resume()
        print("backgroundTask.resume")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }

    func updateUI() {
        let documentsURL = try?
            FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        let path = documentsURL?.path ?? ""
        let content = try? FileManager.default.contentsOfDirectory(atPath: path)
        downloadedFiles.text = content?.reduce("") { "\($0)\($1)" }
    }
}

extension ViewController: URLSessionDelegate, URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("didFinishDownloadingTo")
        do {
            let documentsURL = try
                FileManager.default.url(for: .documentDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: false)
            let savedURL = documentsURL.appendingPathComponent(
                location.lastPathComponent)
            try FileManager.default.moveItem(at: location, to: savedURL)
            DispatchQueue.main.async {
                self.updateUI()
            }
        } catch {
            // handle filesystem error
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("urlSessionDidFinishEvents")
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let backgroundCompletionHandler =
                appDelegate.backgroundCompletionHandler else {
                    return
            }
            backgroundCompletionHandler()
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        if downloadTask == self.backgroundTask {
            let calculatedProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            DispatchQueue.main.async {
                print(NSNumber(value: calculatedProgress))
                self.progressView.progress = Float(NSNumber(value: calculatedProgress))
            }
        }
    }
}
