package com.example.makukujavafx.network;

import com.example.makukujavafx.classes.JsonHandler;
import com.example.makukujavafx.helpers.FileUtils;
import com.example.makukujavafx.models.DeviceInfo;
import org.bouncycastle.asn1.x500.X500Name;
import org.bouncycastle.asn1.x509.SubjectPublicKeyInfo;
import org.bouncycastle.cert.X509v3CertificateBuilder;
import org.bouncycastle.cert.jcajce.JcaX509CertificateConverter;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.bouncycastle.operator.ContentSigner;
import org.bouncycastle.operator.jcajce.JcaContentSignerBuilder;

import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLServerSocket;
import javax.net.ssl.SSLSocket;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.math.BigInteger;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.security.*;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Date;

import static com.example.makukujavafx.classes.ServerHandler.PORT;

public class SslHelper {
    private static SSLContext sslContext;

    public static SSLServerSocket getSslServerSocket(InetAddress inetAddress) throws IOException {
        ServerSocket serverSocket = sslContext.getServerSocketFactory().createServerSocket(PORT, 0, inetAddress);
        return (SSLServerSocket) serverSocket;
    }

    public static SSLSocket getSslClientSocket(InetAddress inetAddress) throws IOException {
        Socket clientSocket = sslContext.getSocketFactory().createSocket(inetAddress, PORT);
        return (SSLSocket) clientSocket;
    }


    public static void init() throws Exception {
        initSslContext();
    }


    private static void initSslContext() throws Exception {
        byte[] certBytes = FileUtils.getCert();
        byte[] privateKeyBytes = FileUtils.getPrivateKey();
        byte[] publicKeyBytes = FileUtils.getPublicKey();
        boolean needToGenerateCert = certBytes == null || privateKeyBytes == null || publicKeyBytes == null;

        if (needToGenerateCert) {
            KeyPair keyPair = createKeys();
            X509Certificate cert = generateCertificate(keyPair);
            certBytes = cert.getEncoded();
            privateKeyBytes = keyPair.getPrivate().getEncoded();
            publicKeyBytes = keyPair.getPublic().getEncoded();

            FileUtils.write(certBytes, FileUtils.getCertFilePath());
            FileUtils.write(privateKeyBytes, FileUtils.getPrivateKeyFilePath());
            FileUtils.write(publicKeyBytes, FileUtils.getPublicKeyFilePath());
        }

        CertificateFactory certFactory = CertificateFactory.getInstance("X.509");
        InputStream in = new ByteArrayInputStream(certBytes);
        X509Certificate cert = (X509Certificate) certFactory.generateCertificate(in);


        KeyFactory keyFactory = KeyFactory.getInstance("RSA");
        PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(privateKeyBytes);
        PrivateKey privateKey = keyFactory.generatePrivate(keySpec);

        // Загрузка KeyStore
        KeyStore keyStore = KeyStore.getInstance("JKS");
        keyStore.load(null, null);
        keyStore.setCertificateEntry("cert-alias", cert);
        keyStore.setKeyEntry("key-alias", privateKey, "".toCharArray(), new java.security.cert.Certificate[]{cert});

        KeyManagerFactory keyManagerFactory = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
        keyManagerFactory.init(keyStore, "".toCharArray());

        // Создание SSLContext
        sslContext = SSLContext.getInstance("TLS");
        sslContext.init(keyManagerFactory.getKeyManagers(), null, null);
    }

    private static X509Certificate generateCertificate(KeyPair keyPair) throws Exception {


        SubjectPublicKeyInfo subjectPublicKeyInfo = SubjectPublicKeyInfo.getInstance(keyPair.getPublic().getEncoded());
        JsonHandler jsonHandler = new JsonHandler();
        DeviceInfo deviceInfo = jsonHandler.getDeviceFromJsonFile();

        X500Name issuerName = new X500Name(String.format("CN=%s, OU=Makuku", deviceInfo.getId()));
        System.out.println("issuerName - " + issuerName);
        X509v3CertificateBuilder certificateBuilder = new X509v3CertificateBuilder(issuerName,
                new BigInteger(64, new SecureRandom()),
                new Date(System.currentTimeMillis() - 24 * 60 * 60 * 1000),
                new Date(System.currentTimeMillis() + 365 * 24 * 60 * 60 * 1000),
                issuerName,
                subjectPublicKeyInfo);


        ContentSigner contentSigner = new JcaContentSignerBuilder("SHA256withRSA").build(keyPair.getPrivate());


        X509Certificate certificate = new JcaX509CertificateConverter().getCertificate(certificateBuilder.build(contentSigner));


        return certificate;
    }


    private static KeyPair createKeys() throws Exception {

        KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA", new BouncyCastleProvider());
        keyPairGenerator.initialize(2048);
        KeyPair keyPair = keyPairGenerator.generateKeyPair();
        FileUtils.write(keyPair.getPrivate().getEncoded(), FileUtils.getPrivateKeyFilePath());
        FileUtils.write(keyPair.getPublic().getEncoded(), FileUtils.getPublicKeyFilePath());
        return keyPair;

    }
}
