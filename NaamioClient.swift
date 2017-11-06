import Foundation
import Merileva

extension ByteArray {
    func asString() -> String? {
        let ptr = UnsafeBufferPointer(start: bytes, count: len)
        return String(bytes: ptr, encoding: String.Encoding.utf8)
    }
}

extension String {
    func asByteArray() -> ByteArray? {
        guard let data = self.data(using: String.Encoding.utf8) else { return nil }

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        let stream = OutputStream(toBuffer: buffer, capacity: data.count)

        stream.open()
        let _ = data.withUnsafeBytes({
            stream.write($0, maxLength: data.count)
        })

        stream.close()
        return ByteArray(bytes: buffer, len: data.count)
    }
}

class NaamioService {
    private let ptr: OpaquePointer

    init(threads: UInt8) {
        ptr = create_service(threads)
    }

    deinit {
        drop_service(ptr)
    }

    func registerPlugin(name: String, relUrl: String, endpoint: String) {
        if let name = name.asByteArray(),
           let relUrl = relUrl.asByteArray(),
           let endpoint = endpoint.asByteArray()
        {
            var req = RegisterRequest(name: name, rel_url: relUrl, endpoint: endpoint)
            register_plugin(ptr, &req, { (token) in
                if let token = token.asString() {
                    print("\(token)")
                }
            })
        }
    }
}

let service = NaamioService(threads: 4)
service.registerPlugin(name: "foo", relUrl: "/hey", endpoint: "localhost")

sleep(2)