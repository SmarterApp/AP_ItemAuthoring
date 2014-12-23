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
import javax.persistence.JoinTable;
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
		@NamedQuery(name = "itemByExternalId", query = "SELECT i FROM Item i WHERE i.externalId = :external_id"),
		@NamedQuery(name = "itemByItemBankAndExternalId", query = "SELECT i FROM Item i WHERE i.itemBankId = :ib_id and i.externalId = :external_id"),
		@NamedQuery(name = "maxItemId", query = "SELECT max(itm.id) FROM Item itm"),
		@NamedQuery(name = "Item.I_BY_FORMAT", query = "SELECT i FROM Item i WHERE i.id = :id AND i.itemFormat IN (SELECT ift.id FROM ItemFormat ift WHERE ift.name in (:name))"), })
public class Item implements Serializable {

	private static final long serialVersionUID = 1L;

	public static final int IT_SR_EXCLUSIVE = 1;
	public static final int IT_SR_NON_ECLUSIVE = 2;
	public static final int IT_CR_SINGLE_LINE = 3;
	public static final int IT_CR_MULTI_LINE = 4;

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
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

	

	@Basic
	@Column(name = "i_difficulty")
	private int difficulty;

	@Basic
	@Column(name = "i_lang")
	private int lang;

	@Column(name = "i_dev_state")
	@OneToOne
	private DevState devState;

	@Basic(fetch = FetchType.LAZY)
	@Column(name = "i_qti_xml_data")
	private String qtiData;

	@Basic
	@Column(name = "i_format")
	private int itemFormat;

	@Basic
	@Column(name = "i_guid")
	private String itemGuid;

	@Basic
	@Column(name = "i_tei_data")
	private String itemTeiData;

	@Basic
	@Column(name = "i_is_pi_set")
	private int itemIsPiSet;

	@OneToOne(fetch = FetchType.EAGER)
	@JoinColumn(name = "i_last_save_user_id")
	private User itemLastSaveUserId;

	@Basic(fetch = FetchType.LAZY)
	@Column(name = "i_xml_data")
	private String itemXmlData;

	@Basic
	@Column(name = "i_is_old_version")
	private int isOldVersion;

	// TODO find out why FetchType.LAZY doesn't work
	@OneToMany(fetch = FetchType.EAGER)
	@JoinColumn(name = "i_id")
	private List<ItemCharacterization> itemCharacterizations;

	@OneToMany(cascade = CascadeType.REMOVE)
	@JoinTable(name = "item_characterization", joinColumns = { @JoinColumn(name = "i_id", referencedColumnName = "i_id") /*
																														 * ,
																														 * /
																														 * /
																														 * FIXME
																														 * use
																														 * openjpa
																														 * constant
																														 * join
																														 * feature
																														 * to
																														 * grab
																														 * associated
																														 * passages
																														 * /
																														 * /
																														 * OPENJPA
																														 * -
																														 * 2054
																														 * [
																														 * https
																														 * :
																														 * /
																														 * /
																														 * issues
																														 * .
																														 * apache
																														 * .
																														 * org
																														 * /
																														 * jira
																														 * /
																														 * browse
																														 * /
																														 * OPENJPA
																														 * -
																														 * 2054
																														 * ]
																														 * /
																														 * /
																														 * OPENJPA
																														 * -
																														 * 1979
																														 * [
																														 * https
																														 * :
																														 * /
																														 * /
																														 * issues
																														 * .
																														 * apache
																														 * .
																														 * org
																														 * /
																														 * jira
																														 * /
																														 * browse
																														 * /
																														 * OPENJPA
																														 * -
																														 * 1979
																														 * ]
																														 * /
																														 * /
																														 * TODO
																														 * Should
																														 * reference
																														 * by
																														 * ItemCharacterization
																														 * enum
																														 * 
																														 * @
																														 * JoinColumn
																														 * (
																														 * name
																														 * =
																														 * "ic_type"
																														 * ,
																														 * referencedColumnName
																														 * =
																														 * "4"
																														 * )
																														 */
	}, inverseJoinColumns = { @JoinColumn(name = "ic_value", referencedColumnName = "p_id") })
	private List<Passage> passages;

