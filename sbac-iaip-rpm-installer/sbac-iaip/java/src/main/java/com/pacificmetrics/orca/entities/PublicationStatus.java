package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;

@Entity
@NamedQueries({
        @NamedQuery(name = "PublicationStatus.dataByName", query = "SELECT ps FROM PublicationStatus ps where ps.name = :name"),
        @NamedQuery(name = "PublicationStatus.maxId", query = "SELECT MAX(ps.id) FROM PublicationStatus ps") })
@Table(name = "publication_status")
public class PublicationStatus implements Serializable {

    /**
	 * 
	 */
    private static final long serialVersionUID = 1L;

    @Id
    @Column(name = "ps_id")
    private int id;

    @Basic
    @Column(name = "ps_name")
    private String name;

    /**
     * @return the id
     */
    public int getId() {
        return id;
    }

    /**
     * @param id
     *            the id to set
     */
    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

}
