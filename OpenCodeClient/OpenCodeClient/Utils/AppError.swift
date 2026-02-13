//
//  AppError.swift
//  OpenCodeClient
//

import Foundation

enum AppError: Error, Equatable {
    case connectionFailed(String)
    case serverError(String)
    case invalidResponse
    case unauthorized
    case sessionNotFound
    case fileNotFound(String)
    case operationFailed(String)
    case unknown(String)
    
    var localizedDescription: String {
        switch self {
        case .connectionFailed(let detail):
            return "连接失败：\(detail)"
        case .serverError(let detail):
            return "服务器错误：\(detail)"
        case .invalidResponse:
            return "服务器返回了无效的响应"
        case .unauthorized:
            return "未授权，请检查认证信息"
        case .sessionNotFound:
            return "Session 不存在"
        case .fileNotFound(let path):
            return "文件不存在：\(path)"
        case .operationFailed(let detail):
            return "操作失败：\(detail)"
        case .unknown(let detail):
            return "未知错误：\(detail)"
        }
    }
    
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        let errorString = error.localizedDescription
        
        if errorString.contains("401") || errorString.contains("Unauthorized") {
            return .unauthorized
        }
        
        if errorString.contains("invalid URL") || errorString.contains("Invalid URL") {
            return .operationFailed("无效的 URL")
        }
        
        if errorString.contains("HTTP") {
            return .serverError(errorString)
        }
        
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .connectionFailed(errorString)
        }
        
        return .unknown(errorString)
    }
}

extension AppError {
    var isConnectionError: Bool {
        if case .connectionFailed = self { return true }
        return false
    }
    
    var isRecoverable: Bool {
        switch self {
        case .connectionFailed, .unauthorized, .serverError:
            return true
        case .invalidResponse, .sessionNotFound, .fileNotFound, .operationFailed, .unknown:
            return false
        }
    }
}
