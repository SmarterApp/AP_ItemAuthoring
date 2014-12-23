package com.pacificmetrics.orca.cts;

import javax.net.ssl.SSLContext;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.pacificmetrics.orca.tib.SSOClient;
import com.pacificmetrics.orca.utils.CertUtil;
import com.pacificmetrics.orca.utils.PropertyUtil;
import com.sun.jersey.api.client.Client;
import com.sun.jersey.api.client.ClientResponse;
import com.sun.jersey.api.client.ClientResponse.Status;
import com.sun.jersey.api.client.WebResource;
import com.sun.jersey.api.client.config.ClientConfig;
import com.sun.jersey.api.client.config.DefaultClientConfig;
import com.sun.jersey.client.urlconnection.HTTPSProperties;

public class CTSRestClient {

    private static final Log LOGGER = LogFactory.getLog(CTSRestClient.class);

    private CTSRestClient() {
    }

    private static final Client CLIENT = createClient();

    private static final String BASE_URL = PropertyUtil
            .getProperty(PropertyUtil.CTS_ENDPOINT);
    private static final String PUBLISHER_PATH = "publisher";
    private static final String SUBJECT_PATH = "subject";
    private static final String PUBLICATION_PATH = "publication";
    private static final String CATEGORY_PATH = "category";
    private static final String GRADE_PATH = "grade";
    private static final String STANDARD_PATH = "standard";

    public static Client createClient() {
        SSLContext ctx = createSSLContentFromFile();
        ClientConfig config = new DefaultClientConfig();
        config.getProperties().put(HTTPSProperties.PROPERTY_HTTPS_PROPERTIES,
                new HTTPSProperties(null, ctx));
        return Client.create(config);
    }

    public static SSLContext createSSLContentFromFile() {
        SSLContext sslContext = null;
        try {
            String certFile = PropertyUtil
                    .getProperty(PropertyUtil.CTS_CERT_FILE);
            sslContext = CertUtil.getSSLContextFromFile(certFile, "ctsca");
        } catch (Exception e) {
            LOGGER.error("Error loading certificate " + e.getMessage(), e);
        }
        return sslContext;
    }

    public static String getPublisherJSON() {
        String jsonString = null;
        String token = getSSOTOken();
        String value = "Bearer " + token.trim();
        WebResource resource = CLIENT.resource(BASE_URL + PUBLISHER_PATH);
        ClientResponse response = resource.header("Authorization", value).get(
                ClientResponse.class);
        if (response.getStatus() == Status.OK.getStatusCode()) {
            jsonString = response.getEntity(String.class);
        } else {
            LOGGER.warn("Response Publisher unsuccessful : "
                    + response.getStatus() + " response : "
                    + response.getEntity(String.class));
        }

        return jsonString;
    }

    public static String getSubjectJSON() {
        String jsonString = null;
        String token = getSSOTOken();
        String value = "Bearer " + token.trim();
        WebResource resource = CLIENT.resource(BASE_URL + SUBJECT_PATH);
        ClientResponse response = resource.header("Authorization", value).get(
                ClientResponse.class);
        if (response.getStatus() == Status.OK.getStatusCode()) {
            jsonString = response.getEntity(String.class);
        } else {
            LOGGER.warn("Response Subject unsuccessful : "
                    + response.getStatus() + " response : "
                    + response.getEntity(String.class));

        }
        return jsonString;
    }

    public static String getSubjectJSON(String publisherKey) {
        String jsonString = null;
        String token = getSSOTOken();
        String value = "Bearer " + token.trim();

        WebResource resource = CLIENT.resource(BASE_URL + SUBJECT_PATH
                + "?publisher=" + publisherKey);
        ClientResponse response = resource.header("Authorization", value).get(
                ClientResponse.class);
        if (response.getStatus() == Status.OK.getStatusCode()) {
            jsonString = response.getEntity(String.class);
        } else {
            LOGGER.warn("Response Subject unsuccessful : "
                    + response.getStatus() + " response : "
                    + response.getEntity(String.class));
        }
        return jsonString;
    }

