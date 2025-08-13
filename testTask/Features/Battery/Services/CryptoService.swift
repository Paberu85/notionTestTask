//
//  CryptoService.swift
//  testTask
//
//  Created by Pavlo Buievych on 12.08.2025.
//

import Foundation
import CryptoKit

// Демонстраційна обфускація (PCBC-подібна) поверх Base64. Це не криптозахист.
final class CryptoService: CryptoServiceProtocol, @unchecked Sendable {
	private let keyBytes: [UInt8]
	private let blockSize = 8

	init(key: String = "BatteryMonitorKey") {
		self.keyBytes = Array(SHA256.hash(data: Data(key.utf8))).map { $0 }
	}

	func encrypt(_ data: Data) -> Data? {
		let iv = Array(keyBytes.prefix(blockSize))
		let padded = pkcs7Pad(Array(data), blockSize: blockSize)
		let cipher = pcBcTransform(padded, iv: iv, encrypting: true)
		let b64 = Data(cipher).base64EncodedString()
		return Data(b64.utf8)
	}

	func decrypt(_ data: Data) -> Data? {
		guard let rawB64 = String(data: data, encoding: .utf8),
			  let raw = Data(base64Encoded: rawB64) else { return nil }
		let iv = Array(keyBytes.prefix(blockSize))
		let plainPadded = pcBcTransform(Array(raw), iv: iv, encrypting: false)
		return Data(pkcs7Unpad(plainPadded, blockSize: blockSize))
	}

	// MARK: - PCBC (спрощена)
	private func pcBcTransform(_ input: [UInt8], iv: [UInt8], encrypting: Bool) -> [UInt8] {
		var prev = iv
		var out: [UInt8] = []
		out.reserveCapacity(input.count)

		for i in stride(from: 0, to: input.count, by: blockSize) {
			let block = Array(input[i ..< i + blockSize])
			if encrypting {
				let x = xor(block, prev)
				let c = xor(x, Array(keyBytes.prefix(blockSize)))
				out += c
				prev = xor(c, block)
			} else {
				let d = xor(block, Array(keyBytes.prefix(blockSize)))
				let p = xor(d, prev)
				out += p
				prev = xor(block, p)
			}
		}
		return out
	}

	// MARK: - Helpers
	private func xor(_ a: [UInt8], _ b: [UInt8]) -> [UInt8] { zip(a, b).map { $0 ^ $1 } }

	private func pkcs7Pad(_ bytes: [UInt8], blockSize: Int) -> [UInt8] {
		let rem = bytes.count % blockSize
		let pad = rem == 0 ? blockSize : (blockSize - rem)
		return bytes + Array(repeating: UInt8(pad), count: pad)
	}

	private func pkcs7Unpad(_ bytes: [UInt8], blockSize: Int) -> [UInt8] {
		guard !bytes.isEmpty, bytes.count % blockSize == 0 else { return bytes }
		let pad = Int(bytes.last!)
		guard pad > 0, pad <= blockSize, bytes.count >= pad else { return bytes }
		return Array(bytes.dropLast(pad))
	}
}
