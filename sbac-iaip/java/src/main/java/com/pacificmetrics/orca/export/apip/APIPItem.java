/**
 * 
 */
package com.pacificmetrics.orca.export.apip;

import java.util.Set;

/**
 * @author maumock
 * 
 */
public class APIPItem {
    private String id;
    private String version;
    private Set<String> resources;
    private Set<String> interactionTypes;
    private String toolVersion;
    private String toolName;
    private String toolVendor;
    private boolean timeDependent;
    private String feedbackType;
    private boolean solutionAvailable;
    private boolean composite;
    private String href;
    private String hrefBase;
    private String metadataHref;
    private String metadataHrefBase;

    /**
     * @return the id
     */
    public String getId() {
        return this.id;
    }

    /**
     * @param id
     *            the id to set
     */
    public void setId(String id) {
        this.id = id;
    }

    /**
     * @return the version
     */
    public String getVersion() {
        return this.version;
    }

    /**
     * @param version
     *            the version to set
     */
    public void setVersion(String version) {
        this.version = version;
    }

    /**
     * @return the resources
     */
    public Set<String> getResources() {
        return this.resources;
    }

    /**
     * @param resources
     *            the resources to set
     */
    public void setResources(Set<String> resources) {
        this.resources = resources;
    }

    /**
     * @return the interactionTypes
     */
    public Set<String> getInteractionTypes() {
        return this.interactionTypes;
    }

    /**
     * @param interactionTypes
     *            the interactionTypes to set
     */
    public void setInteractionTypes(Set<String> interactionTypes) {
        this.interactionTypes = interactionTypes;
    }

    /**
     * @return the toolVersion
     */
    public String getToolVersion() {
        return this.toolVersion;
    }

    /**
     * @param toolVersion
     *            the toolVersion to set
     */
    public void setToolVersion(String toolVersion) {
        this.toolVersion = toolVersion;
    }

    /**
     * @return the toolName
     */
    public String getToolName() {
        return this.toolName;
    }

    /**
     * @param toolName
     *            the toolName to set
     */
    public void setToolName(String toolName) {
        this.toolName = toolName;
    }

    /**
     * @return the toolVendor
     */
    public String getToolVendor() {
        return this.toolVendor;
    }

    /**
     * @param toolVendor
     *            the toolVendor to set
     */
    public void setToolVendor(String toolVendor) {
        this.toolVendor = toolVendor;
    }

    /**
     * @return the timeDependent
     */
    public boolean isTimeDependent() {
        return this.timeDependent;
    }

    /**
     * @param timeDependent
     *            the timeDependent to set
     */
    public void setTimeDependent(boolean timeDependent) {
        this.timeDependent = timeDependent;
    }

    /**
     * @return the feedbackType
     */
    public String getFeedbackType() {
        return this.feedbackType;
    }

    /**
     * @param feedbackType
     *            the feedbackType to set
     */
    public void setFeedbackType(String feedbackType) {
        this.feedbackType = feedbackType;
    }

    /**
     * @return the solutionAvailable
     */
    public boolean isSolutionAvailable() {
        return this.solutionAvailable;
    }

    /**
     * @param solutionAvailable
     *            the solutionAvailable to set
     */
    public void setSolutionAvailable(boolean solutionAvailable) {
        this.solutionAvailable = solutionAvailable;
    }

    /**
     * @return the composite
     */
    public boolean isComposite() {
        return this.composite;
    }

    /**
     * @param composite
     *            the composite to set
     */
    public void setComposite(boolean composite) {
        this.composite = composite;
    }

    /**
     * @return the href
     */
    public String getHref() {
        return this.href;
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
        return this.hrefBase;
    }

    /**
     * @param hrefBase
     *            the hrefBase to set
     */
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
}
