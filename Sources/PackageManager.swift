public struct PackageManager {
    public init() {}
}

extension URLSession {
    @objc func swizzled_dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        print("What a nice request you have there!")
        
        // Call the original method
        return swizzled_dataTask(with: request, completionHandler: completionHandler)
    }
}