package com.pacificmetrics.orca;

import java.util.Arrays;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.logging.Logger;

import javax.servlet.ServletContextEvent;

import org.apache.commons.configuration.ConfigurationException;
import org.apache.commons.configuration.PropertiesConfiguration;

/**
 * 
 * @author amiliteev
 * 
 */
public class ServerConfiguration implements
        javax.servlet.ServletContextListener {

    private static final Logger LOGGER = Logger
            .getLogger(ServerConfiguration.class.getName());

    private static PropertiesConfiguration properties = new PropertiesConfiguration();

    private static final String MY_ENV = System.getProperty("my.env", "");
    private static final String PROP_FILE_NAME_1 = "server"
            + (MY_ENV.isEmpty() ? "-dev" : '-' + MY_ENV) + ".properties";
    private static final String PROP_FILE_NAME_2 = "server.properties";

    public static final String APPLICATION_NAME = "application.name";

    public static final String HTTP_SERVER_URL = "http-server.url";
    public static final String HTTP_SERVER_ROOT_URL = "http-server.root.url";
    public static final String HTTP_SERVER_CGI_BIN_URL = "http-server.cgi-bin.url";

    public static final String TIB_SFTP_HOST = "tib.sftp.host";
    public static final String TIB_SFTP_USER = "tib.sftp.user";
    public static final String TIB_SFTP_PASSWD = "tib.sftp.passwd";

    public static final String TIB_SERVICE_BASE_URL = "tib.service.base.url";

    public static final String ITEM_BANK_METAFILE_PATH = "itembank.metafiles.path";
    public static final String ITEM_BANK_METAFILE_URL = "itembank.metafiles.url";
    public static final String ITEM_BANK_METAFILE_DIR = "itembank.metafiles.directory";
    public static final String ITEM_BANK_METAFILE_DIR_PREFIX = "itembank.metafiles.directory.prefix";

    public static final String ITEM_BANK_METAFILE_MIME_TYPES_DISALLOWED = "itembank.metafiles.mime.types.disallowed";

    public static final String PASSAGES_DIRECTORY = "passages.directory";

    public static final String FTP_IMPORT_EXPRESSION = "ftpimp.expression";
    public static final String FTP_IMPORT_SOURCE = "ftpimp.source";
    public static final String FTP_IMPORT_ARCHIVE = "ftpimp.archive.source";
    public static final String FTP_IMPORT_LIB = "ftpimp.lib";
    public static final String FTP_IMPORT_LOG = "ftpimp.log";
    public static final String FTP_IMPORT_UPLOAD = "ftpimp.upload";

    public static final String CTS_ENDPOINT = "cts.enpoint";
    public static final String CTS_EXPRESSION = "cts.expression";
    public static final String CTS_CERT_FILE = "cts.cert.file";
    public static final String CTS_KEYSTORE_FILE = "cts.keystore.file";
    public static final String CTS_KEYSTORE_PASS = "cts.keystore.pass";
    public static final String CTS_CACHE_ENABLE = "cts.cache.enable";

    public static final String TIB_API_CERT_FILE = "tib.api.cert.file";
    public static final String TIB_API_KEYSTORE = "tib.api.keystore.file";
    public static final String TIB_API_KEY_PASS = "tib.api.keystore.pass";

    public static final String TIB_SSO_CERT_FILE = "tib.sso.cert.file";
    public static final String TIB_SSO_KEYSTORE = "tib.sso.keystore.file";
    public static final String TIB_SSO_KEY_PASS = "tib.sso.keystore.pass";

    public static final String TIB_SSO_URL = "tib.sso.url";
    public static final String TIB_SSO_GRANT_TYPE = "tib.sso.granttype";
    public static final String TIB_SSO_USERNAME = "tib.sso.username";
    public static final String TIB_SSO_PASSWORD = "tib.sso.password";
    public static final String TIB_SSO_CLINETID = "tib.sso.clientid";
    public static final String TIB_SSO_CLIENT_SECRET = "tib.sso.clientsecret";

    public static final String TIB_FTP_HOST = "tib.ftp.host";
    public static final String TIB_FTP_PORT = "tib.ftp.port";
    public static final String TIB_FTP_USERNAME = "tib.ftp.username";
    public static final String TIB_FTP_PASSWORD = "tib.ftp.password";
    public static final String TIB_FTP_DIR = "tib.ftp.dir";

    public static final String TIB_API_URL = "tib.api.url";
    public static final String TIB_TENANTID = "tib.tenantid";

    public static final String INSTANCE_NAME = "app.instance.name";
    public static final String WEB_DIR = "web.dir";
    public static final String RESOURCE_DIR = "resource.dir";
    public static final String RESOURCE_PASSAGE_PREFIX = "resource.passage.prefix";
    public static final String RESOURCE_LIB_PREFIX = "resource.lib.prefix";
    public static final String RESOURCE_ATTACHMENT_DIR = "resource.attachment.dir";
    public static final String RESOURCE_IMAGE_DIR = "resource.image.dir";
    public static final String RESOURCE_MEDIA_DIR = "resource.media.dir";
    public static final String RESOURCE_PASSAGE_DIR = "resource.passage.dir";
    public static final String RESOURCE_RUBRIC_DIR = "resource.rubric.dir";
    public static final String RESOURCE_WORDLIST_DIR = "resource.wordlist.dir";

    static synchronized void load() {

        LOGGER.info("Loading properties from " + PROP_FILE_NAME_1 + ", "
                + PROP_FILE_NAME_2);
        try {
            properties.append(new PropertiesConfiguration(PROP_FILE_NAME_1));
        } catch (ConfigurationException e) {
            LOGGER.warning("Can't load environment-specific sever properties: "
                    + e);
        }
        try {
            properties.append(new PropertiesConfiguration(PROP_FILE_NAME_2));
        } catch (ConfigurationException e) {
            LOGGER.warning("Can't load common server properties: " + e);
        }

        for (Iterator<String> ii = properties.getKeys(); ii.hasNext();) {
            String key = ii.next();
            LOGGER.info(key + " = " + getProperty(key));
        }

    }

    public static String getProperty(String name) {
        String result = System.getProperty(name);
        if (result != null) {
            return result;
        }
        result = properties.getString(name.replaceAll("/", "."));
        return result != null ? result : "";
    }

    public static List<String> getPropertyAsList(String name) {
        String strValue = getProperty(name);
        if (strValue.trim().isEmpty()) {
            return Collections.emptyList();
        }
        return Arrays.asList(strValue.split("\\s"));
    }

    @Override
    public void contextDestroyed(ServletContextEvent arg0) {
        properties.clear();
        properties = null;
    }

    @Override
    public void contextInitialized(ServletContextEvent arg0) {
        load();
    }

    public static boolean isLocalOrDev() {
        return isLocal() || isDev();
    }

    public static boolean isLocal() {
        return checkEnvironment("local");
    }

    public static boolean isDev() {
        return checkEnvironment("dev");
    }

    public static boolean checkEnvironment(String env) {
        return MY_ENV.equalsIgnoreCase(env);
    }

    public static String getEnvironment() {
        return MY_ENV;
    }

}
