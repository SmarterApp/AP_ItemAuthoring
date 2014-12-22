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
@Table(name = "external_content_metadata")
@NamedQueries({
	@NamedQuery(name="findExternalContentMetadataByItemId",query="SELECT e FROM ExternalContentMetadata e WHERE e.item.id = :itemId"),
	@NamedQuery(name="findExternalContentMetadataByPassageId",query="SELECT e FROM ExternalContentMetadata e WHERE e.passage.id = :passageId")})
public class ExternalContentMetadata implements Serializable {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "ecm_id")
	private long id;
	
	@OneToOne(fetch = FetchType.EAGER)
	@JoinColumn(name = "i_id")
	private Item item;
	
	@OneToOne(fetch = FetchType.EAGER)
	@JoinColumn(name = "p_id")
	private Passage passage;
	
	@OneToOne(fetch = FetchType.EAGER, cascade = CascadeType.REMOVE)
	@JoinColumn(name = "cr_id")
	private ContentResources contentResources;
	
	@Basic
	@Column(name = "ecm_content_type")
	private String contentType;
	
	@Basic(fetch = FetchType.LAZY)
	@Column(name = "ecm_content_data")
	private String contentData;
		

	/**
	 * 
	 */
	public ExternalContentMetadata() {
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
	 * @return the contentType
	 */
	public String getContentType() {
		return contentType;
	}


	/**
	 * @param contentType the contentType to set
	 */
	public void setContentType(String contentType) {
		this.contentType = contentType;
	}


	/**
	 * @return the contentData
	 */
	public String getContentData() {
		return contentData;
	}


	/**
	 * @param contentData the contentData to set
	 */
	public void setContentData(String contentData) {
		this.contentData = contentData;
	}


	/**
	 * @return the contentResources
	 */
	public ContentResources getContentResources() {
		return contentResources;
	}


	/**
	 * @param contentResources the contentResources to set
	 */
	public void setContentResources(ContentResources contentResources) {
		this.contentResources = contentResources;
	}

	
}
