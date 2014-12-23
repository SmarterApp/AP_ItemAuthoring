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
 * @author root
 * 
 */
@Entity
@Table(name = "item_format")
public class ItemFormat implements Serializable {

    /**
	 * 
	 */
    private static final long serialVersionUID = 1L;

    @Id
    @Column(name = "itf_id")
    private long id;

    @Basic
    @Column(name = "itf_name", length = 50)
    private String name;

    /**
	 * 
	 */
    public ItemFormat() {
        // TODO Auto-generated constructor stub
    }

    /**
     * @return the id
     */
    public long getId() {
        return id;
    }

    /**
     * @param id
     *            the id to set
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
     * @param name
     *            the name to set
     */
    public void setName(String name) {
        this.name = name;
    }

}