    public static String getPublicationJSON(String publisherKey,
            String subjectKey) {
        String jsonString = null;
        String token = getSSOTOken();
        String value = "Bearer " + token.trim();
        WebResource resource = CLIENT.resource(BASE_URL + PUBLICATION_PATH
                + "?publisher=" + publisherKey + "&subject=" + subjectKey);
        ClientResponse response = resource.header("Authorization", value).get(
                ClientResponse.class);
        if (response.getStatus() == Status.OK.getStatusCode()) {
            jsonString = response.getEntity(String.class);
        } else {
            LOGGER.warn("Response Publication unsuccessful : "
                    + response.getStatus() + " response : "
                    + response.getEntity(String.class));
        }
        return jsonString;
    }

    public static String getCategoryJSON(String publicationKey) {
        String jsonString = null;
        String token = getSSOTOken();
        String value = "Bearer " + token.trim();
        WebResource resource = CLIENT.resource(BASE_URL + PUBLICATION_PATH
                + "/" + publicationKey + "/" + CATEGORY_PATH);
        ClientResponse response = resource.header("Authorization", value).get(
                ClientResponse.class);
        if (response.getStatus() == Status.OK.getStatusCode()) {
            jsonString = response.getEntity(String.class);
        } else {
            LOGGER.warn("Response Category unsuccessful : "
                    + response.getStatus() + " response : "
                    + response.getEntity(String.class));
        }
        return jsonString;
    }

    public static String getAllGradeJSON() {
        String jsonString = null;
        String token = getSSOTOken();
        String value = "Bearer " + token.trim();
        WebResource resource = CLIENT.resource(BASE_URL + GRADE_PATH);
        ClientResponse response = resource.header("Authorization", value).get(
                ClientResponse.class);
        if (response.getStatus() == Status.OK.getStatusCode()) {
            jsonString = response.getEntity(String.class);
        } else {
            LOGGER.warn("Response All Grade unsuccessful : "
                    + response.getStatus() + " response : "
                    + response.getEntity(String.class));
        }
        return jsonString;
    }

    public static String getGradeJSON(String publicationKey) {
        String jsonString = null;
        String token = getSSOTOken();
        String value = "Bearer " + token.trim();
        WebResource resource = CLIENT.resource(BASE_URL + PUBLICATION_PATH
                + "/" + publicationKey + "/" + GRADE_PATH);
        ClientResponse response = resource.header("Authorization", value).get(
                ClientResponse.class);
        if (response.getStatus() == Status.OK.getStatusCode()) {
            jsonString = response.getEntity(String.class);
        } else {
            LOGGER.warn("Response Grade unsuccessful : " + response.getStatus()
                    + " response : " + response.getEntity(String.class));
        }
        return jsonString;
    }

    public static String getStandardJSON(String publicationKey, String gradeKey) {
        String jsonString = null;
        String token = getSSOTOken();
        String value = "Bearer " + token.trim();
        WebResource resource = CLIENT.resource(BASE_URL + PUBLICATION_PATH
                + "/" + publicationKey + "/" + STANDARD_PATH + "?grade="
                + gradeKey);
        ClientResponse response = resource.header("Authorization", value).get(
                ClientResponse.class);
        if (response.getStatus() == Status.OK.getStatusCode()) {
            jsonString = response.getEntity(String.class);
        } else {
            LOGGER.warn("Response Grade unsuccessful : " + response.getStatus()
                    + " response : " + response.getEntity(String.class));
        }
        return jsonString;
    }

    private static String getSSOTOken() {
        String token = null;
        try {
            token = SSOClient.fetchOAUTHToken();
        } catch (Exception e) {
            LOGGER.error("Error getting SSOTOken " + e.getMessage(), e);
        }
        return token;
    }

}
