package com.pacificmetrics.orca.tib;

import javax.net.ssl.SSLContext;
import javax.ws.rs.core.MediaType;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.json.JSONException;
import org.json.JSONObject;

import com.pacificmetrics.orca.utils.CertUtil;
import com.pacificmetrics.orca.utils.PropertyUtil;
import com.sun.jersey.api.client.Client;
import com.sun.jersey.api.client.ClientResponse;
import com.sun.jersey.api.client.WebResource;
import com.sun.jersey.api.client.config.ClientConfig;
import com.sun.jersey.api.client.config.DefaultClientConfig;
import com.sun.jersey.api.representation.Form;
import com.sun.jersey.client.urlconnection.HTTPSProperties;

public class SSOClient {

    private static final Log LOGGER = LogFactory.getLog(SSOClient.class);

    private SSOClient() {
    }

    private static final String GRANT_TYPE = "grant_type";
    private static final String USERNAME = "username";
    private static final String PASSWORD = "password";
    private static final String CLIENTID = "client_id";
    private static final String CLIENT_SECRET = "client_secret";

    public static SSLContext createSSLContentFromFile() {
        SSLContext sslContext = null;
        try {
            String certFile = PropertyUtil
                    .getProperty(PropertyUtil.TIB_SSO_CERT_FILE);
            sslContext = CertUtil.getSSLContextFromFile(certFile, "ssoca");
        } catch (Exception e) {
            LOGGER.error("Error loading certificate " + e.getMessage(), e);
        }
        return sslContext;
    }

    public static Client createClient() {
        SSLContext ctx = createSSLContentFromFile();
        ClientConfig config = new DefaultClientConfig();
        config.getProperties().put(HTTPSProperties.PROPERTY_HTTPS_PROPERTIES,
                new HTTPSProperties(null, ctx));
        return Client.create(config);
    }

    public static String fetchOAUTHToken() throws JSONException {
        Client client = createClient();
        WebResource resource = client.resource(PropertyUtil
                .getProperty(PropertyUtil.TIB_SSO_URL));

        Form form = new Form();
        form.add(GRANT_TYPE,
                PropertyUtil.getProperty(PropertyUtil.TIB_SSO_GRANT_TYPE));
        form.add(USERNAME,
                PropertyUtil.getProperty(PropertyUtil.TIB_SSO_USERNAME));
        form.add(PASSWORD,
                PropertyUtil.getProperty(PropertyUtil.TIB_SSO_PASSWORD));
        form.add(CLIENTID,
                PropertyUtil.getProperty(PropertyUtil.TIB_SSO_CLINETID));
        form.add(CLIENT_SECRET,
                PropertyUtil.getProperty(PropertyUtil.TIB_SSO_CLIENT_SECRET));

        ClientResponse clientResponse = resource/* .queryParams(formData) */
        .accept(MediaType.APPLICATION_JSON)
                .type(MediaType.APPLICATION_FORM_URLENCODED)
                .post(ClientResponse.class, form);
        String responseText = clientResponse.getEntity(String.class);
        String token = extractToken(responseText);

        return token;
    }

    public static String extractToken(String jsonString) throws JSONException {
        JSONObject jsonObject = new JSONObject(jsonString);
        return jsonObject.getString("access_token");
    }
}
