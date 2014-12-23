package com.pacificmetrics.common;

public class SingleResult extends OperationResult {
	
	protected Status status;
	private String info;

	public SingleResult(Status status) {
		super();
		this.status = status;
	}
	
	public SingleResult(Status status, String info) {
		super();
		this.status = status;
		this.info = info;
	}

	public Status getStatus() {
		return status;
	}

	public String getInfo() {
		return info;
	}
	
	public boolean isSuccess() {
		return status == Status.OK;
	}

	public void setStatus(Status status) {
		this.status = status;
	}

	public void setInfo(String info) {
		this.info = info;
	}
	
	@Override
	public String toString() {
	    return status.toString() + (info != null ? ": " + info : "");
	}
	
}
