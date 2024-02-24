
import 'dart:convert';
import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:f_logs/f_logs.dart';

import '../repo/local_storage.dart';

class SslHelper {
  final LocalStorage storage;

  SslHelper(this.storage);

  Future<SecurityContext> getServerSecurityContext() async {
    SecurityContext securityContext = SecurityContext();
    String? certificatePem = await storage.getCertificate();
    String? privateKeyPem = await storage.getPrivateKey();
    String? publicKeyPem = await storage.getPublicKey();
    bool needToGenerateCertificate = certificatePem == null || privateKeyPem == null || publicKeyPem == null;
    if (needToGenerateCertificate) {
      FLog.info(text: "Certificate, public, or (and) private keys are not saved. Move to generating");

      AsymmetricKeyPair keyPair = CryptoUtils.generateEcKeyPair();
      ECPublicKey publicKey = keyPair.publicKey as ECPublicKey;
      ECPrivateKey privateKey = keyPair.privateKey as ECPrivateKey;
      certificatePem = await _generateCertificate(publicKey, privateKey);
      publicKeyPem = CryptoUtils.encodeEcPublicKeyToPem(publicKey);
      privateKeyPem = CryptoUtils.encodeEcPrivateKeyToPem(privateKey);
      FLog.info(text: "Certificate, public and private keys were successfully generated. Save in the local storage");

      await storage.setPublicKey(publicKeyPem);
      await storage.setPrivateKey(privateKeyPem);
      await storage.setCertificate(certificatePem);
      FLog.info(text: "Certificate, public and private keys were successfully saved in the local storage");
    }

    List<int> certificateBytes = utf8.encode(certificatePem);
    List<int> privateKeyBytes = utf8.encode(privateKeyPem);
    securityContext.useCertificateChainBytes(certificateBytes);
    securityContext.usePrivateKeyBytes(privateKeyBytes);
    return securityContext;
  }

  static bool handleSelfSignedCertificate({required X509Certificate certificate,required List<String> pairedDevicesId}) {
    String issuer = certificate.issuer;
    bool containsAppName = issuer.toUpperCase().contains("MAKUKU");
    if (!containsAppName) {
      FLog.info(text: "The issuer ($issuer) of the provided certificate is not Makuku. Closing connection");
      return false;
    }
    bool containsPairedDeviceId = pairedDevicesId.where((e) => issuer.contains(e)).isNotEmpty;
    if (!containsPairedDeviceId) FLog.info(text: "Server device id is unknown to this device. Closing connection");
    return containsPairedDeviceId;
  }

  Future<String> _generateCertificate(ECPublicKey publicKey,ECPrivateKey privateKey) async {
    FLog.trace(text: "generating certificate...");
    Map<String,String> attributes = {
      'CN': storage.getDeviceId(),
      'OU': 'Makuku',
    };
    String csr = X509Utils.generateEccCsrPem(attributes, privateKey, publicKey);
    String x509PEM = X509Utils.generateSelfSignedCertificate(
      privateKey,
      csr,
      365,
    );
    FLog.trace(text: "certificate is generated");
    return x509PEM;
  }
}