	@OneToMany(fetch = FetchType.EAGER, cascade = CascadeType.REMOVE)
	@JoinTable(name = "item_characterization", joinColumns = { @JoinColumn(name = "i_id", referencedColumnName = "i_id") /*
																														 * ,
																														 * /
																														 * /
																														 * FIXME
																														 * use
																														 * openjpa
																														 * constant
																														 * join
																														 * feature
																														 * to
																														 * grab
																														 * associated
																														 * passages
																														 * /
																														 * /
																														 * OPENJPA
																														 * -
																														 * 2054
																														 * [
																														 * https
																														 * :
																														 * /
																														 * /
																														 * issues
																														 * .
																														 * apache
																														 * .
																														 * org
																														 * /
																														 * jira
																														 * /
																														 * browse
																														 * /
																														 * OPENJPA
																														 * -
																														 * 2054
																														 * ]
																														 * /
																														 * /
																														 * OPENJPA
																														 * -
																														 * 1979
																														 * [
																														 * https
																														 * :
																														 * /
																														 * /
																														 * issues
																														 * .
																														 * apache
																														 * .
																														 * org
																														 * /
																														 * jira
																														 * /
																														 * browse
																														 * /
																														 * OPENJPA
																														 * -
																														 * 1979
																														 * ]
																														 * /
																														 * /
																														 * TODO
																														 * Should
																														 * reference
																														 * by
																														 * ItemCharacterization
																														 * enum
																														 * 
																														 * @
																														 * JoinColumn
																														 * (
																														 * name
																														 * =
																														 * "ic_type"
																														 * ,
																														 * referencedColumnName
																														 * =
																														 * "16"
																														 * )
																														 */
	}, inverseJoinColumns = { @JoinColumn(name = "ic_value", referencedColumnName = "sr_id") })
	private List<Rubric> rubrics;

	// FIXME Not everyone needs this data
	@ManyToOne(fetch = FetchType.EAGER)
	@JoinColumn(name = "ib_id")
	private ItemBank itemBank;

	@Basic(fetch = FetchType.LAZY)
	@Column(name = "i_metadata_xml", length = 10000)
	private String metadataXml;

	@OneToMany(fetch = FetchType.EAGER, cascade = CascadeType.REMOVE)
	@JoinColumn(name = "i_id")
	private List<ItemInteraction> itemInteractions;

	@OneToMany(fetch = FetchType.EAGER)
	@JoinColumn(name = "i_id")
	private List<ItemFragment> itemFragments;

	@Transient
	private Map<Integer, ItemCharacterization> itemCharacterizationMap;

	@Basic
	@Column(name = "i_publication_status")
	private Integer publicationStatus;

	@Basic
	@Column(name = "i_primary_standard")
	private String primaryStandard;



	@OneToOne
	@JoinColumn(name = "i_publication_status", referencedColumnName = "ps_id")
	private PublicationStatus itemPublicationStatus;

	@OneToMany(fetch = FetchType.EAGER, cascade = CascadeType.REMOVE)
	@JoinColumn(name = "i_id")
	private List<ExternalContentMetadata> externalContentMetadata;

	@OneToMany(fetch = FetchType.EAGER, cascade = CascadeType.REMOVE)
	@JoinColumn(name = "i_id")
	private List<ContentExternalAttribute> contentExternalAttribute;

	

	@OneToMany(fetch = FetchType.EAGER, cascade = CascadeType.REMOVE)
	@JoinColumn(name = "i_id")
	private List<ContentAttachment> contentAttachment;

	@OneToMany(fetch = FetchType.EAGER)
	@JoinColumn(name = "i_id")
	private List<ItemAssetAttribute> itemAssetAttribute;

	@OneToMany(fetch = FetchType.EAGER, cascade = CascadeType.REMOVE)
	@JoinColumn(name = "i_id")
	private List<PassageItemSet> passageItemSet;

	@OneToMany(fetch = FetchType.EAGER, cascade = CascadeType.ALL)
	@JoinColumn(name = "i_id")
	private List<ItemStandard> itemStandardList;

	@OneToOne(mappedBy = "item")
	private ItemMoveDetails itemMoveDetails;

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
	 * @return the isOldVersion
	 */
	public int getIsOldVersion() {
		return isOldVersion;
	}

	/**
	 * @param isOldVersion
	 *            the isOldVersion to set
	 */
	public void setIsOldVersion(int isOldVersion) {
		this.isOldVersion = isOldVersion;
	}

