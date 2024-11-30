//
//  Podhub.swift
//  PodcastLibraries
//
//  Created by Raidan on 2024. 11. 13..
//
import Foundation

#if DEBUG
private let shouldLog: Bool = true
#else
private let shouldLog: Bool = false
#endif

@inlinable
public func LogError(_ message: @autoclosure () -> String,
                        file: StaticString = #file,
                        function: StaticString = #function,
                        line: UInt = #line) {
    ItunesPodcastManagerLogger.log(message(), type: .error, file: file, function: function, line: line)
}

@inlinable
public func LogWarn(_ message: @autoclosure () -> String,
                       file: StaticString = #file,
                       function: StaticString = #function,
                       line: UInt = #line) {
    ItunesPodcastManagerLogger.log(message(), type: .warning, file: file, function: function, line: line)
}

@inlinable
public func LogInfo(_ message: @autoclosure () -> String,
                       file: StaticString = #file,
                       function: StaticString = #function,
                       line: UInt = #line) {
    ItunesPodcastManagerLogger.log(message(), type: .info, file: file, function: function, line: line)
}

@inlinable
public func LogDebug(_ message: @autoclosure () -> String,
                        file: StaticString = #file,
                        function: StaticString = #function,
                        line: UInt = #line) {
    ItunesPodcastManagerLogger.log(message(), type: .debug, file: file, function: function, line: line)
}

@inlinable
public func LogVerbose(_ message: @autoclosure () -> String,
                          file: StaticString = #file,
                          function: StaticString = #function,
                          line: UInt = #line) {
    ItunesPodcastManagerLogger.log(message(), type: .verbose, file: file, function: function, line: line)
}

public class ItunesPodcastManagerLogger {
    public enum LogType {
        case error
        case warning
        case info
        case debug
        case verbose
    }

    public static func log(_ message: @autoclosure () -> String,
                           type: LogType,
                           file: StaticString,
                           function: StaticString,
                           line: UInt) {
        guard shouldLog else { return }
        let fileName = String(describing: file).lastPathComponent
        let formattedMsg = String(
            format: "file:%@ func:%@ line:%d msg:---%@",
            fileName,
            String(describing: function),
            line, message()
        )
         LogFormatter.shared.log(message: formattedMsg, type: type)
    }
}

private extension String {
    var fileURL: URL {
        return URL(fileURLWithPath: self)
    }

    var pathExtension: String {
        return fileURL.pathExtension
    }

    var lastPathComponent: String {
        return fileURL.lastPathComponent
    }
}

final class LogFormatter: NSObject, Sendable {
    static let shared = LogFormatter()
    let dateFormatter: DateFormatter

    override init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
        super.init()
    }

    func log(message logMessage: String, type: ItunesPodcastManagerLogger.LogType) {
        var logLevelStr: String
        switch type {
        case .error:
            logLevelStr = "‼️ Error"
        case .warning:
            logLevelStr = "⚠️ Warning"
        case .info:
            logLevelStr = "ℹ️ Info"
        case .debug:
            logLevelStr = "✅ Debug"
        case .verbose:
            logLevelStr = "⚪ Verbose"
        }

        let dateStr = dateFormatter.string(from: Date())
        let finalMessage = String(format: "%@ | %@ %@", logLevelStr, dateStr, logMessage)
        print(finalMessage)
    }
}
