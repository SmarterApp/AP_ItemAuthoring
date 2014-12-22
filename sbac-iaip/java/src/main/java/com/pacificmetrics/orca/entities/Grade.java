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
@Table(name = "grade_level")
@NamedQueries({
        @NamedQuery(name = "Grade.Id", query = "SELECT g FROM Grade g WHERE g.name = :name"),        
        @NamedQuery(name="Grade.maxId", query="SELECT max(g.id) FROM Grade g") 
})
public class Grade implements Serializable {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	@Id
    @GeneratedValue(strategy=GenerationType.IDENTITY)
    @Column(name = "gl_id")
    private long id;

    @Basic
    @Column(name = "gl_name")
    private String name;
    
	/**
	 * 
	 */
	public Grade() {
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
