package com.pacificmetrics.orca;

import com.pacificmetrics.common.Status;

public class IBMetafileServicesStatus extends Status {
	
	protected IBMetafileServicesStatus(String name) {
		super(name);
	}

	static final public IBMetafileServicesStatus NOTHING_TO_PROCESS = new IBMetafileServicesStatus("NOTHING_TO_PROCESS");
	static final public IBMetafileServicesStatus ITEM_NOT_FOUND = new IBMetafileServicesStatus("ITEM_NOT_FOUND");
	static final public IBMetafileServicesStatus PASSAGE_NOT_FOUND = new IBMetafileServicesStatus("PASSAGE_NOT_FOUND");
	static final public IBMetafileServicesStatus METAFILE_NOT_FOUND = new IBMetafileServicesStatus("METAFILE_NOT_FOUND");
	static final public IBMetafileServicesStatus METAFILE_ALREADY_ASSOCIATED = new IBMetafileServicesStatus("METAFILE_ALREADY_ASSOCIATED");
	static final public IBMetafileServicesStatus ASSOCIATION_NOT_FOUND = new IBMetafileServicesStatus("ASSOCIATION_NOT_FOUND");
	static final public IBMetafileServicesStatus ITEM_BANKS_NOT_MATCH = new IBMetafileServicesStatus("ITEM_BANKS_NOT_MATCH");
	static final public IBMetafileServicesStatus METAFILE_NAME_ALREADY_EXISTS = new IBMetafileServicesStatus("METAFILE_NAME_ALREADY_EXISTS");
	static final public IBMetafileServicesStatus METAFILE_NEWER_VERSION_EXISTS = new IBMetafileServicesStatus("METAFILE_NEWER_VERSION_EXISTS");
	static final public IBMetafileServicesStatus METAFILE_MIME_TYPE_DISALLOWED = new IBMetafileServicesStatus("METAFILE_MIME_TYPE_DISALLOWED");
	static final public IBMetafileServicesStatus METAFILE_NAME_TOO_LONG = new IBMetafileServicesStatus("METAFILE_NAME_TOO_LONG");

}
