
package com.pacificmetrics.orca.entities;

import java.io.Serializable;
import java.sql.Timestamp;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;
import javax.validation.constraints.Size;

@Entity
@Table(name="stat_import_identifier")
@NamedQueries({
    @NamedQuery(name="saDeleteForId",
                query="delete from StatImportIdentifier sii where sii.id = :id"),
    @NamedQuery(name="saByItemBankId", 
                query="select sii from StatImportIdentifier sii where sii.itemBank.id = :ib_id order by sii.timestamp desc")               
})

public class StatImportIdentifier implements Serializable {

    private static final long serialVersionUID = 1L;
    
    @Id
    @Column(name="sii_id")
    @GeneratedValue(strategy=GenerationType.IDENTITY)
    private int id;
    
    @Basic
    @Column(name="sii_timestamp")
    private Timestamp timestamp;
    
    @Basic
    @Size(max=30)
    @Column(name="sii_identifier")
    private String identifier;
    
    @Basic
    @Size(max=250)
    @Column(name="sii_comment")
    private String comment;
    
    @Basic
    @Column(name="ib_id")
    private int itemBankId;
    
    @ManyToOne(fetch=FetchType.LAZY)
    @JoinColumn(name="ib_id")
    private ItemBank itemBank;
    
    @ManyToOne(fetch=FetchType.EAGER)
    @JoinColumn(name="sas_id")
    private StatAdministrationStatus status;
    
    @Basic
    @Column(name="sas_id")
    private int statusId;
    
    public int getId() {
        return id;
    }

    public Timestamp getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(Timestamp timestamp) {
        this.timestamp = timestamp;
    }

    public String getIdentifier() {
        return identifier;
    }

    public void setIdentifier(String identifier) {
        this.identifier = identifier;
    }

    public String getComment() {
        return comment;
    }

    public void setComment(String comment) {
        this.comment = comment;
    }

    public ItemBank getItemBank() {
        return itemBank;
    }

    public void setItemBank(ItemBank itemBank) {
        this.itemBank = itemBank;
    }

    public void setId(int id) {
        this.id = id;
    }

    public StatAdministrationStatus getStatus() {
        return status;
    }

    public void setStatus(StatAdministrationStatus status) {
        this.status = status;
    }

    public int getStatusId() {
        return statusId;
    }

    public void setStatusId(int statusId) {
        this.statusId = statusId;
    }

    public int getItemBankId() {
        return itemBankId;
    }

    public void setItemBankId(int itemBankId) {
        this.itemBankId = itemBankId;
    }
    
}