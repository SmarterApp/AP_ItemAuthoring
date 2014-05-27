package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.DiscriminatorColumn;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.IdClass;
import javax.persistence.Inheritance;
import javax.persistence.InheritanceType;
import javax.persistence.Table;

@Entity
//@Inheritance(strategy=InheritanceType.JOINED)
//@DiscriminatorColumn(name="ic_type")
@Table(name="item_characterization")
@IdClass(ItemCharacterizationPK.class)
public class ItemCharacterization implements Serializable {
	
	private static final long serialVersionUID = 1L;

	@Id
	@Column(name="i_id")
	private int itemId;
	
	@Id
	@Column(name="ic_type")
	private int type;
	
	@Basic
	@Column(name="ic_value")
	private int intValue;

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

	public int getIntValue() {
		return intValue;
	}

	public void setIntValue(int intValue) {
		this.intValue = intValue;
	}

}
