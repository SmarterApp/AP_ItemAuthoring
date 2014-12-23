package com.pacificmetrics.ims.apip.metadata;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;

import org.apache.commons.lang.StringUtils;

@XmlRootElement(name = "metadata")
@XmlAccessorType(XmlAccessType.FIELD)
public class APIPMetadata {

    @XmlElement(name = "SB_Acknowledgements", required = false)
    private String acknowledgements;
    @XmlElement(name = "SB_ContentTargetLink", required = false)
    private String contentTargetLink;
    @XmlElement(name = "SB_LinkToScoringTable", required = false)
    private String linkToScoringTable;
    @XmlElement(name = "SB_LinkToItemStats", required = false)
    private String linkToItemStat;
    @XmlElement(name = "SB_LinkToItemAssets", required = false)
    private String linkToItemAssets;
    @XmlElement(name = "SB_Braille", required = false)
    private String braille;
    @XmlElement(name = "SB_App", required = false)
    private String app;
    @XmlElement(name = "SB_PTWritingType", required = false)
    private String ptWritingType;

    @XmlElement(name = "SB_TechnologyEnabled", required = false)
    private String technologyEnabled;
    @XmlElement(name = "SB_TechnologyEnhanced", required = false)
    private String technologyEnhanced;

    @XmlElement(name = "SB_Item-TaskNotes", required = false)
    private String itemTaskNotes;
    @XmlElement(name = "SB_Target-SpecificAttributes", required = false)
    private String targetSpecificAttributes;
    @XmlElement(name = "SB_Target-specificAttributes", required = false)
    private String targetSpecificAttribute;
    @XmlElement(name = "SB_EnemyItem", required = false)
    private String enemyItem;

    @XmlElement(name = "SB_PassageLength", required = false)
    private String passageLength;
    @XmlElement(name = "SB_StimulusType", required = false)
    private String stimulusType;
    @XmlElement(name = "SB_StimulusID", required = false)
    private String stimulusId;
    @XmlElement(name = "SB_Stimulus-Passages", required = false)
    private String stimulusPassages;
    @XmlElement(name = "SB_Stimulus-Source", required = false)
    private String stimulusSource;

    @XmlElement(name = "SB_MaximumGrade", required = false)
    private String maxmimumGrade;
    @XmlElement(name = "SB_MinimumGrade", required = false)
    private String minimumGrade;
    @XmlElement(name = "SB_DOK", required = false)
    private String depthOfKnowledge;
    @XmlElement(name = "SB_Difficulty", required = false)
    private String difficulty;

    @XmlElement(name = "SB_Key", required = false)
    private String key;
    @XmlElement(name = "SB_MaximumPoints", required = false)
    private String maximumPoints;
    @XmlElement(name = "SB_MaxPoints", required = false)
    private String maxPoints;
    @XmlElement(name = "SB_ScorePoints", required = false)
    private String scorePoints;
    @XmlElement(name = "SB_HumanScored", required = false)
    private String humandScored;
    @XmlElement(name = "SB_AI-Scored", required = false)
    private String aiScored;
    @XmlElement(name = "SB_AllowCalculator", required = false)
    private String allowCalculator;

    @XmlElement(name = "SB_MathematicalPractices", required = false)
    private String mathameticalPractices;

    @XmlElement(name = "SB_PrimaryContentDomain", required = false)
    private String primaryContentDomain;
    @XmlElement(name = "SB_SecondaryContentDomains", required = false)
    private String secondaryContentDomains;
    @XmlElement(name = "SB_Standards", required = false)
    private String standards;
    @XmlElement(name = "SB_Brief_Write_or_Revision", required = false)
    private String briefWriteOrRevision;

    @XmlElement(name = "SB_SuffEvdncOfClaim", required = false)
    private String sufficientEvidanceOfClaim;
    @XmlElement(name = "SB_PrimaryClaim", required = false)
    private String primaryClaim;
    @XmlElement(name = "SB_SecondaryClaims", required = false)
    private String secondaryClaims;
    @XmlElement(name = "SB_Claim1_Category", required = false)
    private String claim1Category;
    @XmlElement(name = "SB_Claim2_Category", required = false)
    private String claim2Category;
    @XmlElement(name = "SB_Claim3_Category", required = false)
    private String claim3Category;
    @XmlElement(name = "SB_Claim4_Category", required = false)
    private String claim4Category;
    @XmlElement(name = "SB_Claim5_Category", required = false)
    private String claim5Category;
    @XmlElement(name = "SB_Claim6_Category", required = false)
    private String claim6Category;
    @XmlElement(name = "SB_Claim7_Category", required = false)
    private String claim7Category;
    @XmlElement(name = "SB_Claim8_Category", required = false)
    private String claim8Category;
    @XmlElement(name = "SB_Claim9_Category", required = false)
    private String claim9Category;

