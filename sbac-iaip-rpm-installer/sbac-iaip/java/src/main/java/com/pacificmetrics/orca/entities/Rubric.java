package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;

@Entity
@Table(name="scoring_rubric")
public class Rubric implements Serializable {
    private static final long serialVersionUID = 1L;

    @Id
    @Column(name="sr_id")
    private int id;
    
    @Basic
    @Column(name="ib_id")
    private int itemBankId;
    
    @Basic
    @Column(name="sr_name")
    private String name;
    
    @Basic
    @Column(name="sr_url")
    private String url;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getItemBankId() {
        return itemBankId;
    }

    public void setItemBankId(int itemBankId) {
        this.itemBankId = itemBankId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }
}
