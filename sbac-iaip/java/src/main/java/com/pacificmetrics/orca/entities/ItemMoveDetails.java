package com.pacificmetrics.orca.entities;

import java.io.Serializable;
import java.util.List;

import javax.persistence.Basic;
import javax.persistence.CascadeType;
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
import javax.persistence.OneToMany;
import javax.persistence.OneToOne;
import javax.persistence.Table;

import org.apache.commons.collections.CollectionUtils;

/**
 * 
 * Basic entity class for the item move details object.
 * 
 * @author arindam.majumdar
 * 
 */

@Entity
@NamedQueries({
        @NamedQuery(name = "ItemMoveDetails.IMD_BY_EXTERNALID", query = "SELECT imd FROM ItemMoveDetails imd LEFT JOIN FETCH imd.item i WHERE i.itemBank.id = :id AND imd.imdExternalId = :imdExternalId LIMIT 1"),
        @NamedQuery(name = "ItemMoveDetails.IMD_BY_ITEMID", query = "SELECT imd FROM ItemMoveDetails imd WHERE imd.item.id = :id") })
@Table(name = "item_move_details")
public class ItemMoveDetails implements Serializable {

    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "imd_id")
    private long id;

    @Basic
    @Column(name = "imm_id")
    private long itemMoveMonitorId;

    @Basic
    @Column(name = "i_external_id")
    private String externalId;

    @OneToOne(fetch = FetchType.EAGER, cascade = CascadeType.REMOVE)
    @Column(name = "i_id", nullable = true)
    private Item item;

    @OneToMany(fetch = FetchType.EAGER, cascade = CascadeType.REMOVE)
    @JoinColumn(name = "imd_id")
    private List<ItemDetailStatus> itemDetailStatus;

    @Basic
    @Column(name = "imd_external_id")
    private String imdExternalId;

    @ManyToOne
    @JoinColumn(name = "imm_id", referencedColumnName = "imm_id")
    private ItemMoveMonitor itemMoveMonitor;

    public String getItemNameAsString() {
        if (item != null) {
            return item.getExternalId();
        } else {
            return externalId;
        }
    }

    public Integer getItemDetailCount() {
        if (CollectionUtils.isNotEmpty(itemDetailStatus)) {
            return itemDetailStatus.size();
        }
        return 0;
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
     * @return the itemMoveMonitorId
     */
    public long getItemMoveMonitorId() {
        return itemMoveMonitorId;
    }

    /**
     * @param itemMoveMonitorId
     *            the itemMoveMonitorId to set
     */
    public void setItemMoveMonitorId(long itemMoveMonitorId) {
        this.itemMoveMonitorId = itemMoveMonitorId;
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
     * @return the itemDetailStatus
     */
    public List<ItemDetailStatus> getItemDetailStatus() {
        return itemDetailStatus;
    }

    /**
     * @param itemDetailStatus
     *            the itemDetailStatus to set
     */
    public void setItemDetailStatus(List<ItemDetailStatus> itemDetailStatus) {
        this.itemDetailStatus = itemDetailStatus;
    }

    public String getExternalId() {
        return externalId;
    }

    public void setExternalId(String externalId) {
        this.externalId = externalId;
    }

    public String getImdExternalId() {
        return imdExternalId;
    }

    public void setImdExternalId(String imdExternalId) {
        this.imdExternalId = imdExternalId;
    }

    public ItemMoveMonitor getItemMoveMonitor() {
        return itemMoveMonitor;
    }

    public void setItemMoveMonitor(ItemMoveMonitor itemMoveMonitor) {
        this.itemMoveMonitor = itemMoveMonitor;
    }

}
