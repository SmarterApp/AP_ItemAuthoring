/**
 * 
 */
package com.pacificmetrics.orca.packaging.qti;

import static org.junit.Assert.*;

import javax.xml.parsers.ParserConfigurationException;

import org.junit.Test;
import org.xml.sax.SAXException;

import com.pacificmetrics.orca.export.apip.APIPItemParser;

/**
 * @author maumock
 *
 */
@SuppressWarnings("static-method")
public class APIPItemParserTest {
  
    
    @SuppressWarnings("unused")
    @Test
    public final void constructorTests() throws ParserConfigurationException, SAXException{
        new APIPItemParser();
        new APIPItemParser(true);
    }
    
//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#getAPIPItem(com.pacificmetrics.orca.entities.Item)}.
//     */

//
//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#getResources()}.
//     */

//
//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#getInteractionTypes()}.

//
//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#getToolVersion()}.
//     */

//
//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#getToolName()}.
//     */

//
//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#getToolVendor()}.
//     */

//
//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#isTimeDependent()}.
//     */

//

//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#isSolutionAvailable()}.
//     */

//
//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#isComposite()}.
//     */


}
