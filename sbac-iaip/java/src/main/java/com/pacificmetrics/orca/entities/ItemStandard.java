package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;

/**
 * 
 * Basic entity class for the item standard object.
 * 
 * @author arindam.majumdar
 * 
 */

@Entity
@NamedQueries({ @NamedQuery(name = "ItemStandard.BY_ITEM", query = "SELECT istd FROM ItemStandard istd WHERE istd.item.id = :id") })
@Table(name = "item_standard")
public class ItemStandard implements Serializable {

    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "isd_id")
    private long id;

    @Basic
    @Column(name = "isd_standard")
    private String standard;

    @ManyToOne()
    @JoinColumn(name = "i_id")
    private Item item;

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
     * @return the standard
     */
    public String getStandard() {
        return standard;
    }

    /**
     * @param standard
     *            the standard to set
     */
    public void setStandard(String standard) {
        this.standard = standard;
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

}
