package com.pacificmetrics.orca.entities;

import java.io.Serializable;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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
import javax.persistence.OneToMany;
import javax.persistence.OneToOne;
import javax.persistence.Table;
import javax.persistence.Transient;

@Entity
// @DiscriminatorValue("4")
@Table(name = "passage")
@NamedQueries({
        @NamedQuery(name = "passageByBankIdOrderByName", query = "select p from Passage p where p.itemBankId = :ib_id order by p.name"),
        @NamedQuery(name = "Passage.maxId", query = "SELECT max(p.id) from Passage p") })
public class Passage // extends ItemCharacterization
        implements Serializable {

    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "p_id")
    private int id;

    @Basic
    @Column(name = "ib_id")
    private int itemBankId;

    @Basic
    @Column(name = "p_lang")
    private int lang;

    @Basic
    @Column(name = "p_name")
    private String name;

    @Basic
    @Column(name = "p_genre")
    private int genre;

    @Basic
    @Column(name = "p_publication_status")
    private int publicationStatus;

    @OneToOne
    @JoinColumn(name = "p_publication_status", referencedColumnName = "ps_id")
    private PublicationStatus passagePublicationStatus;

    @Basic
    @Column(name = "p_url")
    private String url;

    @OneToMany(fetch = FetchType.EAGER)
    @JoinColumn(name = "oc_object_id")
    private List<ObjectCharacterization> objectCharacterization;

    @OneToMany(fetch = FetchType.EAGER)
    @JoinColumn(name = "p_id")
    private List<PassageMedia> passageMedia;

    @OneToMany(fetch = FetchType.EAGER, cascade = CascadeType.REMOVE)
    @JoinColumn(name = "p_id")
    private List<ContentAttachment> contentAttachment;

    @OneToMany(fetch = FetchType.EAGER, cascade = CascadeType.REMOVE)
    @JoinColumn(name = "p_id")
    private List<ExternalContentMetadata> externalContentMetadata;

    @OneToMany(fetch = FetchType.EAGER, cascade = CascadeType.REMOVE)
    @JoinColumn(name = "p_id")
    private List<ContentExternalAttribute> contentExternalAttribute;

    @Transient
    private Map<Integer, ObjectCharacterization> objectCharacterizationMap;

    @Basic
    @Column(name = "p_author")
    private int userId;
    
    public ObjectCharacterization getCharacterization(int type) {
        if (this.objectCharacterizationMap == null) {
            synchronized (this) {
                this.objectCharacterizationMap = new HashMap<Integer, ObjectCharacterization>();
                for (ObjectCharacterization ic : getObjectCharacterization()) {
                    this.objectCharacterizationMap.put(ic.getObjectType(), ic);
                }
            }
        }
        return this.objectCharacterizationMap.get(type);
    }

    public String getSubject() {
        ObjectCharacterization subject = this.getCharacterization(2);
        return subject == null ? null : (subject.getIntValue() == 1 ? "MATH"
                : "ELA");
    }

    public String getGradeLevel() {
        ObjectCharacterization gradeLevel = this.getCharacterization(3);
        return gradeLevel == null ? null
                : (gradeLevel.getIntValue() == 0 ? "K" : String
                        .valueOf(gradeLevel.getIntValue()));
    }

    public String getMinimumGrade() {
        ObjectCharacterization gradeLevel = this.getCharacterization(5);
        return gradeLevel == null ? null
                : (gradeLevel.getIntValue() == 0 ? "K" : String
                        .valueOf(gradeLevel.getIntValue()));
    }

    public String getMaximumGrade() {
        ObjectCharacterization gradeLevel = this.getCharacterization(6);
        return gradeLevel == null ? null
                : (gradeLevel.getIntValue() == 0 ? "K" : String
                        .valueOf(gradeLevel.getIntValue()));
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getItemBankId() {
        return itemBankId;
    }

    public void setItemBankId(int itemBankId) {
        this.itemBankId = itemBankId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public PublicationStatus getPassagePublicationStatus() {
        return passagePublicationStatus;
    }

    public void setPassagePublicationStatus(
            PublicationStatus passagePublicationStatus) {
        this.passagePublicationStatus = passagePublicationStatus;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    /**
     * @return the objectCharacterization
     */
    public List<ObjectCharacterization> getObjectCharacterization() {
        return objectCharacterization;
    }

    /**
     * @param objectCharacterization
     *            the objectCharacterization to set
     */
    public void setObjectCharacterization(
            List<ObjectCharacterization> objectCharacterization) {
        this.objectCharacterization = objectCharacterization;
    }

    /**
     * @return the passageMedia
     */
    public List<PassageMedia> getPassageMedia() {
        return passageMedia;
    }

    /**
     * @param passageMedia
     *            the passageMedia to set
     */
    public void setPassageMedia(List<PassageMedia> passageMedia) {
        this.passageMedia = passageMedia;
    }

    /**
     * @return the contentAttachment
     */
    public List<ContentAttachment> getContentAttachment() {
        return contentAttachment;
    }

    /**
     * @param contentAttachment
     *            the contentAttachment to set
     */
    public void setContentAttachment(List<ContentAttachment> contentAttachment) {
        this.contentAttachment = contentAttachment;
    }

    /**
     * @return the externalContentMetadata
     */
    public List<ExternalContentMetadata> getExternalContentMetadata() {
        return externalContentMetadata;
    }

    /**
     * @param externalContentMetadata
     *            the externalContentMetadata to set
     */
    public void setExternalContentMetadata(
            List<ExternalContentMetadata> externalContentMetadata) {
        this.externalContentMetadata = externalContentMetadata;
    }

    /**
     * @return the contentExternalAttribute
     */
    public List<ContentExternalAttribute> getContentExternalAttribute() {
        return contentExternalAttribute;
    }

    /**
     * @param contentExternalAttribute
     *            the contentExternalAttribute to set
     */
    public void setContentExternalAttribute(
            List<ContentExternalAttribute> contentExternalAttribute) {
        this.contentExternalAttribute = contentExternalAttribute;
    }

    /**
     * @return the genre
     */
    public int getGenre() {
        return genre;
    }

    /**
     * @param genre
     *            the genre to set
     */
    public void setGenre(int genre) {
        this.genre = genre;
    }

    /**
     * @return the publicationStatus
     */
    public int getPublicationStatus() {
        return publicationStatus;
    }

    /**
     * @param publicationStatus
     *            the publicationStatus to set
     */
    public void setPublicationStatus(int publicationStatus) {
        this.publicationStatus = publicationStatus;
    }

    /**
     * @return the lang
     */
    public int getLang() {
        return lang;
    }

    /**
     * @param lang
     *            the lang to set
     */
    public void setLang(int lang) {
        this.lang = lang;
    }

	/**
	 * @return the userId
	 */
	public int getUserId() {
		return userId;
	}

	/**
	 * @param userId the userId to set
	 */
	public void setUserId(int userId) {
		this.userId = userId;
	}
    
    

}
