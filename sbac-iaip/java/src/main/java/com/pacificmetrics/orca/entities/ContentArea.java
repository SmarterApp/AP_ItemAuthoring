/**
 * 
 */
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

/**
 * @author root
 *
 */
@Entity
@Table(name = "content_area")
@NamedQueries({
        @NamedQuery(name = "ContentArea.Id", query = "SELECT ca FROM ContentArea ca WHERE ca.name = :name"),
        @NamedQuery(name="ContentArea.maxId", query="SELECT MAX(ca.id) FROM ContentArea ca") 
})
public class ContentArea implements Serializable {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	@Id
    @GeneratedValue(strategy=GenerationType.IDENTITY)
    @Column(name = "ca_id")
    private long id;

    @Basic
    @Column(name = "ca_name")
    private String name;
	/**
	 * 
	 */
	public ContentArea() {
		// TODO Auto-generated constructor stub
	}
	
	public long getId() {
		return id;
	}
	
	public void setId(long id) {
		this.id = id;
	}
	
	public String getName() {
		return name;
	}
	
	public void setName(String name) {
		this.name = name;
	}

}
