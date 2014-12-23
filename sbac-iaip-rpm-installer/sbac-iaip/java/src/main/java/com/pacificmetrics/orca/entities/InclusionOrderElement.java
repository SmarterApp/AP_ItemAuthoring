package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;

@Entity
@Table(name="inclusion_order_element")
@NamedQueries({
	@NamedQuery(name="ioeByInclusionOrderId", 
		        query="select ioe from InclusionOrderElement ioe where ioe.inclusionOrderId = :io_id")
})

public class InclusionOrderElement implements Serializable {

	private static final long serialVersionUID = 1L;
	
	@Id
    @GeneratedValue(strategy=GenerationType.IDENTITY)
	@Column(name="ioe_id")
	private int id;
	
	@Basic
	@Column(name="ae_id")
	private int accessibilityElementId;
	
	@Basic
	@Column(name="ioe_sequence")
	private int sequence;
	
	@ManyToOne(fetch=FetchType.LAZY)
	@JoinColumn(name="io_id")
	private InclusionOrder inclusionOrder;

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public int getAccessibilityElementId() {
		return accessibilityElementId;
	}

	public void setAccessibilityElementId(int accessibilityElementId) {
		this.accessibilityElementId = accessibilityElementId;
	}

	public int getSequence() {
		return sequence;
	}

	public void setSequence(int sequence) {
		this.sequence = sequence;
	}

	public InclusionOrder getInclusionOrder() {
		return inclusionOrder;
	}

	public void setInclusionOrder(InclusionOrder inclusionOrder) {
		this.inclusionOrder = inclusionOrder;
	}

	
}
