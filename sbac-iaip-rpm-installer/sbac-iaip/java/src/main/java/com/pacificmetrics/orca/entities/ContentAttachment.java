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
@Table(name = "content_attachment")
@NamedQueries({
        @NamedQuery(name = "findAttachmentByItemId", query = "SELECT c FROM ContentAttachment c WHERE c.item.id = :itemId"),
        @NamedQuery(name = "findAttachmentByPassageId", query = "SELECT c FROM ContentAttachment c WHERE c.passage.id = :passageId") })
public class ContentAttachment implements Serializable {

    /**
	 * 
	 */
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ca_id")
    private long id;

    @OneToOne(fetch = FetchType.EAGER, cascade = CascadeType.REMOVE)
    @JoinColumn(name = "i_id")
    private Item item;

    @OneToOne(fetch = FetchType.EAGER, cascade = CascadeType.REMOVE)
    @JoinColumn(name = "p_id")
    private Passage passage;

    @OneToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "cr_id")
    private ContentResources contentResources;

    @Basic
    @Column(name = "ca_type", length = 30, nullable = false)
    private String type;

    @Basic
    @Column(name = "ca_filename", length = 60)
    private String filename;

    @Basic
    @Column(name = "ca_source_url", length = 200)
    private String sourceUrl;

    /**
	 * 
	 */
    public ContentAttachment() {
        // TODO Auto-generated constructor stub
    }

    /**
     * @return the id
     */
    public long getId() {
        return id;
    }

    /**
     * @param id
     *            the id to set
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
     * @param item
     *            the item to set
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
     * @return the contentResources
     */
    public ContentResources getContentResources() {
        return contentResources;
    }

    /**
     * @param contentResources
     *            the contentResources to set
     */
    public void setContentResources(ContentResources contentResources) {
        this.contentResources = contentResources;
    }

    /**
     * @param passage
     *            the passage to set
     */
    public void setPassage(Passage passage) {
        this.passage = passage;
    }

    /**
     * @return the type
     */
    public String getType() {
        return type;
    }

    /**
     * @param type
     *            the type to set
     */
    public void setType(String type) {
        this.type = type;
    }

    /**
     * @return the filename
     */
    public String getFilename() {
        return filename;
    }

    /**
     * @param filename
     *            the filename to set
     */
    public void setFilename(String filename) {
        this.filename = filename;
    }

    /**
     * @return the sourceUrl
     */
    public String getSourceUrl() {
        return sourceUrl;
    }

    /**
     * @param sourceUrl
     *            the sourceUrl to set
     */
    public void setSourceUrl(String sourceUrl) {
        this.sourceUrl = sourceUrl;
    }

}
