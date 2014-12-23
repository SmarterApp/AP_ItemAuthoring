/**
 * 
 */
package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;

/**
 * Basic entity class for the item move type object.
 * @author arindam.majumdar
 *
 */

@Entity
@Table(name = "item_move_type")
public class ItemMoveType implements Serializable {

	private static final long serialVersionUID = 1L;
	
	@Id
    @Column(name = "imt_id")
    private long id;

    @Basic
    @Column(name = "imt_name")
    private String name;

	/**
	 * @return the id
	 */
	public long getId() {
		return id;
	}

	/**
	 * @param id the id to set
	 */
	public void setId(long id) {
		this.id = id;
	}

	/**
	 * @return the name
	 */
	public String getName() {
		return name;
	}

	/**
	 * @param name the name to set
	 */
	public void setName(String name) {
		this.name = name;
	}
}
