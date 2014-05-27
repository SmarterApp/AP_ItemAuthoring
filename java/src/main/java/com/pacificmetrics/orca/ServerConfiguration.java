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
public class ServerConfiguration implements javax.servlet.ServletContextListener {
	
	static private Logger logger = Logger.getLogger(ServerConfiguration.class.getName()); 

	static private PropertiesConfiguration properties = new PropertiesConfiguration();
	
	static private final String MY_ENV = System.getProperty("my.env", "");
	static private final String PROP_FILE_NAME_1 = "server" + (MY_ENV.isEmpty() ? "-dev" : '-' + MY_ENV) + ".properties";
	static private final String PROP_FILE_NAME_2 = "server.properties";
	
	static public final String APPLICATION_NAME = "application.name";
	
	static public final String HTTP_SERVER_URL = "http-server.url"; 
	static public final String HTTP_SERVER_ROOT_URL = "http-server.root.url"; 
	static public final String HTTP_SERVER_CGI_BIN_URL = "http-server.cgi-bin.url";
	
	static public final String TIB_SFTP_HOST = "tib.sftp.host";
	static public final String TIB_SFTP_USER = "tib.sftp.user";
	static public final String TIB_SFTP_PASSWD = "tib.sftp.passwd";
	
	static public final String TIB_SERVICE_BASE_URL = "tib.service.base.url";
	
	static public final String ITEM_BANK_METAFILE_PATH = "itembank.metafiles.path";
	static public final String ITEM_BANK_METAFILE_URL = "itembank.metafiles.url";
	static public final String ITEM_BANK_METAFILE_DIR = "itembank.metafiles.directory";
	static public final String ITEM_BANK_METAFILE_DIR_PREFIX = "itembank.metafiles.directory.prefix";
	
	static public final String ITEM_BANK_METAFILE_MIME_TYPES_DISALLOWED = "itembank.metafiles.mime.types.disallowed";
	
	static public final String PASSAGES_DIRECTORY = "passages.directory";
	
	static synchronized void load() {
			
	    logger.info("Loading properties from " + PROP_FILE_NAME_1 + ", " + PROP_FILE_NAME_2);
//	    properties = new PropertiesConfiguration();
	    try {
	        properties.append(new PropertiesConfiguration(PROP_FILE_NAME_1));
	    } catch (ConfigurationException e) {
	        logger.warning("Can't load environment-specific sever properties: " + e);
	    }  
        try {
            properties.append(new PropertiesConfiguration(PROP_FILE_NAME_2));
        } catch (ConfigurationException e) {
            logger.warning("Can't load common server properties: " + e);
        }  

	    for (Iterator<String> ii = properties.getKeys(); ii.hasNext(); ) {
	        String key = ii.next();
	        logger.info(key + " = " + getProperty(key));
	    }
	        
	}
	
	static public String getProperty(String name) {
	    String result = System.getProperty(name);
	    if (result != null) {
	        return result;
	    }
		result = properties.getString(name.replaceAll("/", "."));
		return result != null ? result : ""; 
	}
	
	static public List<String> getPropertyAsList(String name) {
		String strValue = getProperty(name);
		if (strValue.trim().isEmpty()) {
			return Collections.emptyList();
		}
		return Arrays.asList(strValue.split("\\s"));
	}

	@Override
	public void contextDestroyed(ServletContextEvent arg0) {
	    properties.clear();
	    properties=null;
	}

	@Override
	public void contextInitialized(ServletContextEvent arg0) {
		load();
	}
	
	static public boolean isLocalOrDev() {
	    return isLocal() || isDev();
	}
	
	static public boolean isLocal() {
        return checkEnvironment("local");
    }

	static public boolean isDev() {
        return checkEnvironment("dev");
    }

    static public boolean checkEnvironment(String env) {
        return MY_ENV.equalsIgnoreCase(env);
    }

    static public String getEnvironment() {
        return MY_ENV;
    }

}
