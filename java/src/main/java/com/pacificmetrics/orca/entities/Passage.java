package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.DiscriminatorValue;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;

@Entity
//@DiscriminatorValue("4")
@Table(name="passage")
@NamedQueries({
	@NamedQuery(name="passageByBankIdOrderByName", 
		    query="select p from Passage p where p.itemBankId = :ib_id order by p.name")
})

public class Passage //extends ItemCharacterization 
    implements Serializable {

	private static final long serialVersionUID = 1L;

	@Id
	@Column(name="p_id")
	private int id;
	
	@Basic
	@Column(name="ib_id")
	private int itemBankId;
	
    @Basic
    @Column(name="p_name")
    private String name;
    
    @Basic
    @Column(name="p_url")
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
