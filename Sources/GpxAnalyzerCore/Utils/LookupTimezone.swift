import Foundation
import Alamofire
import SwiftyJSON

public struct TimezoneInfo : Codable {
    public let id: String
    public let tag: String

    init(id: String, tag: String) {
        self.id = id
        self.tag = tag
    }
}

enum LookupTimezoneError : Swift.Error {
    case ResponseHasNoData
    case InvalidResponse
    case InvalidTimezoneId(String)
}

public class LookupTimezone {
    static public var timezoneLookupServer: String? = nil

    static public func at(point: GpxPoint) throws -> TimezoneInfo {
        return try LookupTimezone.at(latitude: point.latitude, longitude: point.longitude)
    }

    static public func at(latitude: Double, longitude: Double) throws -> TimezoneInfo {
        if let serverUrl = LookupTimezone.timezoneLookupServer {
            guard let data = try synchronousHttpGet(serverUrl, "/api/v1/timezone", ["lat": "\(latitude)", "lon": "\(longitude)"]) else {
                throw LookupTimezoneError.ResponseHasNoData
            }
            let json = try asJson(data)
            return TimezoneInfo(id: json["id"].stringValue, tag: json["tag"].stringValue)
        }
        return TimezoneInfo(id: TimeZone.current.identifier, tag: TimeZone.current.abbreviation(for: Date()) ?? "")
    }

    // Synchronously invoke a GET to a url, return the data or an error.
    static private func synchronousHttpGet(_ host: String, _ path: String, _ parameters: [String:String]) throws -> Data? {
        let responseCompleted = DispatchSemaphore(value: 0)

        var error: Swift.Error? = nil
        var resultData: Data? = nil
        Alamofire.request(host + path, parameters: parameters)
            .validate()
            .responseJSON(queue: DispatchQueue.global(qos: .utility)) { response in
                if response.error != nil {
                    error = response.error
                } else {
                    resultData = response.data
                }

            responseCompleted.signal()
        }

        responseCompleted.wait()
        if error != nil {
            throw error!
        }

        return resultData
    }

    static private func asJson(_ data: Data) throws -> JSON {
        return try JSON(data: data)
    }
}
