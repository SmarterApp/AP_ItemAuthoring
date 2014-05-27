package com.pacificmetrics.common;

import java.util.HashMap;
import java.util.Map;

public class MultipleResults<T> extends SingleResult {
	
	private Map<T, Status> statusMap;
	
	public MultipleResults(Status status) {
		super(status);
	}
	public MultipleResults() {
		this(Status.OK);
		statusMap = new HashMap<T, Status>();
	}
	
	public Map<T, Status> getStatusMap() {
		return statusMap;
	}
	
	public void add(T t, Status status) {
		statusMap.put(t, status);
	}
	
	public boolean isAllSuccess() {
	    for (Status status: statusMap.values()) {
	        if (status != Status.OK) {
	            return false;
	        }
	    }
	    return true;
	}

}
