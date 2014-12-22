package com.pacificmetrics.orca.cts.model;

import java.io.Serializable;

public class Publication implements Serializable {

	private static final long serialVersionUID = 1L;

	private String key;

	private String fkPublisher;

	private String version;

	private String description;

	private String fkSubject;

	private String subjectLabel;

	private String status;

	public String getKey() {
		return key;
	}

	public void setKey(String key) {
		this.key = key;
	}

	public String getFkPublisher() {
		return fkPublisher;
	}

	public void setFkPublisher(String fkPublisher) {
		this.fkPublisher = fkPublisher;
	}

	public String getVersion() {
		return version;
	}

	public void setVersion(String version) {
		this.version = version;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public String getFkSubject() {
		return fkSubject;
	}

	public void setFkSubject(String fkSubject) {
		this.fkSubject = fkSubject;
	}

	public String getSubjectLabel() {
		return subjectLabel;
	}

	public void setSubjectLabel(String subjectLabel) {
		this.subjectLabel = subjectLabel;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}
	
	public String toString() {
		return "{\"key\":\""+key+"\",\"fkPublisher\":\""+fkPublisher+"\",\"version\":"+version+",\"description\":\""+description+"\",\"fkSubject\":\""+fkSubject+"\",\"subjectLabel\":\""+subjectLabel+"\",\"status\":"+status+"}";
	}

}
