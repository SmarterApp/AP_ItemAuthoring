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
    //private static final APIPItemParser p=new APIPItemParser();
    
    @SuppressWarnings("unused")
    @Test
    public final void constructorTests() throws ParserConfigurationException, SAXException{
        new APIPItemParser();
        new APIPItemParser(true);
    }
    
//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#getAPIPItem(com.pacificmetrics.orca.entities.Item)}.
//     */
//    @Test
//    public final void testGetAPIPItem() {
//        fail("Not yet implemented"); // TODO
//    }
//
//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#getResources()}.
//     */
//    @Test
//    public final void testGetResources() {
//        fail("Not yet implemented"); // TODO
//    }
//
//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#getInteractionTypes()}.
//     */
//    @Test
//    public final void testGetInteractionTypes() {
//        fail("Not yet implemented"); // TODO
//    }
//
//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#getToolVersion()}.
//     */
//    @Test
//    public final void testGetToolVersion() {
//        fail("Not yet implemented"); // TODO
//    }
//
//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#getToolName()}.
//     */
//    @Test
//    public final void testGetToolName() {
//        fail("Not yet implemented"); // TODO
//    }
//
//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#getToolVendor()}.
//     */
//    @Test
//    public final void testGetToolVendor() {
//        fail("Not yet implemented"); // TODO
//    }
//
//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#isTimeDependent()}.
//     */
//    @Test
//    public final void testIsTimeDependent() {
//        fail("Not yet implemented"); // TODO
//    }
//
//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#getFeedbackType()}.
//     */
//    @Test
//    public final void testGetFeedbackType() {
//        fail("Not yet implemented"); // TODO
//    }
//
//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#isSolutionAvailable()}.
//     */
//    @Test
//    public final void testIsSolutionAvailable() {
//        fail("Not yet implemented"); // TODO
//    }
//
//    /**
//     * Test method for {@link com.pacificmetrics.orca.export.apip.APIPItemParser#isComposite()}.
//     */
//    @Test
//    public final void testIsComposite() {
//        fail("Not yet implemented"); // TODO
//    }

}
