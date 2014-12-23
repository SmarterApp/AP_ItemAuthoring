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
@Table(name="passage_metafile_association")
@NamedQueries({
	@NamedQuery(name="passageAssociationByPassageAndMetafile", 
     	    query="select pma from PassageMetafileAssociation pma where pma.passageId = :passage_id and pma.metafileId = :metafile_id"),
	@NamedQuery(name="passageAssociationByMetafile", 
	    query="select pma from PassageMetafileAssociation pma where pma.metafileId = :metafile_id"),
	@NamedQuery(name="passageAssociationCountByMetafile", 
	    query="select count(pma.metafileId) from PassageMetafileAssociation pma where pma.metafileId = :metafile_id"),
	@NamedQuery(name="passageAssociationByMetafileOutdated", 
	    query="select pma from PassageMetafileAssociation pma where pma.metafileId = :metafile_id and pma.version < (select max(ibm.version) from ItemBankMetafile ibm where ibm.id = pma.metafileId)"),
	@NamedQuery(name="passageAssociationByMetafileAndVersion", 
	    query="select pma from PassageMetafileAssociation pma where pma.metafileId = :metafile_id and pma.version = :version"),
	@NamedQuery(name="passageAssociationByPassage", 
	    query="select pma from PassageMetafileAssociation pma where pma.passageId = :passage_id")
	    
})
public class PassageMetafileAssociation implements MetafileAssociation, Serializable {
	
	private static final long serialVersionUID = 1L;

	@Id
	@GeneratedValue(strategy=GenerationType.IDENTITY)
	@Column(name="pma_id")
	private int id;
	
	@ManyToOne(fetch=FetchType.EAGER)
	@JoinColumn(name="p_id")
	private Passage passage;
	
	@ManyToOne(fetch=FetchType.EAGER)
	@JoinColumns({
		@JoinColumn(name="ibm_id"),
		@JoinColumn(name="ibm_version")
	})
	private ItemBankMetafile metafile;
	
	@Basic
	@Column(name="p_id")
	private int passageId;
	
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

	public ItemBankMetafile getMetafile() {
		return metafile;
	}

	public void setMetafile(ItemBankMetafile metafile) {
		this.metafile = metafile;
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

	public Passage getPassage() {
		return passage;
	}

	public void setPassage(Passage passage) {
		this.passage = passage;
	}

	public int getPassageId() {
		return passageId;
	}

	public void setPassageId(int passageId) {
		this.passageId = passageId;
	}

}
