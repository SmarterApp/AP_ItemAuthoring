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
@Table(name="item_bank")
@NamedQueries({
	@NamedQuery(name="allItemBanks", 
		    query="select ib from ItemBank ib")
})
public class ItemBank implements Serializable {

	private static final long serialVersionUID = 1L;

	@Id
	@Column(name="ib_id")
	private int id;
	
	@Basic
	@Column(name="ib_external_id")
	private String externalId;
	
	@Basic
	@Column(name="ib_description")
	private String description;

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String getExternalId() {
		return externalId;
	}

	public void setExternalId(String externalId) {
		this.externalId = externalId;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}
	
	@Override
	public String toString() {
		return externalId;
	}

}
