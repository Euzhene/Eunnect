package com.example.makukujavafx.network;

import com.example.makukujavafx.classes.JsonHandler;
import com.example.makukujavafx.models.DeviceInfo;
import org.bouncycastle.asn1.pkcs.RSAPublicKey;
import org.bouncycastle.asn1.x500.X500Name;
import org.bouncycastle.asn1.x509.SubjectPublicKeyInfo;
import org.bouncycastle.cert.X509v3CertificateBuilder;
import org.bouncycastle.cert.jcajce.JcaX509CertificateConverter;
import org.bouncycastle.operator.ContentSigner;
import org.bouncycastle.operator.jcajce.JcaContentSignerBuilder;

import java.math.BigInteger;
import java.security.SecureRandom;
import java.security.cert.X509Certificate;
import java.util.Date;

public class SslHelper {
    public X509Certificate createCertificate() throws Exception {
        KeyGenerator keyGenerator = new KeyGenerator();
        keyGenerator.createKey();

        RSAPublicKey rsaPublicKey = (RSAPublicKey) keyGenerator.getKey().getPublic();
        SubjectPublicKeyInfo subjectPublicKeyInfo = SubjectPublicKeyInfo.getInstance(rsaPublicKey.getEncoded());
        JsonHandler jsonHandler = new JsonHandler();
        DeviceInfo deviceInfo = jsonHandler.getDeviceFromJsonFile();

        X500Name issuerName = new X500Name(String.format("CN={0}, OU=Makuku", deviceInfo.getId()));
        X500Name subjectName = issuerName;
        X509v3CertificateBuilder certificateBuilder = new X509v3CertificateBuilder(issuerName,
                new BigInteger(64, new SecureRandom()),
                new Date(System.currentTimeMillis() - 24 * 60 * 60 * 1000),
                new Date(System.currentTimeMillis() + 365 * 24 * 60 * 60 * 1000),
                subjectName,
                subjectPublicKeyInfo);

        // Create a content signer
        ContentSigner contentSigner = new JcaContentSignerBuilder("SHA256withRSA").build(keyGenerator.getKey().getPrivate());

        // Create a self-signed certificate
        X509Certificate certificate = new JcaX509CertificateConverter().getCertificate(certificateBuilder.build(contentSigner));

        // Print the certificate
        return certificate;
    }
}
