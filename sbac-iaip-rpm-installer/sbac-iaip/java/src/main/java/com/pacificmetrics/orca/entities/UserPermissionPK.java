package com.pacificmetrics.orca.entities;

import java.io.Serializable;

public class UserPermissionPK implements Serializable {

	private static final long serialVersionUID = 1L;
	
	private int userId;
	private int type;
	private int value;
	
	public int getUserId() {
		return userId;
	}
	
	public void setUserId(int userId) {
		this.userId = userId;
	}
	
	public int getType() {
		return type;
	}
	
	public void setType(int type) {
		this.type = type;
	}
	
	public int getValue() {
		return value;
	}
	
	public void setValue(int value) {
		this.value = value;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + type;
		result = prime * result + userId;
		result = prime * result + value;
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
		if (getClass() != obj.getClass()) {
			return false;
		}
		UserPermissionPK other = (UserPermissionPK) obj;
		if (type != other.type) {
			return false;
		}
		if (userId != other.userId) {
			return false;
		}
		if (value != other.value) {
			return false;
		}
		return true;
	}

}
