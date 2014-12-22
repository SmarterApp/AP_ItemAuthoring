/**
 * 
 */
package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.OneToOne;
import javax.persistence.Table;

/**
 * @author root
 *
 */
@Entity
@Table(name = "content_external_attribute")
@NamedQueries({@NamedQuery(name="findContentExternalAttributeByItemId",query="SELECT a FROM ContentExternalAttribute a WHERE a.item.id = :itemId"),
@NamedQuery(name="findContentExternalAttributeByPassageId",query="SELECT a FROM ContentExternalAttribute a WHERE a.passage.id = :passageId")})
public class ContentExternalAttribute implements Serializable {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "cea_id")
	private long id;
	
	@OneToOne(fetch = FetchType.EAGER, cascade = CascadeType.REMOVE)
	@JoinColumn(name = "i_id")
	private Item item;
	
	@OneToOne(fetch = FetchType.EAGER, cascade = CascadeType.REMOVE)
	@JoinColumn(name = "p_id")
	private Passage passage;
	
	@Basic
	@Column(name = "cea_external_id")
	private String externalID;
	
	@Basic
	@Column(name = "cea_format")
	private String format;
	
	/**
	 * 
	 */
	public ContentExternalAttribute() {
		// TODO Auto-generated constructor stub
	}

	/**
	 * @return the id
	 */
	public long getId() {
		return id;
	}

	/**
	 * @param id the id to set
	 */
	public void setId(long id) {
		this.id = id;
	}

	/**
	 * @return the item
	 */
	public Item getItem() {
		return item;
	}

	/**
	 * @param item the item to set
	 */
	public void setItem(Item item) {
		this.item = item;
	}

	/**
	 * @return the passage
	 */
	public Passage getPassage() {
		return passage;
	}

	/**
	 * @param passage the passage to set
	 */
	public void setPassage(Passage passage) {
		this.passage = passage;
	}

	/**
	 * @return the externalID
	 */
	public String getExternalID() {
		return externalID;
	}

	/**
	 * @param externalID the externalID to set
	 */
	public void setExternalID(String externalID) {
		this.externalID = externalID;
	}

	/**
	 * @return the format
	 */
	public String getFormat() {
		return format;
	}

	/**
	 * @param format the format to set
	 */
	public void setFormat(String format) {
		this.format = format;
	}

	
}
