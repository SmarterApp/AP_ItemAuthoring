package com.pacificmetrics.orca.entities;

import java.io.Serializable;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.JoinTable;
import javax.persistence.ManyToMany;
import javax.persistence.ManyToOne;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.OneToMany;
import javax.persistence.OneToOne;
import javax.persistence.Table;
import javax.persistence.Transient;

/**
 * 
 * Basic entity class for the item object.
 * 
 * @author amiliteev
 * @additions maumock
 * 
 */

@Entity
@Table(name = "item")
@NamedQueries({
        @NamedQuery(name = "itemByExternalId", query = "select i from Item i where i.externalId = :external_id"),
        @NamedQuery(name = "itemByItemBankAndExternalId", query = "select i from Item i where i.itemBankId = :ib_id and i.externalId = :external_id")

})
public class Item implements Serializable {

    private static final long serialVersionUID = 1L;

    public static final int IT_SR_EXCLUSIVE = 1;
    public static final int IT_SR_NON_ECLUSIVE = 2;
    public static final int IT_CR_SINGLE_LINE = 3;
    public static final int IT_CR_MULTI_LINE = 4;

    @Id
    @Column(name = "i_id")
    private long id;

    @Basic
    @Column(name = "i_external_id")
    private String externalId;

    @Basic
    @Column(name = "ib_id")
    private int itemBankId;

    @Basic
    @Column(name = "i_description")
    private String description;

    @Basic
    @Column(name = "i_stylesheet_url")
    private String stylesheetUrl;

    // TODO find out why FetchType.LAZY doesn't work
    @Basic
    @Column(name = "i_type")
    private int itemType;

    @Basic
    @Column(name = "i_version")
    private int version;

