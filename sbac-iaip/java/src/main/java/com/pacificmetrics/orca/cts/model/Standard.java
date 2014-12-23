package com.pacificmetrics.orca.cts.model;

import java.io.Serializable;

public class Standard implements Serializable {

	private static final long serialVersionUID = 1L;

	private String key;
	
	private String name;
	
	private String fkParent;
	
	private String fkPublication;
	
	private String fkGradeLevel;
	
	private String description;
	
	private String treeLevel;
	
	private String shortName;

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

	public String getFkParent() {
		return fkParent;
	}

	public void setFkParent(String fkParent) {
		this.fkParent = fkParent;
	}

	public String getFkPublication() {
		return fkPublication;
	}

	public void setFkPublication(String fkPublication) {
		this.fkPublication = fkPublication;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public String getTreeLevel() {
		return treeLevel;
	}

	public void setTreeLevel(String treeLevel) {
		this.treeLevel = treeLevel;
	}

	public String getFkGradeLevel() {
		return fkGradeLevel;
	}

	public void setFkGradeLevel(String fkGradeLevel) {
		this.fkGradeLevel = fkGradeLevel;
	}

	public String getShortName() {
		return shortName;
	}

	public void setShortName(String shortName) {
		this.shortName = shortName;
	}
	
	public String toString() {
		return "{\"key\":\""+key+"\",\"name\":\""+name+"\",\"fkParent\":\""+fkParent+"\",\"fkPublication\":\""+fkPublication+"\",\"description\":\""+description+"\",\"treeLevel\":"+treeLevel+",\"fkGradeLevel\":\""+fkGradeLevel+"\",\"shortName\":\""+shortName+"\"}";
	}
	
	
}
