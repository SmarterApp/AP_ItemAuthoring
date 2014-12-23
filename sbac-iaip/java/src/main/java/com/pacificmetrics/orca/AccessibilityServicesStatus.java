package com.pacificmetrics.orca;

import com.pacificmetrics.common.Status;

public class AccessibilityServicesStatus extends Status {
	
	protected AccessibilityServicesStatus(String name) {
		super(name);
	}

	static final public AccessibilityServicesStatus FEATURE_NOT_FOUND = new AccessibilityServicesStatus("FEATURE_NOT_FOUND");

}
