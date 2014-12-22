package com.pacificmetrics.orca.utils;

import java.io.IOException;
import java.io.InputStream;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509TrustManager;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.pacificmetrics.orca.cts.CTSRestClient;
import com.sun.jersey.api.client.config.ClientConfig;
import com.sun.jersey.api.client.config.DefaultClientConfig;
import com.sun.jersey.client.urlconnection.HTTPSProperties;

public class CertUtil {

    private static final Log LOGGER = LogFactory.getLog(CertUtil.class);

    private CertUtil() {
    }

    public static SSLContext getSSLContextFromFile(String certFile,
            String certEntry) {
        SSLContext sslContext = null;
        try {
            // Load CAs from an InputStream
            // (could be from a resource or ByteArrayInputStream or ...)
            CertificateFactory cf = CertificateFactory.getInstance("X.509");
            InputStream stream = CTSRestClient.class.getClassLoader()
                    .getResourceAsStream(certFile);
            X509Certificate caCert = null;
            try {
                caCert = (X509Certificate) cf.generateCertificate(stream);
            } finally {
                if (stream != null) {
                    stream.close();
                }
            }
            if (caCert != null) {
                // Create a KeyStore containing our trusted CAs
                String keyStoreType = KeyStore.getDefaultType();
                KeyStore keyStore = KeyStore.getInstance(keyStoreType);
                keyStore.load(null, null);
                keyStore.setCertificateEntry(certEntry, caCert);

                // Create a TrustManager that trusts the CAs in our KeyStore
                String tmfAlgorithm = TrustManagerFactory.getDefaultAlgorithm();
                TrustManagerFactory tmf = TrustManagerFactory
                        .getInstance(tmfAlgorithm);
                tmf.init(keyStore);

                // Create an SSLContext that uses our TrustManager
                sslContext = SSLContext.getInstance("TLS");
                sslContext.init(null, tmf.getTrustManagers(), null);
            }
        } catch (NoSuchAlgorithmException e) {
            LOGGER.error("Error loading certificate " + e.getMessage(), e);
        } catch (KeyStoreException e) {
            LOGGER.error("Error loading certificate " + e.getMessage(), e);
        } catch (KeyManagementException e) {
            LOGGER.error("Error loading certificate " + e.getMessage(), e);
        } catch (CertificateException e) {
            LOGGER.error("Error loading certificate " + e.getMessage(), e);
        } catch (IOException e) {
            LOGGER.error("Error loading certificate " + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.error("Error loading certificate " + e.getMessage(), e);
        }
        return sslContext;
    }

    public static ClientConfig getAllTrustingClientConfig() {
        TrustManager[] certs = new TrustManager[] { new X509TrustManager() {
            @Override
            public X509Certificate[] getAcceptedIssuers() {
                return null;
            }

            @Override
            public void checkServerTrusted(X509Certificate[] chain,
                    String authType) throws CertificateException {
            	// Do nothing
            }

            @Override
            public void checkClientTrusted(X509Certificate[] chain,
                    String authType) throws CertificateException {
            	// Do nothing
            }
        } };
        SSLContext ctx = null;
        try {
            ctx = SSLContext.getInstance("TLS");
            ctx.init(null, certs, new SecureRandom());
        } catch (java.security.GeneralSecurityException ex) {
        	LOGGER.error("Error initialising " + ex.getMessage(), ex);
        }
        HttpsURLConnection.setDefaultSSLSocketFactory(ctx.getSocketFactory());

        ClientConfig config = new DefaultClientConfig();
        try {
            config.getProperties().put(
                    HTTPSProperties.PROPERTY_HTTPS_PROPERTIES,
                    new HTTPSProperties(new HostnameVerifier() {
                        @Override
                        public boolean verify(String hostname,
                                SSLSession session) {
                            return true;
                        }
                    }, ctx));
        } catch (Exception e) {
        	LOGGER.error("Error " + e.getMessage(), e);
        }
        return config;
    }

    public static SSLSocketFactory getSSLSocketFactory() {
        TrustManager[] certs = new TrustManager[] { new X509TrustManager() {
            @Override
            public X509Certificate[] getAcceptedIssuers() {
                return null;
            }

            @Override
            public void checkServerTrusted(X509Certificate[] chain,
                    String authType) throws CertificateException {
            	// Do nothing
            }

            @Override
            public void checkClientTrusted(X509Certificate[] chain,
                    String authType) throws CertificateException {
            	// Do nothing
            }
        } };
        SSLContext ctx = null;
        try {
            ctx = SSLContext.getInstance("TLS");
            ctx.init(null, certs, new SecureRandom());
        } catch (java.security.GeneralSecurityException ex) {
        	LOGGER.error("Error initialising:" + ex.getMessage(), ex);
        }
        return ctx.getSocketFactory();
    }

    public static HostnameVerifier getHostnameVerifier() {
        HostnameVerifier hostnameVerifier = null;
        try {
            hostnameVerifier = new HostnameVerifier() {
                @Override
                public boolean verify(String hostname, SSLSession session) {
                    return true;
                }
            };
        } catch (Exception e) {
        	LOGGER.error("Error verifying :" + e.getMessage(), e);
        }
        return hostnameVerifier;
    }
}
