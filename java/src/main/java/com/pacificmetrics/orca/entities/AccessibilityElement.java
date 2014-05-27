package com.pacificmetrics.orca.entities;

import java.io.Serializable;
import java.util.List;

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
import javax.persistence.OneToMany;
import javax.persistence.Table;

@Entity
@Table(name="accessibility_element")
@NamedQueries({
	@NamedQuery(name="aeByItemId", 
		        query="select ae from AccessibilityElement ae where ae.itemId = :i_id order by ae.name"),
	@NamedQuery(name="aeDeleteForItemId", 
                query="delete from AccessibilityElement ae where ae.itemId = :i_id and ae.name NOT IN :nameList"),
	@NamedQuery(name="aeDeleteForItemIdNoRetain", 
                query="delete from AccessibilityElement ae where ae.itemId = :i_id"),
    @NamedQuery(name="aeByPassageId", 
                query="select ae from AccessibilityElement ae where ae.passageId = :p_id order by ae.name"),
    @NamedQuery(name="aeDeleteForPassageId", 
                query="delete from AccessibilityElement ae where ae.passageId = :p_id and ae.name NOT IN :nameList"),
    @NamedQuery(name="aeDeleteForPassageIdNoRetain", 
                query="delete from AccessibilityElement ae where ae.passageId = :p_id")
                
})

public class AccessibilityElement implements Serializable {

	private static final long serialVersionUID = 1L;
	
	static public final int CT_QTI = 1; //Content type QTI
	static public final int CT_APIP = 2; //Content type APIP
	
	static public final int CLT_TEXT = 1; //Content link type TEXT
	static public final int CLT_OBJECT = 2; //Content link type OBJECT
	
	static public final int TLT_FULL_STRING = 1; //Text link type Full String
	static public final int TLT_CHAR_SEQUENCE = 2; //Text link type Character Sequence
	static public final int TLT_WORD = 3; //Text link type Word
	
	@Id
    @GeneratedValue(strategy=GenerationType.IDENTITY)
	@Column(name="ae_id")
	private int id;
	
	@Basic
	@Column(name="i_id")
	private long itemId;
	
    @Basic
    @Column(name="p_id")
    private int passageId;
    
	@Basic
	@Column(name="ae_name")
	private String name;
	
	@Basic
	@Column(name="ae_content_type")
	private int contentType;
	
	@Basic
	@Column(name="ae_content_name")
	private String contentName;

	@Basic
	@Column(name="ae_content_link_type")
	private int contentLinkType;

	@Basic
	@Column(name="ae_text_link_type")
	private int textLinkType;

	@Basic
	@Column(name="ae_text_link_word")
	private int textLinkWord;

	@Basic
	@Column(name="ae_text_link_start_char")
	private int textLinkStartChar;

	@Basic
	@Column(name="ae_text_link_stop_char")
	private int textLinkStopChar;
	
	@OneToMany(fetch=FetchType.EAGER)
	@JoinColumn(name="ae_id")
	private List<AccessibilityFeature> featureList;

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public long getItemId() {
		return itemId;
	}

	public void setItemId(long itemId) {
		this.itemId = itemId;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public int getContentType() {
		return contentType;
	}

	public void setContentType(int contentType) {
		this.contentType = contentType;
	}

	public String getContentName() {
		return contentName;
	}

	public void setContentName(String contentName) {
		this.contentName = contentName;
	}

	public int getContentLinkType() {
		return contentLinkType;
	}

	public void setContentLinkType(int contentLinkType) {
		this.contentLinkType = contentLinkType;
	}

	public int getTextLinkType() {
		return textLinkType;
	}

	public void setTextLinkType(int textLinkType) {
		this.textLinkType = textLinkType;
	}

	public int getTextLinkWord() {
		return textLinkWord;
	}

	public void setTextLinkWord(int textLinkWord) {
		this.textLinkWord = textLinkWord;
	}

	public int getTextLinkStartChar() {
		return textLinkStartChar;
	}

	public void setTextLinkStartChar(int textLinkStartChar) {
		this.textLinkStartChar = textLinkStartChar;
	}

	public int getTextLinkStopChar() {
		return textLinkStopChar;
	}

	public void setTextLinkStopChar(int textLinkStopChar) {
		this.textLinkStopChar = textLinkStopChar;
	}

	public List<AccessibilityFeature> getFeatureList() {
		return featureList;
	}

	public void setFeatureList(List<AccessibilityFeature> featureList) {
		this.featureList = featureList;
	}

    public int getPassageId() {
        return passageId;
    }

    public void setPassageId(int passageId) {
        this.passageId = passageId;
    }
	
}
