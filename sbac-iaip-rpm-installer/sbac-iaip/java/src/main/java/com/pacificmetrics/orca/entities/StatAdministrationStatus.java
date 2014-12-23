package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;

@Entity
@Table(name="stat_administration_status")

public class StatAdministrationStatus implements Serializable {

    private static final long serialVersionUID = 1L;
    
    static public final int UNDEFINED = 0;
    static public final int SUCCESS = 1;
    static public final int FAILURE = 3;
    static public final int ARCHIVE = 6;
    
    @Id
    @Column(name="sas_id")
    private int id;
    
    @Basic
    @Column(name="sas_name")
    private String name;
    
    public StatAdministrationStatus() {
    }
    
    public StatAdministrationStatus(int id) {
        this.id = id;
    }
    
   public int getId() {
        return id;
    }

    public String getName() {
        return name;
    }

}