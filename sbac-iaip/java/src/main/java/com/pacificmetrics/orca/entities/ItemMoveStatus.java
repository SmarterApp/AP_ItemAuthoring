/**
 * 
 */
package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;

/**
 * Basic entity class for the item move status object.
 * @author arindam.majumdar
 *
 */

@Entity
@NamedQueries({
	@NamedQuery(name = "ItemMoveStatus.dataByStatus", query = "SELECT ims FROM ItemMoveStatus ims WHERE ims.status = :status")
})
@Table(name = "item_move_status")
public class ItemMoveStatus implements Serializable {

	private static final long serialVersionUID = 1L;
	
	@Id
    @Column(name = "ims_id")
    private long id;

    @Basic
    @Column(name = "ims_value")
    private String status;

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
	 * @return the status
	 */
	public String getStatus() {
		return status;
	}

	/**
	 * @param status the status to set
	 */
	public void setStatus(String status) {
		this.status = status;
	}
}
