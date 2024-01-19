//
//  DocumentReference+gRPC.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/10.
//

import Foundation
import NIOHPACK

extension DocumentReference {
    
    public func getDocument(prevFirestore: Firestore? = nil) async throws -> DocumentSnapshot {
        let firestore = prevFirestore ?? Firestore.firestore()
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AcessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        return try await getDocument(firestore: firestore, headers: headers)
    }
    
    public func setData(_ documentData: [String: Any], merge: Bool = false, prevFirestore: Firestore? = nil) async throws {
        let firestore = prevFirestore ?? Firestore.firestore()
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AcessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        return try await setData(documentData, merge: merge, firestore: firestore, headers: headers)
    }
    
    public func updateData(_ fields: [String: Any], prevFirestore: Firestore? = nil) async throws {
        let firestore = prevFirestore ?? Firestore.firestore()
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AcessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        return try await updateData(fields, firestore: firestore, headers: headers)
    }
    
    public func delete(prevFirestore: Firestore? = nil) async throws {
        let firestore = prevFirestore ?? Firestore.firestore()
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AcessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        return try await delete(firestore: firestore, headers: headers)
    }
}

extension DocumentReference {
    
    public func setData<T: Encodable>(_ data: T, merge: Bool = false, prevFirestore: Firestore? = nil) async throws {
        let firestore = prevFirestore ?? Firestore.firestore()
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AcessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        return try await self.setData(data, firestore: firestore, headers: headers)
    }
    
    public func updateData<T: Encodable>(_ data: T, prevFirestore: Firestore? = nil) async throws {
        let firestore = prevFirestore ?? Firestore.firestore()
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AcessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        return try await self.updateData(data, firestore: firestore, headers: headers)
    }
}

extension DocumentReference {

    public func getDocument<T: Decodable>(type: T.Type) async throws -> T? {
        let firestore = Firestore.firestore()
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AcessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        return try await getDocument(type: type, firestore: firestore, headers: headers)
    }
}
