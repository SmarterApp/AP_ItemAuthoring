/**
 * 
 */
package com.pacificmetrics.orca.entities;

import java.io.Serializable;
import java.sql.Timestamp;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.OneToOne;
import javax.persistence.Table;

/**
 * @author root
 * 
 */
@Entity
@NamedQueries({ @NamedQuery(name = "PassageMedia.PSG_MEDIA_BY_PSGID", query = "SELECT pm FROM PassageMedia pm WHERE pm.passage.id = :id") })
@Table(name = "passage_media")
public class PassageMedia implements Serializable {

    /**
	 * 
	 */
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "pm_id")
    private long id;

    @OneToOne
    @JoinColumn(name = "p_id")
    private Passage passage;

    @Basic
    @Column(name = "pm_clnt_filename", length = 60)
    private String clntFilename;

    @Basic
    @Column(name = "pm_srvr_filename", length = 60)
    private String srvrFilename;

    @Basic
    @Column(name = "pm_description")
    private String description;

    @OneToOne()
    @JoinColumn(name = "pm_u_id")
    private User user;

    @Basic
    @Column(name = "pm_timestamp")
    private Timestamp timestamp;

    /**
	 * 
	 */
    public PassageMedia() {
        // TODO Auto-generated constructor stub
    }

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public Passage getPassage() {
        return passage;
    }

    public void setPassage(Passage passage) {
        this.passage = passage;
    }

    public String getClntFilename() {
        return clntFilename;
    }

    public void setClntFilename(String clntFilename) {
        this.clntFilename = clntFilename;
    }

    public String getSrvrFilename() {
        return srvrFilename;
    }

    public void setSrvrFilename(String srvrFilename) {
        this.srvrFilename = srvrFilename;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public Timestamp getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(Timestamp timestamp) {
        this.timestamp = timestamp;
    }

}