    @OneToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "i_author")
    private User author;

    /*
     * @OneToOne(fetch=FetchType.EAGER)
     * 
     * @JoinColumn(name="i_id", referencedColumnName="3") private
     * ItemCharacterization gradeLevel;
     */

    @Basic
    @Column(name = "i_difficulty")
    private int difficulty;

    @Column(name = "i_dev_state")
    @OneToOne
    private DevState devState;

    @Basic(fetch = FetchType.LAZY)
    @Column(name = "i_qti_xml_data")
    private String qtiData;

    // TODO find out why FetchType.LAZY doesn't work
    @OneToMany(fetch = FetchType.EAGER)
    @JoinColumn(name = "i_id")
    private List<ItemCharacterization> itemCharacterizations;
    
    @OneToMany
    @JoinTable(name="item_characterization",
        joinColumns={
            @JoinColumn(name="i_id", referencedColumnName="i_id")/*,
            // FIXME use openjpa constant join feature to grab associated passages
            // OPENJPA-2054 [https://issues.apache.org/jira/browse/OPENJPA-2054]
            // OPENJPA-1979 [https://issues.apache.org/jira/browse/OPENJPA-1979]
            // TODO Should reference by ItemCharacterization enum
            @JoinColumn(name="ic_type", referencedColumnName="4")*/
        }, 
        inverseJoinColumns={
            @JoinColumn(name="ic_value", referencedColumnName="p_id")
        })
    private List<Passage> passages;
    
    @OneToMany
    @JoinTable(name="item_characterization",
        joinColumns={
            @JoinColumn(name="i_id", referencedColumnName="i_id")/*,
            // FIXME use openjpa constant join feature to grab associated passages
            // OPENJPA-2054 [https://issues.apache.org/jira/browse/OPENJPA-2054]
            // OPENJPA-1979 [https://issues.apache.org/jira/browse/OPENJPA-1979]
            // TODO Should reference by ItemCharacterization enum
            @JoinColumn(name="ic_type", referencedColumnName="16")*/
        },
        inverseJoinColumns={
            @JoinColumn(name="ic_value", referencedColumnName="sr_id")
        })
    private List<Rubric> rubrics;
    
    // FIXME Not everyone needs this data
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "ib_id")
    private ItemBank itemBank;

    @Basic(fetch = FetchType.LAZY)
    @Column(name = "i_metadata_xml", length = 10000)
    private String metadataXml;

    @OneToMany(fetch = FetchType.LAZY)
    @JoinColumn(name = "i_id")
    private List<ItemInteraction> itemInteractions;

    @OneToMany(fetch = FetchType.LAZY)
    @JoinColumn(name = "i_id")
    private List<ItemFragment> itemFragments;

    @Transient
    private Map<Integer, ItemCharacterization> itemCharacterizationMap;

    /**
     * @return the devState
     */
    public DevState getDevState() {
        return this.devState;
    }

    /**
     * @param devState
     *            the devState to set
     */
    public void setDevState(DevState devState) {
        this.devState = devState;
    }

    /**
     * @return the id
     */
    public long getId() {
        return this.id;
    }

    /**
     * @param id
     *            the id to set
     */
    public void setId(long id) {
        this.id = id;
    }

    /**
     * @return the externalId
     */
    public String getExternalId() {
        return this.externalId;
    }

    /**
     * @param externalId
     *            the externalId to set
     */
    public void setExternalId(String externalId) {
        this.externalId = externalId;
    }

    /**
     * @return the description
     */
    public String getDescription() {
        return this.description;
    }

    /**
     * @param description
     *            the description to set
     */
    public void setDescription(String description) {
        this.description = description;
    }

    public List<ItemCharacterization> getItemCharacterizations() {
        return this.itemCharacterizations;
    }

    public void setItemCharacterizations(
            List<ItemCharacterization> itemCharacterizations) {
        this.itemCharacterizations = itemCharacterizations;
    }

    /**
     * 
     * @param type
     * @return A map of item characterizations
     */
    @SuppressWarnings("boxing")
    // FIXME will only return a single item characterization instead of list of item characterizations by type
    // FIXME should use ENUM instead of int
    public ItemCharacterization getCharacterization(int type) {
        if (this.itemCharacterizationMap == null) {
            synchronized (this) {
                this.itemCharacterizationMap = new HashMap<Integer, ItemCharacterization>();
                for (ItemCharacterization ic : getItemCharacterizations()) {
                    this.itemCharacterizationMap.put(ic.getType(), ic);
                }
            }
        }
        return this.itemCharacterizationMap.get(type);
    }

    public List<Passage> getPassages() {
        return passages;
    }

    public void setPassages(List<Passage> passages) {
        this.passages = passages;
    }

    public String getGradeLevel() {
        ItemCharacterization gradeLevel = this.getCharacterization(3);
        return (gradeLevel == null ? null : (gradeLevel.getIntValue() == 0 ? "K" : String.valueOf(gradeLevel
                .getIntValue())));
    }

    public String getSubject() {
        ItemCharacterization subject = this.getCharacterization(2);
        return ((subject == null ? null : subject.getIntValue() == 1 ? "MATH" : "ELA"));
    }

    public String getSource() {
        return "source";
    }

    public String getKeywords() {
        return "keywords";
    }

    public String getSubCategory() {
        return "subcategory";
    }

    /**
     * @return the itemBankId
     */
    public int getItemBankId() {
        return this.itemBankId;
    }

    /**
     * @param itemBankId
     *            the itemBankId to set
     */
    public void setItemBankId(int itemBankId) {
        this.itemBankId = itemBankId;
    }

    /**
     * @return the itemType
     */
    public int getItemType() {
        return this.itemType;
    }

    /**
     * @param itemType
     *            the itemType to set
     */
    public void setItemType(int itemType) {
        this.itemType = itemType;
    }

    /**
     * @return the itemBank
     */
    public ItemBank getItemBank() {
        return this.itemBank;
    }

    public String getStylesheetUrl() {
        return stylesheetUrl;
    }

    public void setStylesheetUrl(String stylesheetUrl) {
        this.stylesheetUrl = stylesheetUrl;
    }

    /**
     * @param itemBank
     *            the itemBank to set
     */
    public void setItemBank(ItemBank itemBank) {
        this.itemBank = itemBank;
    }

    /**
     * @return the qtiData
     */
    public String getQtiData() {
        return this.qtiData;
    }

    /**
     * @param qtiData
     *            the qtiData to set
     */
    public void setQtiData(String qtiData) {
        this.qtiData = qtiData;
    }

    public String getMetadataXml() {
        return metadataXml;
    }

    public void setMetadataXml(String metadataXml) {
        this.metadataXml = metadataXml;
    }

    public List<ItemInteraction> getItemInteractions() {
        return itemInteractions;
    }

    public void setItemInteractions(List<ItemInteraction> itemInteractions) {
        this.itemInteractions = itemInteractions;
    }

    public List<ItemFragment> getItemFragments() {
        return itemFragments;
    }

    public void setItemFragments(List<ItemFragment> itemFragments) {
        this.itemFragments = itemFragments;
    }

    public int getVersion() {
        return version;
    }

    public void setVersion(int version) {
        this.version = version;
    }

    public User getAuthor() {
        return author;
    }

    public void setAuthor(User author) {
        this.author = author;
    }

    public int getDifficulty() {
        return difficulty;
    }

    public void setDifficulty(int difficulty) {
        this.difficulty = difficulty;
    }

    /**
     * Searches for item interaction with given interactionId
     * 
     * @param interactionId
     * @return
     */
    public ItemInteraction findItemInteraction(int interactionId) {
        for (ItemInteraction ii : getItemInteractions()) {
            if (ii.getId() == interactionId) {
                return ii;
            }
        }
        return null;
    }

    public List<Rubric> getRubrics() {
        return rubrics;
    }

    public void setRubrics(List<Rubric> rubrics) {
        this.rubrics = rubrics;
    }

}