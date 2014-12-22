/**
 * 
 */
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
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.OneToOne;
import javax.persistence.Table;

/**
 * @author root
 * 
 */
@Entity
@Table(name = "passage_item_set")
@NamedQueries({
        @NamedQuery(name = "PassageItemSet.maxId", query = "select max(pts.id) from PassageItemSet pts"),
        @NamedQuery(name = "PassageItemSet.findPassageByItemId", query = "SELECT pst.passage FROM PassageItemSet pst WHERE pst.item.id = :itemId"),
        @NamedQuery(name = "Item.PIS_BY_ITEM", query = "SELECT pis FROM PassageItemSet pis WHERE pis.item.id = :id") })
public class PassageItemSet implements Serializable {

    /**
	 * 
	 */
    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "pis_id")
    private long id;

    @OneToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "i_id")
    private Item item;

    @OneToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "p_id")
    private Passage passage;

    @Basic
    @Column(name = "pis_sequence")
    private int sequence;

    /**
	 * 
	 */
    public PassageItemSet() {
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
     * @param passage
     *            the passage to set
     */
    public void setPassage(Passage passage) {
        this.passage = passage;
    }

    /**
     * @return the sequence
     */
    public int getSequence() {
        return sequence;
    }

    /**
     * @param sequence
     *            the sequence to set
     */
    public void setSequence(int sequence) {
        this.sequence = sequence;
    }

}
