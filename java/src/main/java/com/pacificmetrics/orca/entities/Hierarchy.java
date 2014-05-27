package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;

@Entity
@Table(name="hierarchy_definition")
@NamedQueries({
    @NamedQuery(name="allHierarchies", 
                query="select h from Hierarchy h")               
})
public class Hierarchy implements Serializable {

	private static final long serialVersionUID = 1L;
	
	@Id
	@Column(name="hd_id")
	private int id;
	
	@Basic
	@Column(name="hd_value")
	private String name;
	
	@Basic
	@Column(name="hd_parent_id")
	private int parentId;

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public int getParentId() {
		return parentId;
	}

	public void setParentId(int parentId) {
		this.parentId = parentId;
	}
	

}
