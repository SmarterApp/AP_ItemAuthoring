package com.pacificmetrics.orca.entities;

import java.io.Serializable;


public class ItemBankMetafilePK implements Serializable {

	private static final long serialVersionUID = 1L;
	
	private int id;
	private int version;
	
	public ItemBankMetafilePK(int id, int version) {
		super();
		this.id = id;
		this.version = version;
	}

	public ItemBankMetafilePK() {
	}
	
	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}
	
	public int getVersion() {
		return version;
	}
	
	public void setVersion(int version) {
		this.version = version;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + id;
		result = prime * result + version;
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj) {
			return true;
		}
		if (obj == null) {
			return false;
		}
		if (!(obj instanceof ItemBankMetafilePK)) {
			return false;
		}
		ItemBankMetafilePK other = (ItemBankMetafilePK) obj;
		if (id != other.id) {
			return false;
		}
		if (version != other.version) {
			return false;
		}
		return true;
	}
	
}
