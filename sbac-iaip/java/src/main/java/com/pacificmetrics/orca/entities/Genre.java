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
 * @author root
 * 
 */
@Entity
@NamedQueries({
        @NamedQuery(name = "Genre.dataByName", query = "SELECT g FROM Genre g WHERE g.name = :name"),
        @NamedQuery(name = "Genre.maxId", query = "SELECT MAX(g.id) FROM Genre g") })
@Table(name = "genre")
public class Genre implements Serializable {

    /**
	 * 
	 */
    private static final long serialVersionUID = 1L;

    @Id
    @Column(name = "g_id")
    private long id;

    @Basic
    @Column(name = "g_name")
    private String name;

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