	/**
	 * 
	 * @param type
	 * @return A map of item characterizations
	 */
	@SuppressWarnings("boxing")
	// FIXME will only return a single item characterization instead of list of
	// item characterizations by type
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
		return gradeLevel == null ? null
				: (gradeLevel.getIntValue() == 0 ? "K" : String
						.valueOf(gradeLevel.getIntValue()));
	}

	public String getSubject() {
		ItemCharacterization subject = this.getCharacterization(2);
		return subject == null ? null : (subject.getIntValue() == 1 ? "MATH"
				: "ELA");
	}

	public String getMinimumGrade() {
		ItemCharacterization gradeLevel = this.getCharacterization(5);
		return gradeLevel == null ? null
				: (gradeLevel.getIntValue() == 0 ? "K" : String
						.valueOf(gradeLevel.getIntValue()));
	}

	public String getMaximumGrade() {
		ItemCharacterization gradeLevel = this.getCharacterization(6);
		return gradeLevel == null ? null
				: (gradeLevel.getIntValue() == 0 ? "K" : String
						.valueOf(gradeLevel.getIntValue()));
	}

	public String getPoint() {
		ItemCharacterization point = this.getCharacterization(7);
		return point == null ? null : Integer.toString(point.getIntValue());
	}

	public String getDepthOfKnowdledge() {
		ItemCharacterization dok = this.getCharacterization(8);
		return dok == null ? null : Integer.toString(dok.getIntValue());
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

	public int getItemFormat() {
		return itemFormat;
	}

	public void setItemFormat(int itemFormat) {
		this.itemFormat = itemFormat;
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

	/**
	 * @return the itemGuid
	 */
	public String getItemGuid() {
		return itemGuid;
	}

	/**
	 * @param itemGuid
	 *            the itemGuid to set
	 */
	public void setItemGuid(String itemGuid) {
		this.itemGuid = itemGuid;
	}

	/**
	 * @return the itemTeiData
	 */
	public String getItemTeiData() {
		return itemTeiData;
	}

	/**
	 * @param itemTeiData
	 *            the itemTeiData to set
	 */
	public void setItemTeiData(String itemTeiData) {
		this.itemTeiData = itemTeiData;
	}

	/**
	 * @return the itemIsPiSet
	 */
	public int getItemIsPiSet() {
		return itemIsPiSet;
	}

	/**
	 * @param itemIsPiSet
	 *            the itemIsPiSet to set
	 */
	public void setItemIsPiSet(int itemIsPiSet) {
		this.itemIsPiSet = itemIsPiSet;
	}

	/**
	 * @return the itemLastSaveUserId
	 */
	public User getItemLastSaveUserId() {
		return itemLastSaveUserId;
	}

	/**
	 * @param itemLastSaveUserId
	 *            the itemLastSaveUserId to set
	 */
	public void setItemLastSaveUserId(User itemLastSaveUserId) {
		this.itemLastSaveUserId = itemLastSaveUserId;
	}

	/**
	 * @return the itemXmlData
	 */
	public String getItemXmlData() {
		return itemXmlData;
	}

	/**
	 * @param itemXmlData
	 *            the itemXmlData to set
	 */
	public void setItemXmlData(String itemXmlData) {
		this.itemXmlData = itemXmlData;
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

	public Integer getPublicationStatus() {
		return publicationStatus;
	}

	public void setPublicationStatus(Integer publicationStatus) {
		this.publicationStatus = publicationStatus;
	}

	/**
	 * @return the primaryStandard
	 */
	public String getPrimaryStandard() {
		return primaryStandard;
	}

	/**
	 * @param primaryStandard
	 *            the primaryStandard to set
	 */
	public void setPrimaryStandard(String primaryStandard) {
		this.primaryStandard = primaryStandard;
	}

	public PublicationStatus getItemPublicationStatus() {
		return itemPublicationStatus;
	}

	public void setItemPublicationStatus(PublicationStatus itemPublicationStatus) {
		this.itemPublicationStatus = itemPublicationStatus;
	}

	/**
	 * @return the itemCharacterizationMap
	 */
	public Map<Integer, ItemCharacterization> getItemCharacterizationMap() {
		return itemCharacterizationMap;
	}

	/**
	 * @param itemCharacterizationMap
	 *            the itemCharacterizationMap to set
	 */
	public void setItemCharacterizationMap(
			Map<Integer, ItemCharacterization> itemCharacterizationMap) {
		this.itemCharacterizationMap = itemCharacterizationMap;
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
	 * @return the itemAssetAttribute
	 */
	public List<ItemAssetAttribute> getItemAssetAttribute() {
		return itemAssetAttribute;
	}

	/**
	 * @param itemAssetAttribute
	 *            the itemAssetAttribute to set
	 */
	public void setItemAssetAttribute(
			List<ItemAssetAttribute> itemAssetAttribute) {
		this.itemAssetAttribute = itemAssetAttribute;
	}

	/**
	 * @return the passageItemSet
	 */
	public List<PassageItemSet> getPassageItemSet() {
		return passageItemSet;
	}

	/**
	 * @param passageItemSet
	 *            the passageItemSet to set
	 */
	public void setPassageItemSet(List<PassageItemSet> passageItemSet) {
		this.passageItemSet = passageItemSet;
	}

	/**
	 * @return the itemStandard
	 */
	public List<ItemStandard> getItemStandardList() {
		return itemStandardList;
	}

	/**
	 * @param itemStandard
	 *            the itemStandard to set
	 */
	public void setItemStandardList(List<ItemStandard> itemStandardList) {
		this.itemStandardList = itemStandardList;
	}

	public String getItemFormatName() {

		switch (itemFormat) {
		case 1:
			return "Selected Response";
		case 2:
			return "Constructed Response";
		case 3:
			return "Activity Based";
		case 4:
			return "Performance Task";
		case 5:
			return "Unsupported";
		default:
			return "";
		}
	}

	public ItemMoveDetails getItemMoveDetails() {
		return itemMoveDetails;
	}

	public void setItemMoveDetails(ItemMoveDetails itemMoveDetails) {
		this.itemMoveDetails = itemMoveDetails;
	}

	public String getPackageFormatName() {
		if (itemMoveDetails != null
				&& itemMoveDetails.getItemMoveMonitor() != null
				&& itemMoveDetails.getItemMoveMonitor().getItemPackageFormat() != null) {
			return itemMoveDetails.getItemMoveMonitor().getItemPackageFormat()
					.getName();
		}
		return "";
	}
}