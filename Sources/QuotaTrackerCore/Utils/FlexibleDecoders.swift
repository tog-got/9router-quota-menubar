import Foundation

/// Helper untuk mendekode nilai angka fleksibel (Double, Int, atau String berisi angka)
public struct FlexibleDouble: Codable, Equatable, Sendable {
    public let value: Double
    
    public init(_ value: Double) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let doubleVal = try? container.decode(Double.self) {
            self.value = doubleVal
        } else if let intVal = try? container.decode(Int.self) {
            self.value = Double(intVal)
        } else if let strVal = try? container.decode(String.self), let parsed = Double(strVal.trimmingCharacters(in: .whitespacesAndNewlines)) {
            self.value = parsed
        } else {
            throw DecodingError.typeMismatch(FlexibleDouble.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Double, Int, or numeric String"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

/// Helper untuk mendekode ID fleksibel (String atau Int)
public struct FlexibleID: Codable, Equatable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: String
    
    public var description: String { rawValue }
    
    public init(_ value: String) {
        self.rawValue = value
    }
    
    public init(_ value: Int) {
        self.rawValue = String(value)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let strVal = try? container.decode(String.self) {
            self.rawValue = strVal
        } else if let intVal = try? container.decode(Int.self) {
            self.rawValue = String(intVal)
        } else {
            throw DecodingError.typeMismatch(FlexibleID.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or Int ID"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// Helper untuk mendekode Tanggal fleksibel (ISO8601 string, timestamp detik, atau timestamp milidetik)
public struct FlexibleDate: Codable, Equatable, Sendable {
    public let date: Date
    
    public init(_ date: Date) {
        self.date = date
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Coba sebagai string ISO8601 / RFC3339
        if let strVal = try? container.decode(String.self) {
            if let parsed = FlexibleDate.parseDateString(strVal) {
                self.date = parsed
                return
            }
            // Jika string adalah angka timestamp
            if let num = Double(strVal) {
                self.date = FlexibleDate.parseTimestamp(num)
                return
            }
        }
        
        // Coba sebagai angka timestamp
        if let doubleVal = try? container.decode(Double.self) {
            self.date = FlexibleDate.parseTimestamp(doubleVal)
            return
        }
        
        if let intVal = try? container.decode(Int.self) {
            self.date = FlexibleDate.parseTimestamp(Double(intVal))
            return
        }
        
        throw DecodingError.typeMismatch(FlexibleDate.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected ISO8601 String or Unix Timestamp"))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: date))
    }
    
    public static func parseTimestamp(_ timestamp: Double) -> Date {
        // Jika lebih dari tahun 2100 dalam detik (misal > 4_102_444_800), kemungkinan milidetik
        if timestamp > 4_102_444_800 {
            return Date(timeIntervalSince1970: timestamp / 1000.0)
        } else {
            return Date(timeIntervalSince1970: timestamp)
        }
    }
    
    public static func parseDateString(_ str: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: str) {
            return date
        }
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: str) {
            return date
        }
        
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        for format in formats {
            df.dateFormat = format
            if let date = df.date(from: str) {
                return date
            }
        }
        return nil
    }
}
