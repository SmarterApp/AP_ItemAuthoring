package com.pacificmetrics.orca.utils;

import java.io.File;


import com.pacificmetrics.orca.ServerConfiguration;
import com.pacificmetrics.orca.entities.ItemBankMetafile;

public class IBMetafileUtils {

	static public String getMetafileDirName(int ibId) {
		String prefix = ServerConfiguration.getProperty(ServerConfiguration.ITEM_BANK_METAFILE_DIR_PREFIX); 
		return ServerConfiguration.getProperty(ServerConfiguration.ITEM_BANK_METAFILE_DIR) + File.separator + prefix + ibId;
	}
	
	static public String getMetafileURL(int ibId) {
		String prefix = ServerConfiguration.getProperty(ServerConfiguration.ITEM_BANK_METAFILE_DIR_PREFIX); 
		return ServerConfiguration.getProperty(ServerConfiguration.ITEM_BANK_METAFILE_URL) + "/" + prefix + ibId;
	}
	
	static public String getMetafileURL(ItemBankMetafile ibm) {
		return getMetafileURL(ibm.getItemBankId()) + "/" + ibm.getSystemName();
	}

}
