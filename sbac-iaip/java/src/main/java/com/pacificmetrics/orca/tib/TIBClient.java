package com.pacificmetrics.orca.tib;

import java.io.File;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import javax.net.ssl.SSLContext;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.jcraft.jsch.Channel;
import com.jcraft.jsch.ChannelSftp;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.JSchException;
import com.jcraft.jsch.Session;
import com.jcraft.jsch.SftpException;
import com.pacificmetrics.orca.utils.CertUtil;
import com.pacificmetrics.orca.utils.PropertyUtil;
import com.sun.jersey.api.client.Client;
import com.sun.jersey.api.client.ClientHandlerException;
import com.sun.jersey.api.client.ClientResponse;
import com.sun.jersey.api.client.UniformInterfaceException;
import com.sun.jersey.api.client.WebResource;
import com.sun.jersey.api.client.config.ClientConfig;
import com.sun.jersey.api.client.config.DefaultClientConfig;
import com.sun.jersey.client.urlconnection.HTTPSProperties;
import com.sun.jersey.multipart.FormDataMultiPart;
import com.sun.jersey.multipart.file.FileDataBodyPart;

public class TIBClient {
    private static final Log LOGGER = LogFactory.getLog(TIBClient.class);

    private TIBClient() {
    }

    private static final String VERSION = "version";
    private static final String UPLOAD_FILE = "uploadFile";
    private static final String SFTP_FILE_IMPORT = "sftpFileImport";

    static {
        javax.net.ssl.HttpsURLConnection
                .setDefaultHostnameVerifier(new javax.net.ssl.HostnameVerifier() {

                    @Override
                    public boolean verify(String hostname,
                            javax.net.ssl.SSLSession sslSession) {
                        return true;
                    }
                });
    }

    public static SSLContext createSSLContextFromFile() {
        SSLContext sslContext = null;
        try {
            String certFile = PropertyUtil
                    .getProperty(PropertyUtil.TIB_API_CERT_FILE);
            sslContext = CertUtil.getSSLContextFromFile(certFile, "tibca");
        } catch (Exception e) {
            LOGGER.error("Error loading certificate " + e.getMessage(), e);
        }
        return sslContext;
    }

    public static Client createTIBClient() {
        SSLContext ctx = createSSLContextFromFile();
        ClientConfig config = new DefaultClientConfig();
        config.getProperties().put(HTTPSProperties.PROPERTY_HTTPS_PROPERTIES,
                new HTTPSProperties(null, ctx));
        return Client.create(config);
    }

    public static void callTIBVersion(String token) {
        // https://tib.dev.opentestsystem.org:8443/testitembank/version

        Client client = createTIBClient();
        WebResource resource = client.resource(PropertyUtil
                .getProperty(PropertyUtil.TIB_API_URL) + VERSION);
        String value = "Bearer " + token.trim();
        ClientResponse clientResponse = resource.header("Authorization", value)
                .get(ClientResponse.class);
        String responseText = clientResponse.getEntity(String.class);
        LOGGER.info("TIB Response " + responseText);
    }

    public static TIBResponse callImportSet(String token, String importSetId) {
        // /importSet/53c7f839e4b0e504ecbc1702
        TIBResponse response = null;
        Client client = createTIBClient();
        WebResource resource = client.resource(PropertyUtil
                .getProperty(PropertyUtil.TIB_API_URL) + importSetId);
        String value = "Bearer " + token.trim();
        ClientResponse clientResponse = resource.header("Authorization", value)
                .get(ClientResponse.class);
        if (clientResponse.getType().isCompatible(
                MediaType.APPLICATION_JSON_TYPE)) {
            String jsonResponse = clientResponse.getEntity(String.class);
            response = getResponseStatus(jsonResponse);
            LOGGER.info("TIB Response " + response);
        }
        return response;
    }

    private static TIBResponse getResponseStatus(String jsonString) {
        TIBResponse response = new TIBResponse();
        try {
            JSONObject jsonObject = new JSONObject(jsonString);
            response.setImportStatus(jsonObject.getString("importStatus"));
            JSONArray importFilesArray = jsonObject.getJSONArray("importFiles");
            List<String> messages = new ArrayList<String>();
            for (int i = 0; i < importFilesArray.length(); i++) {
                JSONObject fileStats = (JSONObject) importFilesArray.get(i);
                response.setFileImportStatus(fileStats
                        .getString("importStatus"));
                JSONObject messageStats = fileStats.getJSONObject("messages");
                Iterator iterator = messageStats.keys();
                while (iterator.hasNext()) {
                    String keyName = (String) iterator.next();
                    LOGGER.info("Key " + keyName);
                    JSONArray fileStatus = messageStats.getJSONArray(keyName);
                    for (int f = 0; f < fileStatus.length(); f++) {
                        JSONObject message = (JSONObject) fileStatus.get(f);
                        messages.add(message.getString("messageCode") + ":"
                                + message.getString("messageArgs"));
                    }
                }
                response.setMessages(messages);
            }
        } catch (JSONException e) {
            LOGGER.info(
                    "TIB Response unable to get callback url " + jsonString, e);
        } catch (Exception e) {
            LOGGER.info(
                    "TIB Response unable to get callback url " + jsonString, e);
        }
        return response;
    }

