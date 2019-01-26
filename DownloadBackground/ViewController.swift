import UIKit

class ViewController: UIViewController {

    private var resumeData: Data?
    private var backgroundTask: URLSessionDownloadTask?
    private var session: URLSession?

    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!

    override func viewDidLoad() {
        super.viewDidLoad()
        initSession()
    }

    private func initSession() {
        let config = URLSessionConfiguration.background(withIdentifier: "MySession")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    @IBAction func startDownload(_ sender: Any) {
        if let backgroundTask = backgroundTask {
            backgroundTask.resume()
        } else {
            resumeTask()
        }
    }

    func resumeTask() {
        if let data = self.resumeData {
            backgroundTask = session?.downloadTask(withResumeData: data)
        } else {
            let endpoint = "https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4"
            backgroundTask = session?.downloadTask(with: URL(string: endpoint)!)
        }
        backgroundTask?.resume()
    }
}

extension ViewController: URLSessionDelegate, URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }
        let userInfo = (error as NSError).userInfo
        if let resumeData = userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            self.resumeData = resumeData
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
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
        DispatchQueue.main.async {
            let calculatedProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            self.progressLabel.text = "\(calculatedProgress)"
            self.progressView.progress = calculatedProgress
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) { }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) { }
}
