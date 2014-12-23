package com.pacificmetrics.orca.cts.model;

import java.io.Serializable;

public class Subject implements Serializable {
	
	private static final long serialVersionUID = 1L;

	private String key;
	
	private String name;
	
	private String code;

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

	public String getCode() {
		return code;
	}

	public void setCode(String code) {
		this.code = code;
	}
	
	public String toString() {
		return "{\"key\":\""+key+"\",\"name\":\""+name+"\",\"code\":\""+code+"\"}";
	}
}
