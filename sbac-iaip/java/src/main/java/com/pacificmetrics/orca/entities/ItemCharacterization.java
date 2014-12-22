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

@Entity
//@Inheritance(strategy=InheritanceType.JOINED)
//@DiscriminatorColumn(name="ic_type")
@Table(name="item_characterization")
@NamedQueries({
	@NamedQuery(name="IC.IC_BY_ITEM", query="SELECT ic FROM ItemCharacterization ic WHERE ic.itemId = :id"),
	@NamedQuery(name="IC.IC_FOR_PASSAGE", query="SELECT ic FROM ItemCharacterization ic WHERE ic.itemId = :itemId AND ic.type = :type"),
	@NamedQuery(name="IC.IC_FOR_PASSAGE_BY_ID", query="SELECT ic FROM ItemCharacterization ic WHERE ic.intValue = :passageId AND ic.type = :type")
})
@IdClass(ItemCharacterizationPK.class)
public class ItemCharacterization implements Serializable {
	
	private static final long serialVersionUID = 1L;

	@Id
	@Column(name="i_id")
	private long itemId;
	
	@Id
	@Column(name="ic_type")
	private int type;
	
	@Basic
	@Column(name="ic_value")
	private int intValue;
	

	public long getItemId() {
		return itemId;
	}

	public void setItemId(long itemId) {
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
