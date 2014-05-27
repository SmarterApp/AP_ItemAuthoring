/**
 * 
 */
package com.pacificmetrics.orca.packaging.qti;

import static org.junit.Assert.assertEquals;

import java.io.File;
import java.io.IOException;
import java.net.URISyntaxException;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.xpath.XPathExpressionException;

import org.junit.Test;
import org.xml.sax.SAXException;

import com.pacificmetrics.orca.utils.XMLUtil;

/**
 * @author maumock
 * 
 */
public class XMLReaderTest {

    @Test
    public void readFile() throws XPathExpressionException, ParserConfigurationException, SAXException, IOException, URISyntaxException {
        XMLUtil reader = new XMLUtil();
        File xmlFile = new File(getClass().getResource("/apipPkgs/apipv1p0_EntryTest_VE_TP_06/Items/Item_VE_IP_02/apipv1p0_EntryTest_VE_IP_02.xml").toURI());
        reader.load(xmlFile);
        reader.addXPathNS("", "http://www.imsglobal.org/xsd/apip/apipv1p0/qtiitem/imsqti_v2p1");
        String[] values = reader.getValues("//:img");
        assertEquals(1,values.length);
    }
}
