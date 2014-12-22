/**
 * 
 */
package com.pacificmetrics.orca.entities;

import java.io.Serializable;

/**
 * @author root
 *
 */
public class ObjectCharacterizationPK implements Serializable {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	private long objectId;
	private int objectType;
	
	/**
	 * 
	 */
	public ObjectCharacterizationPK() {
		// TODO Auto-generated constructor stub
	}

	public long getObjectId() {
		return objectId;
	}

	public void setObjectId(long objectId) {
		this.objectId = objectId;
	}

	public int getObjectType() {
		return objectType;
	}

	public void setObjectType(int objectType) {
		this.objectType = objectType;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + (int) (objectId ^ (objectId >>> 32));
		result = prime * result + objectType;
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
		ObjectCharacterizationPK other = (ObjectCharacterizationPK) obj;
		if (objectId != other.objectId) {
			return false;
		}
		if (objectType != other.objectType) {
			return false;
		}
		return true;
	}
	
	

}
