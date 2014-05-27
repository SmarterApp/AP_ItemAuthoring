package com.pacificmetrics.orca.entities;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;

import org.apache.commons.lang.StringEscapeUtils;

@Entity
@Table(name="accessibility_feature")
@NamedQueries({
	@NamedQuery(name="afByElementId", 
		        query="select af from AccessibilityFeature af where af.elementId = :ae_id"),
    @NamedQuery(name="afDeleteForElementId", 
                query="delete from AccessibilityFeature af where af.elementId = :ae_id"),
    @NamedQuery(name="afDeleteForIdNotInList", 
    			query="delete from AccessibilityFeature af where af.id NOT IN :idList")

})

public class AccessibilityFeature implements Serializable {

	private static final long serialVersionUID = 1L;
	
	static public final int T_SPOKEN = 1; //F_AUDIO_FILE, F_AUDIO_TEXT, F_TEXT_TO_SPEECH 
	static public final int T_TACTILE= 2; //F_AUDIO_FILE, F_AUDIO_TEXT, F_BRAILLE_TEXT
	static public final int T_BRAILLE = 3; //F_BRAILLE_TEXT
	static public final int T_KEYWORD_TRANSLATION = 4; //
	static public final int T_HIGHLIGHTING = 5; //
	
	static public final String[] TYPES_AS_STRING = {"Spoken", "Tactile", "Braille", "Translation", "Highlighting"};
	static public final Map<Integer, String> TYPES_AS_STRING_MAP = new HashMap<Integer, String>();

	static public final int F_AUDIO_TEXT = 1;
	static public final int F_TEXT_TO_SPEECH = 2;
	static public final int F_BRAILLE_TEXT = 3;
	static public final int F_AUDIO_FILE = 4;
	static public final int F_HIGHLIGHTED_TEXT = 5;
	
	static public final String[] FEATURES_AS_STRING = {"Audio Text", "Text to Speech", "Braille Text", "Audio File", "Highlighted Text"};
	
	static {
		synchronized (AccessibilityFeature.class) {
//			for (int i = 0; i < TYPES_AS_STRING.length; i++) { 
//				TYPES_AS_STRING_MAP.put(i + 1, TYPES_AS_STRING[i]);
//			}
		    //For DE1054, need custom mapping as some of feature types are not supported yet
		    TYPES_AS_STRING_MAP.put(T_SPOKEN, TYPES_AS_STRING[0]);
		    TYPES_AS_STRING_MAP.put(T_BRAILLE, TYPES_AS_STRING[2]);
		}
	}
	
	@Id
    @GeneratedValue(strategy=GenerationType.IDENTITY)
	@Column(name="af_id")
	private int id;
	
	@Basic
	@Column(name="ae_id")
	private int elementId;
	
	@Basic
	@Column(name="af_type")
	private int type;
	
	@Basic
	@Column(name="af_feature")
	private int feature;
	
	@Basic
	@Column(name="af_info")
	private String info;
	
	@Basic
	@Column(name="lang_code")
	private String langCode;

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public int getElementId() {
		return elementId;
	}

	public void setElementId(int elementId) {
		this.elementId = elementId;
	}

	public int getFeature() {
		return feature;
	}

	public void setFeature(int feature) {
		this.feature = feature;
	}

	public String getInfo() {
		return info;
	}
	
	public String getUnescapedInfo() {
	    return StringEscapeUtils.unescapeHtml(getInfo());
	}

	public void setInfo(String info) {
		this.info = info;
	}
	
	public String getTypeAndFeatureAsString() {
		switch (getType()) {
		case T_SPOKEN:
		case T_TACTILE:
		case T_BRAILLE: return TYPES_AS_STRING[getType() - 1] + " - " + FEATURES_AS_STRING[getFeature() - 1];
		case T_KEYWORD_TRANSLATION: return TYPES_AS_STRING[getType() - 1] + " - " + getLangCode();  
		default: return TYPES_AS_STRING[getType() - 1];
		}
	}
	
	public int getType() {
		return type;
	}

	public void setType(int type) {
		this.type = type;
	}
	
	static public String getFeatureAsString(int feature) {
		return FEATURES_AS_STRING[feature - 1];
	}
	
	static public List<String> getFeaturesAsString(Iterable<Integer> features) {
		List<String> result = new ArrayList<String>();
		for (int feature: features) {
			result.add(FEATURES_AS_STRING[feature - 1]);
		}
		return result;
	}

	public String getLangCode() {
		return langCode;
	}

	public void setLangCode(String langCode) {
		this.langCode = langCode;
	}

}
