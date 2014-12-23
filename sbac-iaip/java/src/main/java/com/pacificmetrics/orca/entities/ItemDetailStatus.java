package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.ManyToOne;
import javax.persistence.Table;
import javax.persistence.Transient;

/**
 * 
 * Basic entity class for the item detail status object.
 * 
 * @author arindam.majumdar
 * 
 */

@Entity
@Table(name = "item_detail_status")
public class ItemDetailStatus implements Serializable {

    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ids_id")
    private long id;

    @Basic
    @Column(name = "imd_status_detail")
    private String statusDetail;

    @Basic
    @Column(name = "imd_id")
    private long itemMoveDetailsId;

    @ManyToOne
    @Column(name = "dst_id")
    private DetailStatusType detailStatusType;

    @Transient
    private String externalId;

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
     * @return the statusDetail
     */
    public String getStatusDetail() {
        return statusDetail;
    }

    /**
     * @param statusDetail
     *            the statusDetail to set
     */
    public void setStatusDetail(String statusDetail) {
        this.statusDetail = statusDetail;
    }

    /**
     * @return the itemMoveDetailsId
     */
    public long getItemMoveDetailsId() {
        return itemMoveDetailsId;
    }

    /**
     * @param itemMoveDetailsId
     *            the itemMoveDetailsId to set
     */
    public void setItemMoveDetailsId(long itemMoveDetailsId) {
        this.itemMoveDetailsId = itemMoveDetailsId;
    }

    /**
     * @return the detailStatusType
     */
    public DetailStatusType getDetailStatusType() {
        return detailStatusType;
    }

    /**
     * @param detailStatusType
     *            the detailStatusType to set
     */
    public void setDetailStatusType(DetailStatusType detailStatusType) {
        this.detailStatusType = detailStatusType;
    }

    public String getStatusTypeAsString() {
        if (detailStatusType != null) {
            return detailStatusType.getType();
        }
        return "";
    }

    public String getStatusCodeAsString() {
        if (detailStatusType != null) {
            return String.valueOf(detailStatusType.getCode());
        }
        return "";
    }

    public String getExternalId() {
        return externalId;
    }

    public void setExternalId(String externalId) {
        this.externalId = externalId;
    }

}