    @XmlElement(name = "SB_AssessmentTargets", required = false)
    private String assessmentTargets;
    @XmlElement(name = "SB_ItemID", required = false)
    private String itemId;
    @XmlElement(name = "SB_SampleItemID", required = false)
    private String sampleItemId;

    @XmlElement(name = "SYSTEM_ItemID", required = false)
    private String systemId;
    @XmlElement(name = "SYSTEM_ItemType", required = false)
    private String systemItemType;
    @XmlElement(name = "SYSTEM_ItemVersion", required = false)
    private String systemVersion;
    @XmlElement(name = "SYSTEM_Subject", required = false)
    private String systemSubject;
    @XmlElement(name = "SYSTEM_ItemSubcategory", required = false)
    private String systemItemSubCategory;
    @XmlElement(name = "SYSTEM_Grade", required = false)
    private String systemGrade;
    @XmlElement(name = "SYSTEM_Workflow", required = false)
    private String systemWorkflow;
    @XmlElement(name = "SYSTEM_Status", required = false)
    private String systemStatus;
    @XmlElement(name = "SYSTEM_ItemKeywords", required = false)
    private String systemItemKeyword;
    @XmlElement(name = "SYSTEM_DateCreated", required = false)
    private String systemDateCreated;
    @XmlElement(name = "SYSTEM_LastApprovedDate", required = false)
    private String systemLastApprovedDate;
    @XmlElement(name = "SYSTEM_LinkedPassageID", required = false)
    private String systemLinkedPassageId;
    @XmlElement(name = "SYSTEM_PerformanceTaskID", required = false)
    private String systemPerformanceTaskId;
    @XmlElement(name = "SYSTEM_Author", required = false)
    private String systemAuthor;
    @XmlElement(name = "SYSTEM_Source", required = false)
    private String systemSource;
    @XmlElement(name = "SYSTEM_Copyright", required = false)
    private String systemCopyright;

    public String getAcknowledgements() {
        return acknowledgements;
    }

    public void setAcknowledgements(String acknowledgements) {
        this.acknowledgements = acknowledgements;
    }

    public String getContentTargetLink() {
        return contentTargetLink;
    }

    public void setContentTargetLink(String contentTargetLink) {
        this.contentTargetLink = contentTargetLink;
    }

    public String getLinkToScoringTable() {
        return linkToScoringTable;
    }

    public void setLinkToScoringTable(String linkToScoringTable) {
        this.linkToScoringTable = linkToScoringTable;
    }

    public String getLinkToItemStat() {
        return linkToItemStat;
    }

    public void setLinkToItemStat(String linkToItemStat) {
        this.linkToItemStat = linkToItemStat;
    }

    public String getLinkToItemAssets() {
        return linkToItemAssets;
    }

    public void setLinkToItemAssets(String linkToItemAssets) {
        this.linkToItemAssets = linkToItemAssets;
    }

    public String getBraille() {
        return braille;
    }

    public void setBraille(String braille) {
        this.braille = braille;
    }

    public String getApp() {
        return app;
    }

    public void setApp(String app) {
        this.app = app;
    }

    public String getPtWritingType() {
        return ptWritingType;
    }

    public void setPtWritingType(String ptWritingType) {
        this.ptWritingType = ptWritingType;
    }

    public String getTechnologyEnabled() {
        return technologyEnabled;
    }

    public void setTechnologyEnabled(String technologyEnabled) {
        this.technologyEnabled = technologyEnabled;
    }

    public String getTechnologyEnhanced() {
        return technologyEnhanced;
    }

    public void setTechnologyEnhanced(String technologyEnhanced) {
        this.technologyEnhanced = technologyEnhanced;
    }

    public String getItemTaskNotes() {
        return itemTaskNotes;
    }

    public void setItemTaskNotes(String itemTaskNotes) {
        this.itemTaskNotes = itemTaskNotes;
    }

    public String getTargetSpecificAttributes() {
        return targetSpecificAttributes;
    }

    public void setTargetSpecificAttributes(String targetSpecificAttributes) {
        this.targetSpecificAttributes = targetSpecificAttributes;
    }

    public String getTargetSpecificAttribute() {
        return targetSpecificAttribute;
    }

    public void setTargetSpecificAttribute(String targetSpecificAttribute) {
        this.targetSpecificAttribute = targetSpecificAttribute;
    }

    public String getEnemyItem() {
        return enemyItem;
    }

    public void setEnemyItem(String enemyItem) {
        this.enemyItem = enemyItem;
    }

    public String getPassageLength() {
        return passageLength;
    }

