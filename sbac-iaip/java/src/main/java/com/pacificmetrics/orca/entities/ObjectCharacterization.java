/**
 * 
 */
package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.IdClass;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;

/**
 * @author root
 *
 */
@Entity
@Table(name="object_characterization")
@NamedQueries({
	@NamedQuery(name = "ObjectCharacterization.OC_BY_PASSAGE", query = "SELECT oc FROM ObjectCharacterization oc WHERE oc.objectId = :id")
})
@IdClass(ObjectCharacterizationPK.class)
public class ObjectCharacterization implements Serializable {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	@Id
	@Column(name="oc_object_type")
	private int objectType;
	
	@Id
	@Column(name="oc_object_id")
	private long objectId;
	
	@Basic
	@Column(name="oc_int_value")
	private int intValue;
	
	@Basic
	@Column(name="oc_characteristic")
	private int characteristic;
	
	/**
	 * 
	 */
	public ObjectCharacterization() {
		// TODO Auto-generated constructor stub
	}

	public int getObjectType() {
		return objectType;
	}

	public void setObjectType(int objectType) {
		this.objectType = objectType;
	}

	public long getObjectId() {
		return objectId;
	}

	public void setObjectId(long objectId) {
		this.objectId = objectId;
	}

	public int getIntValue() {
		return intValue;
	}

	public void setIntValue(int intValue) {
		this.intValue = intValue;
	}

	/**
	 * @return the characteristic
	 */
	public int getCharacteristic() {
		return characteristic;
	}

	/**
	 * @param characteristic the characteristic to set
	 */
	public void setCharacteristic(int characteristic) {
		this.characteristic = characteristic;
	}

		
}
