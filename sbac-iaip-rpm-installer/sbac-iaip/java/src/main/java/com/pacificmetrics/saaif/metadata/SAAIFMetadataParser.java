package com.pacificmetrics.saaif.metadata;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.xml.sax.SAXException;

import com.pacificmetrics.orca.utils.DomUtil;
import com.pacificmetrics.saaif.metadata.Metadata.SmarterAppMetadata;
import com.pacificmetrics.saaif.metadata.Metadata.SmarterAppMetadata.IrtDimension;
import com.pacificmetrics.saaif.metadata.Metadata.SmarterAppMetadata.StandardPublication;

public class SAAIFMetadataParser {

    private static final Log LOGGER = LogFactory
            .getLog(SAAIFMetadataParser.class);

    private SAAIFMetadataParser() {
    }

    public static Metadata parseMetdata(String xmlContent) {
        Metadata metadata = new Metadata();
        try {
            InputStream is = new ByteArrayInputStream(xmlContent.getBytes());
            final DocumentBuilderFactory docFactory = DocumentBuilderFactory
                    .newInstance();
            final DocumentBuilder docBuilder = docFactory.newDocumentBuilder();

            Document document = docBuilder.parse(is);

            Node metadataElement = document.getFirstChild();

            Node saMetadata = DomUtil.getNode("smarterAppMetadata",
                    metadataElement.getChildNodes());
            if (saMetadata != null) {
                SmarterAppMetadata smarterAppMetadata = buildSmarterAppMetdata(saMetadata);
                metadata.setSmarterAppMetadata(smarterAppMetadata);
            }

            List<Node> irsDimentions = DomUtil.getNodes("IrtDimension",
            		saMetadata.getChildNodes());
            if (CollectionUtils.isNotEmpty(irsDimentions)) {
                for (Node irsDimention : irsDimentions) {
                    metadata.getSmarterAppMetadata().getIrtDimension()
                            .add(buildIrtDimention(irsDimention));
                }
            }
            
            List<Node> standardPublications = DomUtil.getNodes("StandardPublication",
            		saMetadata.getChildNodes());
            if (CollectionUtils.isNotEmpty(standardPublications)) {
                for (Node standardPublication : standardPublications) {
                    metadata.getSmarterAppMetadata().getStandardPublication()
                            .add(buildStandardPublication(standardPublication));
                }
            }

        } catch (SAXException e) {
            LOGGER.error(
                    "Parser unable to parse metadata contnet " + e.getMessage(),
                    e);
        } catch (IOException e) {
            LOGGER.error("Unable to read metadata contnet " + e.getMessage(), e);
        } catch (ParserConfigurationException e) {
            LOGGER.error(
                    "Unable to configure parser for metadata contnet "
                            + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.error("Unable to parse metadata contnet " + e.getMessage(),
                    e);
        }

        return metadata;
    }

    public static SmarterAppMetadata buildSmarterAppMetdata(
            Node smarterAppElement) {

        SmarterAppMetadata smarterAppMetadata = new SmarterAppMetadata();
        smarterAppMetadata.setIdentifier(DomUtil.getNodeIntValue(
                MetadataFieldConstants.IDENTIFIER,
                smarterAppElement.getChildNodes()));
        smarterAppMetadata.setInteractionType(DomUtil.getNodeValue(
                MetadataFieldConstants.INTERACTIONTYPE,
                smarterAppElement.getChildNodes()));
        smarterAppMetadata.setEducationalDifficulty(DomUtil.getNodeValue(
                MetadataFieldConstants.EDUCATIONALDIFFICULTY,
                smarterAppElement.getChildNodes()));
        smarterAppMetadata.setVersion(DomUtil.getNodeIntValue(
                MetadataFieldConstants.VERSION,
                smarterAppElement.getChildNodes()));
        smarterAppMetadata.setSubject(DomUtil.getNodeValue(
                MetadataFieldConstants.SUBJECT,
                smarterAppElement.getChildNodes()));
        smarterAppMetadata.setSmarterAppItemDescriptor(DomUtil.getNodeValue(
                MetadataFieldConstants.ITEMDESCRIPTOR,
                smarterAppElement.getChildNodes()));

        smarterAppMetadata.setSecurityStatus(DomUtil.getNodeValue(
                MetadataFieldConstants.SECURITYSTATUS,
                smarterAppElement.getChildNodes()));
        smarterAppMetadata.setMinimumGrade(DomUtil.getNodeIntValue(
                MetadataFieldConstants.MINIMUMGRADE,
                smarterAppElement.getChildNodes()));
        smarterAppMetadata.setIntendedGrade(DomUtil.getNodeIntValue(
                MetadataFieldConstants.INTENDEDGRADE,
                smarterAppElement.getChildNodes()));
        smarterAppMetadata.setMaximumGrade(DomUtil.getNodeIntValue(
                MetadataFieldConstants.MAXIMUMGRADE,
                smarterAppElement.getChildNodes()));
        smarterAppMetadata.setDepthOfKnowledge(DomUtil.getNodeIntValue(
                MetadataFieldConstants.DEPTHOFKNOWLEDGE,
                smarterAppElement.getChildNodes()));
        smarterAppMetadata.setAdministrationDate(DomUtil.getNodeValue(
                MetadataFieldConstants.ADMINISTRATIONDATE,
                smarterAppElement.getChildNodes()));
        smarterAppMetadata.setMaximumNumberOfPoints(DomUtil.getNodeIntValue(
                MetadataFieldConstants.MAXNOOFPOINTS,
                smarterAppElement.getChildNodes()));

        smarterAppMetadata.setStimulusGenre(DomUtil.getNodeValue(
                MetadataFieldConstants.STIMULUSGENRE,
                smarterAppElement.getChildNodes()));
        smarterAppMetadata.setAlternateIdentifier(DomUtil.getNodeValue(
                MetadataFieldConstants.ALTERNATEIDENTIFIER,
                smarterAppElement.getChildNodes()));

        smarterAppMetadata.getLanguage().addAll(
                DomUtil.getNodeValues(MetadataFieldConstants.LANGUAGE,
                        smarterAppElement.getChildNodes()));
        smarterAppMetadata.getScorePoints().addAll(
                DomUtil.getNodeValues(MetadataFieldConstants.SCOREPOINTS,
                        smarterAppElement.getChildNodes()));
        smarterAppMetadata.getEvidenceStatement().addAll(
                DomUtil.getNodeValues(MetadataFieldConstants.EVIDENCESTATMENT,
                        smarterAppElement.getChildNodes()));

        smarterAppMetadata.setStimulusFormat(DomUtil.getNodeValue(
                MetadataFieldConstants.STIMULUSFORMAT,
                smarterAppElement.getChildNodes()));

        smarterAppMetadata.setItemSpecFormat(DomUtil.getNodeValue(
                MetadataFieldConstants.ITEMSPECFORMAT,
                smarterAppElement.getChildNodes()));

        smarterAppMetadata.setPresentationFormat(DomUtil.getNodeValue(
                MetadataFieldConstants.PRESENTATIONFORMAT,
                smarterAppElement.getChildNodes()));
        smarterAppMetadata.setStatus(DomUtil.getNodeValue(
                MetadataFieldConstants.STATUS,
                smarterAppElement.getChildNodes()));

        smarterAppMetadata.setPrimaryStandard(DomUtil.getNodeValue(
                MetadataFieldConstants.PRIMARYSTANDARD,
                smarterAppElement.getChildNodes()));
        smarterAppMetadata.getSecondaryStandard().addAll(
                DomUtil.getNodeValues(MetadataFieldConstants.SECONDARYSTANDARD,
                        smarterAppElement.getChildNodes()));

        return smarterAppMetadata;
    }

    public static StandardPublication buildStandardPublication(Node standardPublicationNode) {
    	StandardPublication standardPublication = new StandardPublication();
    	standardPublication.setPublication(DomUtil.getNodeValue(
    			StandardPublicationFieldConstants.PUBLICATION,
                standardPublicationNode.getChildNodes()));
    	standardPublication.setPrimaryStandard(DomUtil.getNodeValue(
    			StandardPublicationFieldConstants.PRIMARYSTANDARD,
                standardPublicationNode.getChildNodes()));
    	standardPublication.getSecondaryStandard().addAll(DomUtil.getNodeValues(
    			StandardPublicationFieldConstants.SECONDARYSTANDARD,
    			standardPublicationNode.getChildNodes()));       
        

        return standardPublication;
    }
    
    public static IrtDimension buildIrtDimention(Node irtDimensionNode) {
        IrtDimension irtDimension = new IrtDimension();
        irtDimension.setIrtScore(DomUtil.getNodeIntValue(
                IrtDimentionsFieldConstants.SCORE,
                irtDimensionNode.getChildNodes()));
        irtDimension.setIrtWeight(DomUtil.getNodeIntValue(
                IrtDimentionsFieldConstants.WEIGHT,
                irtDimensionNode.getChildNodes()));
        irtDimension.setIrtParam0(DomUtil.getNodeIntValue(
                IrtDimentionsFieldConstants.PARAM0,
                irtDimensionNode.getChildNodes()));
        irtDimension.setIrtParam1(DomUtil.getNodeIntValue(
                IrtDimentionsFieldConstants.PARAM1,
                irtDimensionNode.getChildNodes()));
        irtDimension.setIrtDimensionPurpose(DomUtil.getNodeValue(
                IrtDimentionsFieldConstants.PURPOSE,
                irtDimensionNode.getChildNodes()));
        irtDimension.setIrtModelType(DomUtil.getNodeValue(
                IrtDimentionsFieldConstants.MODELTYPE,
                irtDimensionNode.getChildNodes()));

        return irtDimension;
    }
}