    public void setPassageLength(String passageLength) {
        this.passageLength = passageLength;
    }

    public String getStimulusType() {
        return stimulusType;
    }

    public void setStimulusType(String stimulusType) {
        this.stimulusType = stimulusType;
    }

    public String getStimulusId() {
        return stimulusId;
    }

    public void setStimulusId(String stimulusId) {
        this.stimulusId = stimulusId;
    }

    public String getStimulusPassages() {
        return stimulusPassages;
    }

    public void setStimulusPassages(String stimulusPassages) {
        this.stimulusPassages = stimulusPassages;
    }

    public String getStimulusSource() {
        return stimulusSource;
    }

    public void setStimulusSource(String stimulusSource) {
        this.stimulusSource = stimulusSource;
    }

    public String getMaxmimumGrade() {
        return maxmimumGrade;
    }

    public void setMaxmimumGrade(String maxmimumGrade) {
        this.maxmimumGrade = maxmimumGrade;
    }

    public String getMinimumGrade() {
        return minimumGrade;
    }

    public void setMinimumGrade(String minimumGrade) {
        this.minimumGrade = minimumGrade;
    }

    public String getDepthOfKnowledge() {
        return depthOfKnowledge;
    }

    public void setDepthOfKnowledge(String depthOfKnowledge) {
        this.depthOfKnowledge = depthOfKnowledge;
    }

    public String getDifficulty() {
        return difficulty;
    }

    public void setDifficulty(String difficulty) {
        this.difficulty = difficulty;
    }

    public String getKey() {
        return key;
    }

    public void setKey(String key) {
        this.key = key;
    }

    public String getMaxPoints() {
        return maxPoints;
    }

    public void setMaxPoints(String maxPoints) {
        this.maxPoints = maxPoints;
    }

    public String getScorePoints() {
        return scorePoints;
    }

    public void setScorePoints(String scorePoints) {
        this.scorePoints = scorePoints;
    }

    public String getPoint() {
        if (StringUtils.isNotBlank(this.scorePoints)
                && this.scorePoints.split(",").length > 0) {
            String pointArray[] = scorePoints.split(",");
            return pointArray[pointArray.length - 1];
        }
        return "0";
    }

    public String getHumandScored() {
        return humandScored;
    }

    public void setHumandScored(String humandScored) {
        this.humandScored = humandScored;
    }

    public String getAiScored() {
        return aiScored;
    }

    public void setAiScored(String aiScored) {
        this.aiScored = aiScored;
    }

    public String getAllowCalculator() {
        return allowCalculator;
    }

    public void setAllowCalculator(String allowCalculator) {
        this.allowCalculator = allowCalculator;
    }

    public String getMathameticalPractices() {
        return mathameticalPractices;
    }

    public void setMathameticalPractices(String mathameticalPractices) {
        this.mathameticalPractices = mathameticalPractices;
    }

    public String getPrimaryContentDomain() {
        return primaryContentDomain;
    }

    public void setPrimaryContentDomain(String primaryContentDomain) {
        this.primaryContentDomain = primaryContentDomain;
    }

    public String getSecondaryContentDomains() {
        return secondaryContentDomains;
    }

    public void setSecondaryContentDomains(String secondaryContentDomains) {
        this.secondaryContentDomains = secondaryContentDomains;
    }

    public String getStandards() {
        return standards;
    }

    public void setStandards(String standards) {
        this.standards = standards;
    }

    public String getBriefWriteOrRevision() {
        return briefWriteOrRevision;
    }

    public void setBriefWriteOrRevision(String briefWriteOrRevision) {
        this.briefWriteOrRevision = briefWriteOrRevision;
    }

    public String getSufficientEvidanceOfClaim() {
        return sufficientEvidanceOfClaim;
    }

    public void setSufficientEvidanceOfClaim(String sufficientEvidanceOfClaim) {
        this.sufficientEvidanceOfClaim = sufficientEvidanceOfClaim;
    }

    public String getPrimaryClaim() {
        return primaryClaim;
    }

    public void setPrimaryClaim(String primaryClaim) {
        this.primaryClaim = primaryClaim;
    }

    public String getSecondaryClaims() {
        return secondaryClaims;
    }

    public void setSecondaryClaims(String secondaryClaims) {
        this.secondaryClaims = secondaryClaims;
    }

    public String getClaim1Category() {
        return claim1Category;
    }

    public void setClaim1Category(String claim1Category) {
        this.claim1Category = claim1Category;
    }

    public String getClaim2Category() {
        return claim2Category;
    }

    public void setClaim2Category(String claim2Category) {
        this.claim2Category = claim2Category;
    }

    public String getClaim3Category() {
        return claim3Category;
    }

