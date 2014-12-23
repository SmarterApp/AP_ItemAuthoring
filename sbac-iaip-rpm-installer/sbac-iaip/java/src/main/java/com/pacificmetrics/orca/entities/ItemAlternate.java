package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;
import javax.validation.constraints.Size;

@Entity
@Table(name = "item_alternate")
@NamedQueries({
		@NamedQuery(name = "alternatesByItemId", query = "select a from ItemAlternate a where a.itemId = :i_id"),
		@NamedQuery(name = "alternateByAlternateItemId", query = "select a from ItemAlternate a where a.alternateItemId = :ia_alternate_i_id") })
public class ItemAlternate implements Serializable {

	private static final long serialVersionUID = 1L;

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "ia_id")
	private int id;

	@Basic
	@Column(name = "i_id")
	private int itemId;

	@Basic
	@Column(name = "ia_alternate_i_id")
	private int alternateItemId;

	@Basic
	@Column(name = "ia_alternate_label")
	@Size(max = 50)
	private String alternateType;

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public int getItemId() {
		return itemId;
	}

	public void setItemId(int itemId) {
		this.itemId = itemId;
	}

	public int getAlternateItemId() {
		return alternateItemId;
	}

	public void setAlternateItemId(int alternateItemId) {
		this.alternateItemId = alternateItemId;
	}

	public String getAlternateType() {
		return alternateType;
	}

	public void setAlternateType(String alternateType) {
		this.alternateType = alternateType;
	}
}
