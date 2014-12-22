package com.pacificmetrics.orca;

import com.pacificmetrics.common.Status;

public class ItemBankServicesStatus extends Status {
	
	protected ItemBankServicesStatus(String name) {
		super(name);
	}

	static final public IBMetafileServicesStatus ITEM_BANK_NOT_FOUND = new IBMetafileServicesStatus("ITEM_BANK_NOT_FOUND");

}
