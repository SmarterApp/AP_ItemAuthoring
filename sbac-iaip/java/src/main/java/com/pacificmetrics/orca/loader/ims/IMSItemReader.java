package com.pacificmetrics.orca.loader.ims;

import java.io.File;
import java.io.IOException;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;

import javax.xml.bind.JAXBElement;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.io.FileUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.ieee.ltsc.lom.resource.DifficultyType;
import org.ieee.ltsc.lom.resource.EducationalType;
import org.ieee.ltsc.lom.resource.GeneralType;
import org.ieee.ltsc.lom.resource.IdentifierType;
import org.ieee.ltsc.lom.resource.LangStringType;
import org.ieee.ltsc.lom.resource.LanguageStringType;
import org.w3.synthesis.ObjectFactory;

import com.pacificmetrics.ims.apip.cp.ResourceMetadataType;
import com.pacificmetrics.ims.apip.cp.ResourceType;
import com.pacificmetrics.ims.apip.metadata.APIPMetadata;
import com.pacificmetrics.ims.apip.qti.item.AssessmentItem;
import com.pacificmetrics.ims.apip.qti.metadata.QtiMetadata;
import com.pacificmetrics.orca.utils.FileUtil;
import com.pacificmetrics.orca.utils.JAXBUtil;
import com.pacificmetrics.saaif.metadata.Metadata;
import com.pacificmetrics.saaif.metadata.Metadata.SmarterAppMetadata;
import com.pacificmetrics.saaif.metadata.Metadata.SmarterAppMetadata.StandardPublication;

public class IMSItemReader {

    private static final Log LOGGER = LogFactory.getLog(IMSItemReader.class);

    private static final DateFormat ASSETDATEFORMAT = new SimpleDateFormat(
            "yyyyMMdd_HHmmss");

    private static final String GENERAL_ID = "identifier";
    private static final String GENERAL_ID_ENTRY = "entry";
    private static final String GENERAL_TITLE = "title";    
    private static final String GENERAL_DESCRIPTION = "description";
    private static final String EDUCATION_DIFFICULTY = "difficulty";
    private static final String EDUCATION_DIFFICULTY_VALUE = "value";

    private IMSItemReader() {
    }

