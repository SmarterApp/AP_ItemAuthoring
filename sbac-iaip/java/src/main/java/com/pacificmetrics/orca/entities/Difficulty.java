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
@Table(name = "difficulty")
@NamedQueries({
        @NamedQuery(name = "Difficulty.difficultId", query = "SELECT d FROM Difficulty d WHERE d.name = :name"),
        @NamedQuery(name = "Difficulty.maxId", query = "SELECT max(d.id) from Difficulty d") })
public class Difficulty implements Serializable {

    /**
	 * 
	 */
    private static final long serialVersionUID = 1L;

    @Id
    @Column(name = "d_id")
    private long id;

    @Basic
    @Column(name = "d_name")
    private String name;

    /**
	 * 
	 */
    public Difficulty() {
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
