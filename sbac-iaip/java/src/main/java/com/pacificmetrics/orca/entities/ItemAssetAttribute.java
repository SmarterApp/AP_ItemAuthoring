/**
 * 
 */
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
import javax.persistence.NamedQuery;
import javax.persistence.OneToOne;
import javax.persistence.Table;

/**
 * @author root
 * 
 */
@Entity
@Table(name = "item_asset_attribute")
@NamedQuery(name = "findItemAssetAttributeByItemId", query = "SELECT a FROM ItemAssetAttribute a WHERE a.item.id = :itemId")
public class ItemAssetAttribute implements Serializable {

    /**
	 * 
	 */
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "iaa_id")
    private long id;

    @OneToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "i_id")
    private Item item;

    @Basic(fetch = FetchType.EAGER)
    @Column(name = "iaa_filename")
    private String fileName;

    @Basic(fetch = FetchType.EAGER)
    @Column(name = "iaa_media_description")
    private String mediaDescription;

    @Basic(fetch = FetchType.EAGER)
    @Column(name = "iaa_source_url")
    private String sourceUrl;

    @OneToOne
    @JoinColumn(name = "iaa_u_id")
    private User user;

    @Basic
    @Column(name = "iaa_timestamp")
    private Timestamp timeAsset;

    @Basic(fetch = FetchType.EAGER)
    @Column(name = "iaa_classification", length = 5)
    private String classification;

    /**
	 * 
	 */
    public ItemAssetAttribute() {
        // TODO Auto-generated constructor stub
    }

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public Item getItem() {
        return item;
    }

    public void setItem(Item item) {
        this.item = item;
    }

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public String getMediaDescription() {
        return mediaDescription;
    }

    public void setMediaDescription(String mediaDescription) {
        this.mediaDescription = mediaDescription;
    }

    public String getSourceUrl() {
        return sourceUrl;
    }

    public void setSourceUrl(String sourceUrl) {
        this.sourceUrl = sourceUrl;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public Timestamp getTimeAsset() {
        return timeAsset;
    }

    public void setTimeAsset(Timestamp timeAsset) {
        this.timeAsset = timeAsset;
    }

    public String getClassification() {
        return classification;
    }

    public void setClassification(String classification) {
        this.classification = classification;
    }

}
