package com.pacificmetrics.orca;

import com.pacificmetrics.common.Status;

public class ORCAStatus extends Status {
	
	static final public ORCAStatus SESSION_NOT_FOUND = new ORCAStatus("SESSION_NOT_FOUND");

	protected ORCAStatus(String name) {
		super(name);
	}

}
