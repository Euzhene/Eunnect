
import 'dart:convert';
import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:f_logs/f_logs.dart';

import '../repo/local_storage.dart';

//todo deviceId может быть получен прямо из storage
class SslHelper {
  final LocalStorage storage;
  final String deviceId;

  SslHelper(this.storage, this.deviceId);

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

  Future<String> _generateCertificate(ECPublicKey publicKey,ECPrivateKey privateKey) async {
    FLog.trace(text: "generating certificate...");
    Map<String,String> attributes = {
      'CN': deviceId,
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