package com.pacificmetrics.orca.export.saaif;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class SAAIFItem {
	private String id;
	private String uniqueId;
	private String externalId;
	private int version;
	private String bankKey;
	private String format;
	private String type;
	private Map<String,String> attachments;
	private Map<String,String> assets;
	private List<SAAIFItem> tutorials;
	private List<SAAIFItem> wordlists;
	private List<SAAIFItem> passages; 
	private String href;
    private String hrefBase;
    private String metadataHref;
    private String metadataHrefBase;
    private String xmlContent;
    private String metadataXmlContent;
    
	public String getId() {
		return id;
	}
	public void setId(String id) {
		this.id = id;
	}
	public String getUniqueId() {
		return uniqueId;
	}
	public void setUniqueId(String uniqueId) {
		this.uniqueId = uniqueId;
	}
	public int getVersion() {
		return version;
	}
	public void setVersion(int version) {
		this.version = version;
	}
	public String getBankKey() {
		return bankKey;
	}
	public void setBankKey(String bankKey) {
		this.bankKey = bankKey;
	}
	public String getFormat() {
		return format;
	}
	public void setFormat(String format) {
		this.format = format;
	}
	public String getType() {
		return type;
	}
	public void setType(String type) {
		this.type = type;
	}
	public String getHref() {
		return href;
	}
	public void setHref(String href) {
		this.href = href;
	}
	public String getHrefBase() {
		return hrefBase;
	}
	public void setHrefBase(String hrefBase) {
		this.hrefBase = hrefBase;
	}
	public String getMetadataHref() {
		return metadataHref;
	}
	public void setMetadataHref(String metadataHref) {
		this.metadataHref = metadataHref;
	}
	public String getMetadataHrefBase() {
		return metadataHrefBase;
	}
	public void setMetadataHrefBase(String metadataHrefBase) {
		this.metadataHrefBase = metadataHrefBase;
	}
	public Map<String, String> getAttachments() {
		return attachments;
	}
	public void setAttachments(Map<String, String> attachments) {
		this.attachments = attachments;
	}
	public Map<String, String> getAssets() {
		return assets;
	}
	public void setAssets(Map<String, String> assets) {
		this.assets = assets;
	}
	
	public List<SAAIFItem> getTutorials() {
		if (tutorials == null) {
			tutorials = new ArrayList<SAAIFItem>();
		}
		return tutorials;
	}
	public void setTutorials(List<SAAIFItem> tutorials) {
		this.tutorials = tutorials;
	}
	
	public SAAIFItem getTutorialById(String tutorialId) {
		for( SAAIFItem tutorial : getTutorials()) { 
			if(tutorial.getId().equalsIgnoreCase(tutorialId)) {
				return tutorial;
			}
		}
		return null;
	}
	
	public boolean isTutorialAdded(String newTutorialId) {
		for( SAAIFItem tutorial : getTutorials()) { 
			if(tutorial.getId().equalsIgnoreCase(newTutorialId)) {
				return true;
			}
		}
		return false;
	}
	
	public List<SAAIFItem> getWordlists() {
		if(wordlists == null) {
			wordlists = new ArrayList<SAAIFItem> ();
		}
		return wordlists;
	}
	public void setWordlists(List<SAAIFItem> wordlists) {
		this.wordlists = wordlists;
	}
	
	public boolean isWordlistAdded(String newWordlistId) {
		for( SAAIFItem wordlist : getWordlists()) { 
			if(wordlist.getId().equalsIgnoreCase(newWordlistId)) {
				return true;
			}
		}
		return false;
	}
	
	public SAAIFItem getWordlistById(String wordlistId) {
		for( SAAIFItem wordlist : getWordlists()) { 
			if(wordlist.getId().equalsIgnoreCase(wordlistId)) {
				return wordlist;
			}
		}
		return null;
	}
	
	public List<SAAIFItem> getPassages() {
		if(passages == null) {
			passages = new ArrayList<SAAIFItem>();
		}
		return passages;
	}
	
	public void setPassages(List<SAAIFItem> passages) {
		this.passages = passages;
	}
	
	public boolean isPassageAdded(String newPassageId) {
		for( SAAIFItem passage : getPassages()) { 
			if(passage.getId().equalsIgnoreCase(newPassageId)) {
				return true;
			}
		}
		return false;
	}
	
	public SAAIFItem getPassageById(String passageId) {
		for( SAAIFItem passage : getPassages()) { 
			if(passage.getId().equalsIgnoreCase(passageId)) {
				return passage;
			}
		}
		return null;
	}
	
	public String getXmlContent() {
		return xmlContent;
	}
	public void setXmlContent(String xmlContent) {
		this.xmlContent = xmlContent;
	}
	public String getMetadataXmlContent() {
		return metadataXmlContent;
	}
	public void setMetadataXmlContent(String metadataXmlContent) {
		this.metadataXmlContent = metadataXmlContent;
	}
	public String getExternalId() {
		return externalId;
	}
	public void setExternalId(String externalId) {
		this.externalId = externalId;
	}
    
}