    public void setClaim3Category(String claim3Category) {
        this.claim3Category = claim3Category;
    }

    public String getClaim4Category() {
        return claim4Category;
    }

    public void setClaim4Category(String claim4Category) {
        this.claim4Category = claim4Category;
    }

    public String getClaim5Category() {
        return claim5Category;
    }

    public void setClaim5Category(String claim5Category) {
        this.claim5Category = claim5Category;
    }

    public String getClaim6Category() {
        return claim6Category;
    }

    public void setClaim6Category(String claim6Category) {
        this.claim6Category = claim6Category;
    }

    public String getClaim7Category() {
        return claim7Category;
    }

    public void setClaim7Category(String claim7Category) {
        this.claim7Category = claim7Category;
    }

    public String getClaim8Category() {
        return claim8Category;
    }

    public void setClaim8Category(String claim8Category) {
        this.claim8Category = claim8Category;
    }

    public String getClaim9Category() {
        return claim9Category;
    }

    public void setClaim9Category(String claim9Category) {
        this.claim9Category = claim9Category;
    }

    public String getAssessmentTargets() {
        return assessmentTargets;
    }

    public void setAssessmentTargets(String assessmentTargets) {
        this.assessmentTargets = assessmentTargets;
    }

    public String getItemId() {
        return itemId;
    }

    public void setItemId(String itemId) {
        this.itemId = itemId;
    }

    public String getSampleItemId() {
        return sampleItemId;
    }

    public void setSampleItemId(String sampleItemId) {
        this.sampleItemId = sampleItemId;
    }

    public String getSystemId() {
        return systemId;
    }

    public void setSystemId(String systemId) {
        this.systemId = systemId;
    }

    public String getSystemItemType() {
        return systemItemType;
    }

    public void setSystemItemType(String systemItemType) {
        this.systemItemType = systemItemType;
    }

    public String getSystemVersion() {
        return systemVersion;
    }

    public void setSystemVersion(String systemVersion) {
        this.systemVersion = systemVersion;
    }

    public String getSystemSubject() {
        return systemSubject;
    }

    public void setSystemSubject(String systemSubject) {
        this.systemSubject = systemSubject;
    }

    public String getSystemItemSubCategory() {
        return systemItemSubCategory;
    }

    public void setSystemItemSubCategory(String systemItemSubCategory) {
        this.systemItemSubCategory = systemItemSubCategory;
    }

    public String getSystemGrade() {
        return systemGrade;
    }

    public void setSystemGrade(String systemGrade) {
        this.systemGrade = systemGrade;
    }

    public String getSystemWorkflow() {
        return systemWorkflow;
    }

    public void setSystemWorkflow(String systemWorkflow) {
        this.systemWorkflow = systemWorkflow;
    }

    public String getSystemStatus() {
        return systemStatus;
    }

    public void setSystemStatus(String systemStatus) {
        this.systemStatus = systemStatus;
    }

    public String getSystemItemKeyword() {
        return systemItemKeyword;
    }

    public void setSystemItemKeyword(String systemItemKeyword) {
        this.systemItemKeyword = systemItemKeyword;
    }

    public String getSystemDateCreated() {
        return systemDateCreated;
    }

    public void setSystemDateCreated(String systemDateCreated) {
        this.systemDateCreated = systemDateCreated;
    }

    public String getSystemLastApprovedDate() {
        return systemLastApprovedDate;
    }

    public void setSystemLastApprovedDate(String systemLastApprovedDate) {
        this.systemLastApprovedDate = systemLastApprovedDate;
    }

    public String getSystemLinkedPassageId() {
        return systemLinkedPassageId;
    }

    public void setSystemLinkedPassageId(String systemLinkedPassageId) {
        this.systemLinkedPassageId = systemLinkedPassageId;
    }

    public String getSystemPerformanceTaskId() {
        return systemPerformanceTaskId;
    }

    public void setSystemPerformanceTaskId(String systemPerformanceTaskId) {
        this.systemPerformanceTaskId = systemPerformanceTaskId;
    }

    public String getSystemAuthor() {
        return systemAuthor;
    }

    public void setSystemAuthor(String systemAuthor) {
        this.systemAuthor = systemAuthor;
    }

    public String getSystemSource() {
        return systemSource;
    }

    public void setSystemSource(String systemSource) {
        this.systemSource = systemSource;
    }

    public String getSystemCopyright() {
        return systemCopyright;
    }

    public void setSystemCopyright(String systemCopyright) {
        this.systemCopyright = systemCopyright;
    }

    public String getMaximumPoints() {
        return maximumPoints;
    }

    public void setMaximumPoints(String maximumPoints) {
        this.maximumPoints = maximumPoints;
    }

}
