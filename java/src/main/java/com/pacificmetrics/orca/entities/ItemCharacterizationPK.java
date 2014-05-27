package com.pacificmetrics.orca.entities;

import java.io.Serializable;

public class ItemCharacterizationPK implements Serializable {
	
	private static final long serialVersionUID = 1L;

	private int itemId;
	private int type;
	
	public ItemCharacterizationPK() {
	}
	
	public int getItemId() {
		return itemId;
	}
	
	public void setItemId(int itemId) {
		this.itemId = itemId;
	}
	
	public int getType() {
		return type;
	}
	
	public void setType(int type) {
		this.type = type;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + itemId;
		result = prime * result + type;
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
		if (!(obj instanceof ItemCharacterizationPK)) {
			return false;
		}
		ItemCharacterizationPK other = (ItemCharacterizationPK) obj;
		if (itemId != other.itemId) {
			return false;
		}
		if (type != other.type) {
			return false;
		}
		return true;
	}

}
