class LicensePublicKeyConfig {
  /// Replace this development placeholder with the production Ed25519 public key.
  ///
  /// Generate keys with:
  /// python tools/license_admin/generate_keypair.py
  ///
  /// The private key stays with the software owner/admin tool only.
  /// The public key can be shipped in the customer app.
  static const ed25519PublicKeyBase64 = 'PASTE_PRODUCTION_ED25519_PUBLIC_KEY_BASE64_HERE';

  static bool get hasConfiguredPublicKey =>
      ed25519PublicKeyBase64.isNotEmpty &&
      ed25519PublicKeyBase64 != 'PASTE_PRODUCTION_ED25519_PUBLIC_KEY_BASE64_HERE';
}
