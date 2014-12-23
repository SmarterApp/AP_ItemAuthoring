package com.pacificmetrics.orca.export.ims;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class IMSItem {

    private String identifier;
    private String title;
    private String adaptive;
    private String timeDependent;
    private String externalId;
    private String format;
    private String bankKey;

    private Map<String, String> attachments;
    private Map<String, String> assets;
    private List<IMSItem> passages;

    private String href;
    private String hrefBase;
    private String metadataHref;
    private String metadataHrefBase;
    private String xmlContent;
    private String metadataXmlContent;

    /**
     * @return the identifier
     */
    public String getIdentifier() {
        return identifier;
    }

    /**
     * @param identifier
     *            the identifier to set
     */
    public void setIdentifier(String identifier) {
        this.identifier = identifier;
    }

    /**
     * @return the title
     */
    public String getTitle() {
        return title;
    }

    /**
     * @param title
     *            the title to set
     */
    public void setTitle(String title) {
        this.title = title;
    }

    /**
     * @return the adaptive
     */
    public String getAdaptive() {
        return adaptive;
    }

    /**
     * @param adaptive
     *            the adaptive to set
     */
    public void setAdaptive(String adaptive) {
        this.adaptive = adaptive;
    }

    /**
     * @return the timeDependent
     */
    public String getTimeDependent() {
        return timeDependent;
    }

    /**
     * @param timeDependent
     *            the timeDependent to set
     */
    public void setTimeDependent(String timeDependent) {
        this.timeDependent = timeDependent;
    }

    public String getExternalId() {
        return externalId;
    }

    public void setExternalId(String externalId) {
        this.externalId = externalId;
    }

    public String getFormat() {
        return format;
    }

    public void setFormat(String format) {
        this.format = format;
    }

    /**
     * @return the href
     */
    public String getHref() {
        return href;
    }

    /**
     * @param href
     *            the href to set
     */
    public void setHref(String href) {
        this.href = href;
    }

    /**
     * @return the hrefBase
     */
    public String getHrefBase() {
        return hrefBase;
    }

    /**
     * @param hrefBase
     *            the hrefBase to set
     */
    public void setHrefBase(String hrefBase) {
        this.hrefBase = hrefBase;
    }

    /**
     * @return the metadataHref
     */
    public String getMetadataHref() {
        return metadataHref;
    }

    /**
     * @param metadataHref
     *            the metadataHref to set
     */
    public void setMetadataHref(String metadataHref) {
        this.metadataHref = metadataHref;
    }

    /**
     * @return the metadataHrefBase
     */
    public String getMetadataHrefBase() {
        return metadataHrefBase;
    }

    /**
     * @param metadataHrefBase
     *            the metadataHrefBase to set
     */
    public void setMetadataHrefBase(String metadataHrefBase) {
        this.metadataHrefBase = metadataHrefBase;
    }

    /**
     * @return the xmlContent
     */
    public String getXmlContent() {
        return xmlContent;
    }

    /**
     * @param xmlContent
     *            the xmlContent to set
     */
    public void setXmlContent(String xmlContent) {
        this.xmlContent = xmlContent;
    }

    /**
     * @return the metadataXmlContent
     */
    public String getMetadataXmlContent() {
        return metadataXmlContent;
    }

    /**
     * @param metadataXmlContent
     *            the metadataXmlContent to set
     */
    public void setMetadataXmlContent(String metadataXmlContent) {
        this.metadataXmlContent = metadataXmlContent;
    }

    /**
     * @return the attachments
     */
    public Map<String, String> getAttachments() {
        return attachments;
    }

    /**
     * @param attachments
     *            the attachments to set
     */
    public void setAttachments(Map<String, String> attachments) {
        this.attachments = attachments;
    }

    /**
     * @return the assets
     */
    public Map<String, String> getAssets() {
        if (assets == null) {
            assets = new HashMap<String, String>();
        }
        return assets;
    }

    /**
     * @param assets
     *            the assets to set
     */
    public void setAssets(Map<String, String> assets) {
        this.assets = assets;
    }

    /**
     * @return the passages
     */
    public List<IMSItem> getPassages() {
        if (passages == null) {
            passages = new ArrayList<IMSItem>();
        }
        return passages;
    }

    /**
     * @param passages
     *            the passages to set
     */
    public void setPassages(List<IMSItem> passages) {
        this.passages = passages;
    }

	/**
	 * @return the bankKey
	 */
	public String getBankKey() {
		return bankKey;
	}

	/**
	 * @param bankKey the bankKey to set
	 */
	public void setBankKey(String bankKey) {
		this.bankKey = bankKey;
	}

    
}
