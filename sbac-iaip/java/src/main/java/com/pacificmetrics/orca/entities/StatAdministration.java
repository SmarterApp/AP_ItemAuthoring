package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Table;
import javax.validation.constraints.Size;

@Entity
@Table(name = "stat_administration")
public class StatAdministration implements Serializable {

    private static final long serialVersionUID = 1L;

    @Id
    @Column(name = "sa_id")
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Basic
    @Size(max = 30)
    @Column(name = "sa_administration")
    private String statAdministartion;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getStatAdministartion() {
        return statAdministartion;
    }

    public void setStatAdministartion(String statAdministartion) {
        this.statAdministartion = statAdministartion;
    }

}