package com.pacificmetrics.orca.cts.model;

import java.io.Serializable;

public class Grade implements Serializable {

	private static final long serialVersionUID = 1L;

	private String key;
	
	private String name;
	
	private String description;

	public String getKey() {
		return key;
	}

	public void setKey(String key) {
		this.key = key;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}
	
	
	public String toString() {
		return "{\"key\":\""+key+"\",\"name\":\""+name+"\",\"description\":\""+description+"\"}";
	}
}
