package com.pacificmetrics.orca.cts.model;

import java.io.Serializable;
import java.util.List;

public class Category implements Serializable {

	private static final long serialVersionUID = 1L;

	private String name;
	
	private String treeLevel;
	
	private String fkPublication;
	
	private String level;
	
	private List<Standard> standardList;

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getTreeLevel() {
		return treeLevel;
	}

	public void setTreeLevel(String treeLevel) {
		this.treeLevel = treeLevel;
	}

	public String getFkPublication() {
		return fkPublication;
	}

	public void setFkPublication(String fkPublication) {
		this.fkPublication = fkPublication;
	}
	
	/**
	 * @return the level
	 */
	public String getLevel() {
		return level;
	}

	/**
	 * @param level the level to set
	 */
	public void setLevel(String level) {
		this.level = level;
	}

	/**
	 * @return the standardList
	 */
	public List<Standard> getStandardList() {
		return standardList;
	}

	/**
	 * @param standardList the standardList to set
	 */
	public void setStandardList(List<Standard> standardList) {
		this.standardList = standardList;
	}

	public String toString() {
		return "{\"name\":\""+name+"\",\"treeLevel\":"+treeLevel+",\"fkPublication\":\""+fkPublication+"\"}";
	}
}
