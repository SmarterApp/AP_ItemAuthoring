package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Table;

@Entity
@Table(name="stat_item_value")
public class StatItemValue implements Serializable {

    private static final long serialVersionUID = 1L;
    
    @Id
    @Column(name="siv_id")
    @GeneratedValue(strategy=GenerationType.IDENTITY)
    private int id;
    
    @Basic
    @Column(name="sa_id")
    private int statAdministrationId;
    
    @Basic
    @Column(name="i_id")
    private long itemId;
    
    @Basic
    @Column(name="sk_id") 
    private int statKeyId;
    
    @Basic
    @Column(name="siv_numeric_value")
    private double numericValue;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getStatAdministrationId() {
        return statAdministrationId;
    }

    public void setStatAdministrationId(int statAdministrationId) {
        this.statAdministrationId = statAdministrationId;
    }

    public long getItemId() {
        return itemId;
    }

    public void setItemId(long itemId) {
        this.itemId = itemId;
    }

    public int getStatKeyId() {
        return statKeyId;
    }

    public void setStatKeyId(int statKeyId) {
        this.statKeyId = statKeyId;
    }

    public double getNumericValue() {
        return numericValue;
    }

    public void setNumericValue(double numericValue) {
        this.numericValue = numericValue;
    }


}