    public static IMSMetadata getItemMetadata(String outputZipFolder,
            ResourceType resource, Map<String, ResourceType> resourceMap) {
        IMSMetadata itemMetadata = new IMSMetadata();

        if (resource != null
                && IMSItemUtil.isSBACMetadataExists(outputZipFolder, resource)) {
            Metadata sbacMetadata = IMSManifestReader.readSBACMetadata(
                    outputZipFolder, resource, resourceMap);
            if (sbacMetadata != null
                    && sbacMetadata.getSmarterAppMetadata() != null) {
                SmarterAppMetadata sAppMetadata = sbacMetadata
                        .getSmarterAppMetadata();
                itemMetadata.setDifficulty(StringUtils.isNotBlank(sAppMetadata
                        .getEducationalDifficulty()) ? sAppMetadata
                        .getEducationalDifficulty()
                        : IMSPackageConstants.DEFAULT_DIFFICULTY);
                itemMetadata.setIdentifier(Integer.toString(sAppMetadata
                        .getIdentifier()));
                itemMetadata
                        .setPublicationStatus(StringUtils
                                .isNotBlank(sAppMetadata
                                        .getAdministrationDate()) ? sAppMetadata
                                .getAdministrationDate()
                                : IMSPackageConstants.DEFAULT_PUBLICATION_STATUS);
                itemMetadata.setLanguage(IMSPackageConstants.DEFAULT_LANG);
                itemMetadata.setGenre(StringUtils.isNotBlank(sAppMetadata
                        .getStimulusGenre()) ? sAppMetadata.getStimulusGenre()
                        : IMSPackageConstants.DEFAULT_GENRE);
                itemMetadata.setDescription(sAppMetadata.getSmarterAppItemDescriptor());
                itemMetadata.setTitle("");
                itemMetadata.setDepthOfKnowledge(Integer.toString(sAppMetadata
                        .getDepthOfKnowledge()));
                itemMetadata.setGradeStart(Integer.toString(sAppMetadata
                        .getMinimumGrade()));
                itemMetadata.setGradeEnd(Integer.toString(sAppMetadata
                        .getMinimumGrade()));
                itemMetadata.setSubject(sAppMetadata.getSubject());
                itemMetadata.setGrade(Integer.toString(sAppMetadata
                        .getIntendedGrade()));
                itemMetadata.setPoints(Integer.toString(sAppMetadata
                        .getMaximumNumberOfPoints()));
                itemMetadata.setInteractionType(sAppMetadata
                        .getInteractionType());

                if(sAppMetadata != null && CollectionUtils.isNotEmpty(sAppMetadata.getStandardPublication())) {
                	itemMetadata.setPrimaryStandard(sAppMetadata
                        .getStandardPublication().get(0).getPrimaryStandard());
                	
                	List<String> secondaryStandardList = new ArrayList<String>();
                    int spCount = 0;
                    for (StandardPublication sp : sAppMetadata.getStandardPublication()) {
                    	if (spCount > 0) {
                    		secondaryStandardList.add(sp.getPrimaryStandard());
                    	}
                    	if (!sp.getSecondaryStandard().isEmpty()) {
                    		for (int j = 0; j < sp.getSecondaryStandard().size(); j++) {
                    			secondaryStandardList.add(sp.getSecondaryStandard().get(j));
    						}                                                		
                    	}
                    	spCount++;
    				}
                    
                    itemMetadata.setSecondaryStandards(secondaryStandardList);
                }
            }
        } else if (resource != null
                && IMSItemUtil.isSBACMetadataExists(outputZipFolder, resource)) {
            APIPMetadata apipMetadata = IMSManifestReader.readAPIPMetadata(
                    outputZipFolder, resource, resourceMap);
            itemMetadata.setDifficulty(StringUtils.isNotBlank(apipMetadata
                    .getDifficulty()) ? apipMetadata.getDifficulty()
                    : IMSPackageConstants.DEFAULT_DIFFICULTY);
            itemMetadata.setIdentifier(apipMetadata.getSystemId());
            itemMetadata
                    .setPublicationStatus(IMSPackageConstants.DEFAULT_PUBLICATION_STATUS);
            itemMetadata.setLanguage(IMSPackageConstants.DEFAULT_LANG);
            itemMetadata.setDescription("");
            itemMetadata.setTitle("");
            itemMetadata
                    .setDepthOfKnowledge(apipMetadata.getDepthOfKnowledge());
            itemMetadata.setGradeStart(apipMetadata.getMinimumGrade());
            itemMetadata.setGradeEnd(apipMetadata.getMaxmimumGrade());
            itemMetadata.setSubject(apipMetadata.getSystemSubject());
            itemMetadata.setGrade(apipMetadata.getSystemGrade());
            itemMetadata.setPoints(apipMetadata.getPoint());
            itemMetadata.setInteractionType(apipMetadata.getSystemItemType());
        } else if (resource != null
                && resource.getMetadata() != null
                && resource.getMetadata().getLom() != null
                && CollectionUtils.isNotEmpty(resource.getMetadata().getLom()
                        .getGeneralsAndLifeCyclesAndMetaMetadatas())) {
            for (Object metadata : resource.getMetadata().getLom()
                    .getGeneralsAndLifeCyclesAndMetaMetadatas()) {
                if (metadata instanceof GeneralType
                        && CollectionUtils.isNotEmpty(((GeneralType) metadata)
                                .getIdentifiersAndTitlesAndLanguages())) {
                    readGeneralType(metadata, itemMetadata);
                } else if (metadata instanceof EducationalType
                        && CollectionUtils
                                .isNotEmpty(((EducationalType) metadata)
                                        .getInteractivityTypesAndLearningResourceTypesAndInteractivityLevels())) {
                    readEducationType(metadata, itemMetadata);
                } else if (metadata instanceof QtiMetadata
                        && CollectionUtils.isNotEmpty(((QtiMetadata) metadata)
                                .getInteractionTypes())) {
                    itemMetadata.setInteractionType(((QtiMetadata) metadata)
                            .getInteractionTypes().get(0));
                }
            }
        }
        return itemMetadata;
    }

    public static void readEducationType(Object metadata,
            IMSMetadata itemMetadata) {
        for (JAXBElement<?> element : ((EducationalType) metadata)
                .getInteractivityTypesAndLearningResourceTypesAndInteractivityLevels()) {
            if (StringUtils.equalsIgnoreCase(element.getName().getLocalPart(),
                    EDUCATION_DIFFICULTY) && element.getValue() instanceof DifficultyType
                    && CollectionUtils.isNotEmpty(((DifficultyType) element
                            .getValue()).getSourcesAndValues())) {
            	
                
                    for (JAXBElement<String> value : ((DifficultyType) element
                            .getValue()).getSourcesAndValues()) {
                        if (StringUtils.equalsIgnoreCase(value.getName()
                                .getLocalPart(), EDUCATION_DIFFICULTY_VALUE)) {
                            itemMetadata.setDifficulty(value.getValue());
                        }
                    }
                
            }
        }
    }

