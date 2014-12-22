package com.pacificmetrics.orca.loader.ims;

import java.io.File;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.w3.synthesis.ObjectFactory;

import com.pacificmetrics.ims.qti.stimulus.AssessmentStimulus;
import com.pacificmetrics.orca.utils.FileUtil;
import com.pacificmetrics.orca.utils.JAXBUtil;

public class IMSPassageReader {

    private static final Log LOGGER = LogFactory.getLog(IMSPassageReader.class);

    private IMSPassageReader() {
    }

    public static AssessmentStimulus readPassage(String filePath) {
        AssessmentStimulus stimulus = null;
        try {
            LOGGER.info("Reading stimulus xml content from file " + filePath);
            String xmlContent = FileUtil
                    .readXMLFileWithoutDeclaration(new File(filePath));
            LOGGER.info("Unmershalling stimulus xml content from file "
                    + filePath);
            stimulus = JAXBUtil.unmershall(xmlContent,
                    AssessmentStimulus.class, ObjectFactory.class);
            LOGGER.info("Unmershaled stimulus xml content from file "
                    + filePath);
        } catch (Exception e) {
            LOGGER.error("Unable to unmershall stimulus xml from file "
                    + filePath + " " + e.getMessage(), e);
        }
        return stimulus;
    }

}
