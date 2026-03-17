//
//  AppCheck.swift
//  FirebaseAdmin
//
//  Created by Norikazu Muramoto on 2023/05/11.
//

import Foundation
import Synchronization
import JWTKit
import AsyncHTTPClient
import NIO
@_exported import FirebaseApp

// MARK: - Errors

public enum AppCheckError: Error {
    case invalidToken(String)
    case expiredToken
    case invalidIssuer(expected: String, actual: String)
    case invalidAudience(expected: [String], actual: [String])
    case missingRequiredClaim(String)
    case jwksFetchFailed(Error)
    case tokenVerificationFailed(Error)
    case invalidProjectID
    case cacheExpired
}

// MARK: - Token Payload

/// App Check token payload structure
/// See: https://firebase.google.com/docs/app-check/custom-resource-backend
public struct AppCheckTokenPayload: JWTPayload, Sendable {

    /// Issuer: always "https://firebaseappcheck.googleapis.com/<project-number>"
    public var iss: IssuerClaim

    /// Subject: Firebase App ID
    public var sub: SubjectClaim

    /// Audience: array of project identifiers (project numbers and project IDs)
    public var aud: AudienceClaim

    /// Expiration time
    public var exp: ExpirationClaim

    /// Issued at time
    public var iat: IssuedAtClaim

    public func verify(using algorithm: some JWTAlgorithm) async throws {
        try exp.verifyNotExpired()
    }
}

// MARK: - JWKS Cache

/// Cached JWKS with expiration
private struct JWKSCache {
    let jwks: JWKS
    let expiresAt: Date

    var isExpired: Bool {
        Date() >= expiresAt
    }

    /// Create a new cache entry with 6-hour TTL (as recommended by Firebase)
    init(jwks: JWKS, ttl: TimeInterval = 6 * 60 * 60) {
        self.jwks = jwks
        self.expiresAt = Date().addingTimeInterval(ttl)
    }
}

// MARK: - AppCheck

/// Firebase App Check verifier for server-side token validation
///
/// Usage:
/// ```swift
/// let appCheck = AppCheck(projectID: "your-project-id")
/// let token = request.headers["X-Firebase-AppCheck"].first
/// let payload = try await appCheck.verifyToken(token, client: httpClient)
/// ```
public actor AppCheck {

    /// Firebase App Check JWKS endpoint
    /// See: https://firebaseappcheck.googleapis.com/v1/jwks
    private let jwksURL = "https://firebaseappcheck.googleapis.com/v1/jwks"

    /// Firebase project ID for audience validation
    private let projectID: String

    /// Firebase project number for issuer validation (optional)
    private let projectNumber: String?

    /// Cached JWKS with expiration
    private var jwksCache: JWKSCache?

    /// Initialize AppCheck verifier
    /// - Parameters:
    ///   - projectID: Firebase project ID (from service account)
    ///   - projectNumber: Firebase project number (optional, for stricter validation)
    public init(projectID: String, projectNumber: String? = nil) {
        self.projectID = projectID
        self.projectNumber = projectNumber
    }

    /// Convenience initializer using default FirebaseApp's service account
    /// - Throws: AppCheckError.invalidProjectID if default FirebaseApp is not initialized
    public init() throws {
        let app = try FirebaseApp.app()
        self.projectID = app.serviceAccount.projectId
        self.projectNumber = nil
    }

    /// Initialize with a specific FirebaseApp instance
    /// - Parameter app: The FirebaseApp instance to use
    public init(app: FirebaseApp) {
        self.projectID = app.serviceAccount.projectId
        self.projectNumber = nil
    }

    /// Fetch JWKS from Firebase App Check endpoint
    /// - Parameter client: HTTP client instance
    /// - Returns: JWKS object
    /// - Throws: AppCheckError.jwksFetchFailed if fetch fails
    private func fetchJWKS(client: HTTPClient) async throws -> JWKS {
        do {
            let response = try await client.get(url: jwksURL).get()
            guard let body = response.body else {
                throw AppCheckError.jwksFetchFailed(NSError(domain: "AppCheck", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty response body"]))
            }
            return try JSONDecoder().decode(JWKS.self, from: body)
        } catch {
            throw AppCheckError.jwksFetchFailed(error)
        }
    }

    /// Get JWKS from cache or fetch if expired/missing
    /// - Parameter client: HTTP client instance
    /// - Returns: JWKS object
    private func getJWKS(client: HTTPClient) async throws -> JWKS {
        // Check cache
        if let cache = jwksCache, !cache.isExpired {
            return cache.jwks
        }

        // Fetch and cache
        let jwks = try await fetchJWKS(client: client)
        jwksCache = JWKSCache(jwks: jwks)
        return jwks
    }

    /// Verify App Check token
    /// - Parameters:
    ///   - token: App Check JWT token (from X-Firebase-AppCheck header)
    ///   - client: HTTP client instance
    /// - Returns: Decoded token payload
    /// - Throws: AppCheckError if verification fails
    public func verifyToken(_ token: String, client: HTTPClient) async throws -> AppCheckTokenPayload {
        do {
            // Get JWKS
            let jwks = try await getJWKS(client: client)

            // Setup JWT key collection
            let keys = JWTKeyCollection()
            try await keys.add(jwks: jwks)

            // Verify and decode token
            let payload = try await keys.verify(token, as: AppCheckTokenPayload.self)

            // Validate issuer
            if let projectNumber = projectNumber {
                let expectedIssuer = "https://firebaseappcheck.googleapis.com/\(projectNumber)"
                if payload.iss.value != expectedIssuer {
                    throw AppCheckError.invalidIssuer(expected: expectedIssuer, actual: payload.iss.value)
                }
            }

            // Validate audience (must include project ID or project number)
            let audiences = payload.aud.value
            let validAudiences = [
                "projects/\(projectID)",
                projectNumber.map { "projects/\($0)" }
            ].compactMap { $0 }

            let hasValidAudience = audiences.contains { aud in
                validAudiences.contains(aud)
            }

            if !hasValidAudience {
                throw AppCheckError.invalidAudience(expected: validAudiences, actual: audiences)
            }

            return payload

        } catch let error as AppCheckError {
            throw error
        } catch {
            throw AppCheckError.tokenVerificationFailed(error)
        }
    }

    /// Clear the JWKS cache (useful for testing or forcing refresh)
    public func clearCache() {
        jwksCache = nil
    }
}

// MARK: - FirebaseApp Extension

/**
 Extension providing AppCheck factory method on FirebaseApp.
 */
extension FirebaseApp {

    /**
     Returns an `AppCheck` instance for this app.

     Use this method to obtain an `AppCheck` instance that is initialized with this app's
     service account project ID.

     Example:
     ```swift
     let app = try FirebaseApp.initialize(serviceAccount: serviceAccount)
     let appCheck = app.appCheck()
     ```

     - Returns: An `AppCheck` instance initialized with this app's project ID.
     */
    public func appCheck() -> AppCheck {
        return AppCheck(app: self)
    }
}
