package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.JoinColumns;
import javax.persistence.ManyToOne;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;

@Entity
@Table(name="item_metafile_association")
@NamedQueries({
	@NamedQuery(name="itemAssociationByItemAndMetafile", 
     	    query="select ima from ItemMetafileAssociation ima where ima.itemId = :item_id and ima.metafileId = :metafile_id"),
	@NamedQuery(name="itemAssociationByMetafile", 
	    query="select ima from ItemMetafileAssociation ima where ima.metafileId = :metafile_id"),
	@NamedQuery(name="itemAssociationCountByMetafile", 
	    query="select count(ima.metafileId) from ItemMetafileAssociation ima where ima.metafileId = :metafile_id"),
	@NamedQuery(name="itemAssociationByMetafileOutdated", 
	    query="select ima from ItemMetafileAssociation ima where ima.metafileId = :metafile_id and ima.version < (select max(ibm.version) from ItemBankMetafile ibm where ibm.id = ima.metafileId)"),
	@NamedQuery(name="itemAssociationByMetafileAndVersion", 
	    query="select ima from ItemMetafileAssociation ima where ima.metafileId = :metafile_id and ima.version = :version"),
	@NamedQuery(name="itemAssociationByItem", 
	    query="select ima from ItemMetafileAssociation ima where ima.itemId = :item_id")
	    
})
public class ItemMetafileAssociation implements MetafileAssociation, Serializable {
	
	private static final long serialVersionUID = 1L;

	@Id
	@GeneratedValue(strategy=GenerationType.IDENTITY)
	@Column(name="ima_id")
	private int id;
	
	@ManyToOne(fetch=FetchType.EAGER)
	@JoinColumn(name="i_id")
	private Item item;
	
	@ManyToOne(fetch=FetchType.EAGER)
	@JoinColumns({
		@JoinColumn(name="ibm_id"),
		@JoinColumn(name="ibm_version")
	})
	private ItemBankMetafile metafile;
	
	@Basic
	@Column(name="i_id")
	private int itemId;
	
	@Basic
	@Column(name="ibm_id")
	private int metafileId;
	
	@Basic
	@Column(name="ibm_version")
	private int version;
	
	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public Item getItem() {
		return item;
	}

	public void setItem(Item item) {
		this.item = item;
	}

	public ItemBankMetafile getMetafile() {
		return metafile;
	}

	public void setMetafile(ItemBankMetafile metafile) {
		this.metafile = metafile;
	}

	public int getItemId() {
		return itemId;
	}

	public void setItemId(int itemId) {
		this.itemId = itemId;
	}

	public int getMetafileId() {
		return metafileId;
	}

	public void setMetafileId(int metafileId) {
		this.metafileId = metafileId;
	}

	public int getVersion() {
		return version;
	}

	public void setVersion(int version) {
		this.version = version;
	}

}
