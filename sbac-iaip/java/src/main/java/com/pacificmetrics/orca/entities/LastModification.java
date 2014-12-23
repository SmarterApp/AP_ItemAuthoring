package com.pacificmetrics.orca.entities;

import java.io.Serializable;
import java.sql.Timestamp;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;

@Entity
@Table(name="last_modification")
@NamedQueries({
	@NamedQuery(name="lmByTableName", 
		        query="select lm from LastModification lm where lm.tableName = :lm_table_name")		        
})

public class LastModification implements Serializable {

	private static final long serialVersionUID = 1L;
	
	@Id
	@Column(name="lm_id")
	private int id;
	
    @Basic
    @Column(name="lm_table_name")
    private String tableName;
    
    @Basic
    @Column(name="lm_timestamp")
    private Timestamp timestamp;

    public int getId() {
        return id;
    }

    public String getTableName() {
        return tableName;
    }

    public Timestamp getTimestamp() {
        return timestamp;
    }
    
}
