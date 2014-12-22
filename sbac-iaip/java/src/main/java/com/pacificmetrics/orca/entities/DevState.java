/**
 * 
 */
package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.Id;
import javax.persistence.Table;

/**
 * @author maumock
 * 
 */
@Entity
@Table(name = "dev_state")
public class DevState implements Serializable {
    
    private static final long serialVersionUID = 1L;
    
    @Id
    @GeneratedValue
    @Column(name="ds_id")
    private long id;
    
    @Column(name="ds_name")
    private String name;

    /**
     * @return the id
     */
    public long getId() {
        return this.id;
    }

    /**
     * @param id
     *            the id to set
     */
    public void setId(long dsId) {
        this.id = dsId;
    }

    /**
     * @return the name
     */
    public String getName() {
        return this.name;
    }

    /**
     * @param name
     *            the name to set
     */
    public void setName(String dsName) {
        this.name = dsName;
    }
}