    public static void readGeneralType(Object metadata, IMSMetadata itemMetadata) {
        for (JAXBElement<?> element : ((GeneralType) metadata)
                .getIdentifiersAndTitlesAndLanguages()) {
            if (StringUtils.equalsIgnoreCase(element.getName().getLocalPart(),
                    GENERAL_DESCRIPTION)) {
                if (element.getValue() instanceof LangStringType
                        && CollectionUtils.isNotEmpty(((LangStringType) element
                                .getValue()).getStrings())) {
                    LanguageStringType stringType = ((LangStringType) element
                            .getValue()).getStrings().get(0);
                    itemMetadata.setDescription(stringType.getValue());
                }
            } else if (StringUtils.equalsIgnoreCase(element.getName()
                    .getLocalPart(), GENERAL_TITLE)) {
                if (element.getValue() instanceof LangStringType
                        && CollectionUtils.isNotEmpty(((LangStringType) element
                                .getValue()).getStrings())) {
                    LanguageStringType stringType = ((LangStringType) element
                            .getValue()).getStrings().get(0);
                    itemMetadata.setTitle(stringType.getValue());

                }
            } else if (StringUtils.equalsIgnoreCase(element.getName()
                    .getLocalPart(), GENERAL_ID) && element.getValue() instanceof IdentifierType
                    && CollectionUtils.isNotEmpty(((IdentifierType) element
                            .getValue()).getCatalogsAndEntries())) {
              
                    for (JAXBElement<String> value : ((IdentifierType) element
                            .getValue()).getCatalogsAndEntries()) {
                        if (StringUtils.equalsIgnoreCase(value.getName()
                                .getLocalPart(), GENERAL_ID_ENTRY)) {
                            itemMetadata.setIdentifier(value.getValue());
                        }
                    }
               
            }
        }
    }

    public static AssessmentItem readItem(String filePath) {
        AssessmentItem item = null;
        try {
            LOGGER.info("Reading item xml content from file " + filePath);
            String xmlContent = FileUtil
                    .readXMLFileWithoutDeclaration(new File(filePath));
            LOGGER.info("Unmershalling item xml content from file " + filePath);
            item = JAXBUtil.<AssessmentItem> unmershall(xmlContent,
                    AssessmentItem.class, ObjectFactory.class);
            LOGGER.info("Unmershaled item xml content from file " + filePath);
        } catch (Exception e) {
            LOGGER.error("Unable to unmershall item xml from file " + filePath
                    + " " + e.getMessage(), e);
        }
        return item;
    }

    public static String getMetadata(String outputZipFolder,
            ResourceType resource, Map<String, ResourceType> resourceMap) {
        String metadata = null;
        try {
            if (resource.getMetadata() != null) {
                metadata = JAXBUtil.mershall(resource.getMetadata(),
                        ResourceMetadataType.class);
            } else if (IMSItemUtil.isAPIPMetadataExists(outputZipFolder,
                    resource)
                    || IMSItemUtil.isSBACMetadataExists(outputZipFolder,
                            resource)) {
                metadata = IMSManifestReader.readMetadataContent(
                        outputZipFolder, resource, resourceMap);
            }
        } catch (Exception e) {
            LOGGER.error("Unable to mershall item metadata " + e.getMessage(),
                    e);
        }
        return metadata;
    }

    public static String saveItemAssets(File sourceFile, int itemBankId,
            String identifier) {
        String assetDir = IMSItemUtil.getItemImageDirPath(itemBankId,
                identifier);
        if (sourceFile.exists()) {
            try {
                String assetFilePostfix = ASSETDATEFORMAT.format(new Date());
                String destinationFileName = identifier + "_"
                        + assetFilePostfix + "."
                        + sourceFile.getName().split("\\.")[1];
                File destinationFile = new File(assetDir + File.separator
                        + destinationFileName);
                FileUtils.copyFile(sourceFile, destinationFile);
                LOGGER.info("File copied to path "
                        + destinationFile.getCanonicalPath());
                return destinationFile.getName();
            } catch (IOException e) {
                LOGGER.error("Error in saving item asset from path "
                        + sourceFile.getAbsolutePath() + " " + e.getMessage(),
                        e);
            } catch (Exception e) {
                LOGGER.error("Error in saving item asset from path "
                        + sourceFile.getAbsolutePath() + " " + e.getMessage(),
                        e);
            }
        }
        return null;
    }

    public static String saveItemAttachment(File sourceFile, int itemBankId,
            String identifier) {
        String attachmentDir = IMSItemUtil.getItemAttachmentDirPath(itemBankId,
                identifier);
        if (sourceFile.exists()) {
            try {
                File destinationFile = new File(attachmentDir + File.separator
                        + sourceFile.getName());
                FileUtils.copyFile(sourceFile, destinationFile);
                LOGGER.info("File copied to path "
                        + destinationFile.getCanonicalPath());
                return destinationFile.getAbsolutePath();
            } catch (IOException e) {
                LOGGER.error("Error in saving item asset from path "
                        + sourceFile.getAbsolutePath() + " " + e.getMessage(),
                        e);
            } catch (Exception e) {
                LOGGER.error("Error in saving item asset from path "
                        + sourceFile.getAbsolutePath() + " " + e.getMessage(),
                        e);
            }
        }
        return null;
    }

    public static String getHref(ResourceType resource) {
        if (resource != null && StringUtils.isNotEmpty(resource.getHref())) {
            return resource.getHref();
        } else if (CollectionUtils.isNotEmpty(resource.getFiles())) {
            return resource.getFiles().get(0).getHref();
        }
        return null;
    }
}
