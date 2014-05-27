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
@Table(name="stat_key")
@NamedQueries({
    @NamedQuery(name="skByNames", 
                query="select sk from StatKey sk where upper(sk.name) IN :names")               
})

public class StatKey implements Serializable {

    private static final long serialVersionUID = 1L;
    
    @Id
    @Column(name="sk_id")
    private int id;
    
    @Basic
    @Column(name="sk_name")
    private String name;

    public int getId() {
        return id;
    }

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
    