    public static String callUploadFile(String token, File file) {
        String callbackURL = null;
        Client client = createTIBClient();
        WebResource resource = client.resource(PropertyUtil
                .getProperty(PropertyUtil.TIB_API_URL) + UPLOAD_FILE);
        String value = "Bearer " + token.trim();

        FormDataMultiPart multipart = new FormDataMultiPart();
        multipart.bodyPart(new FileDataBodyPart("file", file, MediaType
                .valueOf("application/zip")));

        ClientResponse clientResponse = resource
                .queryParam("tenantId",
                        PropertyUtil.getProperty(PropertyUtil.TIB_TENANTID))
                .type(MediaType.MULTIPART_FORM_DATA_TYPE)
                .header("Authorization", value)
                .post(ClientResponse.class, multipart);
        if (clientResponse.getStatus() == 400
                && clientResponse.getType().isCompatible(
                        MediaType.APPLICATION_JSON_TYPE)) {
            String jsonString = clientResponse.getEntity(String.class);
            callbackURL = getCallbackURL(jsonString);
        }

        return callbackURL;
    }

    public static String callSFTPFileUpload(String token, String fileName) {
        String callbackURL = null;
        try {
            Client client = createTIBClient();
            WebResource resource = client.resource(PropertyUtil
                    .getProperty(PropertyUtil.TIB_API_URL) + SFTP_FILE_IMPORT);
            String value = "Bearer " + token.trim();

            JSONObject jsonRequest = new JSONObject();
            jsonRequest.put("tenantId",
                    PropertyUtil.getProperty(PropertyUtil.TIB_TENANTID));

            JSONObject jsonFile = new JSONObject();
            jsonFile.put("pathName", fileName);
            JSONArray jsonArray = new JSONArray();
            jsonArray.put(jsonFile);
            jsonRequest.put("importFiles", jsonArray);
            String jsonString = jsonRequest.toString();

            ClientResponse clientResponse = resource

            .type(MediaType.APPLICATION_JSON_TYPE)
                    .header("Authorization", value)
                    .post(ClientResponse.class, jsonRequest.toString());
            if (clientResponse.getType().isCompatible(
                    MediaType.APPLICATION_JSON_TYPE)) {
                jsonString = clientResponse.getEntity(String.class);
                callbackURL = getCallbackURL(jsonString);
            }

        } catch (UniformInterfaceException e) {
            LOGGER.error("Error in persing callback url " + e.getMessage(), e);
        } catch (ClientHandlerException e) {
            LOGGER.error("Error in persing callback url " + e.getMessage(), e);
        } catch (JSONException e) {
            LOGGER.error("Error in persing json string " + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.error("Error in persing callback url " + e.getMessage(), e);
        }
        return callbackURL;
    }

    public static String getCallbackURL(String jsonString) {
        String callbackurl = null;
        try {
            JSONObject jsonObject = new JSONObject(jsonString);
            callbackurl = jsonObject.getString("url");
        } catch (JSONException e) {
            LOGGER.info(
                    "TIB Response unable to get callback url " + jsonString, e);
        } catch (Exception e) {
            LOGGER.info(
                    "TIB Response unable to get callback url " + jsonString, e);
        }
        return callbackurl;
    }

    public static void ftpPackage(InputStream is, String fileName) {
        final String tibSftpHost = PropertyUtil
                .getProperty(PropertyUtil.TIB_FTP_HOST);
        final String tibSftpUsr = PropertyUtil
                .getProperty(PropertyUtil.TIB_FTP_USERNAME);
        final String tibSftpPass = PropertyUtil
                .getProperty(PropertyUtil.TIB_FTP_PASSWORD);

        try {
            JSch jsch = new JSch();
            Session session = null;
            session = jsch.getSession(tibSftpUsr, tibSftpHost);
            session.setConfig("StrictHostKeyChecking", "no");
            session.setPassword(tibSftpPass);
            session.connect();
            Channel channel = session.openChannel("sftp");
            channel.connect();
            ChannelSftp sftpChannel = (ChannelSftp) channel;
            sftpChannel.cd(PropertyUtil.getProperty(PropertyUtil.TIB_FTP_DIR));
            sftpChannel.put(is, fileName);
            sftpChannel.exit();
            session.disconnect();
        } catch (JSchException e) {
            LOGGER.info(e.getMessage(), e);
            final Response errorResponse = Response
                    .status(Status.BAD_REQUEST)
                    .entity("Could not connect to Test item bank: "
                            + e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        } catch (SftpException e) {
            LOGGER.info(e.getMessage(), e);
            final Response errorResponse = Response
                    .status(Status.BAD_REQUEST)
                    .entity("Could not connect to Test item bank: "
                            + e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        }
    }
}
