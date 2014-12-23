package com.pacificmetrics.orca.cts.model;

import java.io.Serializable;
import java.util.List;


public class CTSResponse  implements Serializable {

	private static final long serialVersionUID = 1L;

	private String status;
	
	private List<Object> errors;
	
	private List<Object> warnings;
	
	private List<Object> validationsPassed;
	
	private String payload;

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public List<Object> getErrors() {
		return errors;
	}

	public void setErrors(List<Object> errors) {
		this.errors = errors;
	}

	public List<Object> getWarnings() {
		return warnings;
	}

	public void setWarnings(List<Object> warnings) {
		this.warnings = warnings;
	}

	public List<Object> getValidationsPassed() {
		return validationsPassed;
	}

	public void setValidationsPassed(List<Object> validationsPassed) {
		this.validationsPassed = validationsPassed;
	}

	public String getPayload() {
		return payload;
	}

	public void setPayload(String payload) {
		this.payload = payload;
	}
	
	
}
