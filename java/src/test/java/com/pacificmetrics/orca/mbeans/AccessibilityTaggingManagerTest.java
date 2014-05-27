package com.pacificmetrics.orca.mbeans;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNotSame;
import static org.junit.Assert.assertTrue;

import java.util.ArrayList;
import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import org.junit.Assert;
import org.junit.Test;
import org.unitils.UnitilsJUnit4;
import org.unitils.dbunit.annotation.DataSet;
import org.unitils.inject.annotation.TestedObject;
import org.unitils.mock.Mock;
import org.unitils.mock.annotation.AfterCreateMock;
import org.unitils.orm.jpa.JpaUnitils;
import org.unitils.orm.jpa.annotation.JpaEntityManagerFactory;

import com.pacificmetrics.common.web.ManagerException;
import com.pacificmetrics.orca.ejb.AccessibilityItemServices;
import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.entities.AccessibilityElement;
import com.pacificmetrics.orca.entities.AccessibilityFeature;
import com.pacificmetrics.orca.entities.InclusionOrder;
import com.pacificmetrics.orca.entities.InclusionOrderElement;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.test.InjectIntoByTypeExt;
import com.pacificmetrics.orca.test.TestParameter;
import com.pacificmetrics.orca.test.TestedManager;


@DataSet({"AccessibilityTaggingManagerTest.xml"})
@JpaEntityManagerFactory(persistenceUnit = "test-cde-unit", configFile = "META-INF/persistence-test.xml")
public class AccessibilityTaggingManagerTest extends UnitilsJUnit4 {
    
    @TestedObject
    @TestedManager
    @TestParameter(name="item", value="123") 
    AccessibilityTaggingManager accessibility;
    
    @TestedObject
    @TestedManager
    @TestParameter(name="item", value="321") 
    AccessibilityTaggingManager accessibility321;
    
    @InjectIntoByTypeExt(target={"accessibility", "accessibility321"})
    Mock<ItemServices> mockItemServices;
    
    @InjectIntoByTypeExt(target={"accessibility", "accessibility321"})
    @TestedObject
    AccessibilityItemServices accessibilityItemServices;

    @InjectIntoByTypeExt(target={"accessibilityItemServices"})
    @PersistenceContext
    EntityManager entityManager;
    
    @AfterCreateMock
    void initMock(Object mock, String name, Class<?> type) {
        {
            Item item = new Item();
            item.setId(123);
            mockItemServices.returns(item).findItemById(123);
            mockItemServices.returns(item).findItemWithInteractionsById(123);
            mockItemServices.returns("<html><body></body></html>").getItemAsHTML(null);
            mockItemServices.returns("<html><body></body></html>").getItemAsHTML_2(null);
        }
        {
            Item item = new Item();
            item.setId(321);
            mockItemServices.returns(item).findItemById(321);
            mockItemServices.returns(item).findItemWithInteractionsById(321);
            mockItemServices.returns("<html><body></body></html>").getItemAsHTML(null);
            mockItemServices.returns("<html><body></body></html>").getItemAsHTML_2(null);
        }
    }
    
    @Test
    public void testParameter() {
        assertEquals("123", accessibility.getParameter("item"));
    }
    
    @Test
    public void testAddNewElements() throws ManagerException {
        accessibility.load();
        assertNotSame(0, accessibility.getItemOrPassageHTML().length());
        assertNotNull(accessibility.getTagsJSON());
        assertEquals("[{\"id\":\"cde_11\",\"elementId\":\"ae001\",\"tagName\":\"OBJECT\",\"featureCount\":2}]", accessibility.getTagsJSON());
        String newJSON = "[{\"id\":\"cde_11\",\"elementId\":\"ae001\",\"tagName\":\"OBJECT\",\"featureCount\":2}," + 
                         "{\"id\":\"cde_12\",\"elementId\":\"ae002\",\"tagName\":\"OBJECT\",\"featureCount\":0}," + 
                         "{\"id\":\"cde_13\",\"elementId\":\"ae003\",\"tagName\":\"OBJECT\",\"featureCount\":0}]";
        accessibility.setTagsJSON(newJSON);
        accessibility.doSave();
        assertEquals(newJSON, accessibility.getTagsJSON());
    }

    @Test
    public void testModifyElements() throws ManagerException {
        accessibility.load();
        assertEquals("[{\"id\":\"cde_11\",\"elementId\":\"ae001\",\"tagName\":\"OBJECT\",\"featureCount\":2}]", accessibility.getTagsJSON());
        String modifiedJSON = "[{\"id\":\"cde_22\",\"elementId\":\"ae001\",\"tagName\":\"OBJECT\",\"featureCount\":2,\"modified\":true}]";
        accessibility.setTagsJSON(modifiedJSON);
        accessibility.doSave();
        String newJSON = "[{\"id\":\"cde_22\",\"elementId\":\"ae001\",\"tagName\":\"OBJECT\",\"featureCount\":2}]";
        assertEquals(newJSON, accessibility.getTagsJSON());
    }

    @Test
    public void testRemoveElement() throws ManagerException {
        accessibility.load();
        assertNotSame(0, accessibility.getItemOrPassageHTML().length());
        assertNotNull(accessibility.getTagsJSON());
        assertEquals("[{\"id\":\"cde_11\",\"elementId\":\"ae001\",\"tagName\":\"OBJECT\",\"featureCount\":2}]", accessibility.getTagsJSON());
        String newJSON = "[]";
        accessibility.setTagsJSON(newJSON);
        accessibility.doSave();
        assertEquals(newJSON, accessibility.getTagsJSON());
    }

    @Test
    public void testAddFeature() throws ManagerException {
        accessibility.load();
        assertEquals("[{\"id\":\"cde_11\",\"elementId\":\"ae001\",\"tagName\":\"OBJECT\",\"featureCount\":2}]", accessibility.getTagsJSON());
        //On 'Define Tags' tab select first tag
        accessibility.setSelectedElementId("ae001");
        accessibility.doRefresh();
        assertEquals(2, accessibility.getFeatureListForSelectedElement().size());
        //Click 'Add New Feature'
        accessibility.addNewFeature();
        //Select Feature Type
        accessibility.setSelectedFeatureType(AccessibilityFeature.T_SPOKEN);
        accessibility.featureTypeSelected(null);
        //Make sure Features drop down is populated properly
        String feature = AccessibilityFeature.getFeatureAsString(AccessibilityFeature.F_TEXT_TO_SPEECH);
        assertEquals(AccessibilityFeature.F_TEXT_TO_SPEECH, (int)accessibility.getFeaturesForTypeMap().get(feature));
        //Select Feature and enter info. Click Save
        accessibility.setSelectedFeature(AccessibilityFeature.F_AUDIO_TEXT);
        accessibility.setFeatureInfo("Some Info");
        accessibility.saveFeature();
        //Click Save Changes (need to clear persistence context first)
        entityManager.clear();
        accessibility.doSaveFeatures();
        //Make sure there are now 3 features associated with 1st element
        accessibility.setSelectedElementId("ae001");
        accessibility.doRefresh();
        assertEquals(3, accessibility.getFeatureListForSelectedElement().size());
    }
    
    @Test
    public void testModifyFeature() throws ManagerException {
        accessibility.load();
        assertEquals("[{\"id\":\"cde_11\",\"elementId\":\"ae001\",\"tagName\":\"OBJECT\",\"featureCount\":2}]", accessibility.getTagsJSON());
        //On 'Define Tags' tab select first tag
        accessibility.setSelectedElementId("ae001");
        accessibility.doRefresh();
        assertEquals(2, accessibility.getFeatureListForSelectedElement().size());
        //Select 'Modify'
        AccessibilityFeature af = accessibility.getFeatureListForSelectedElement().get(0);
        accessibility.modifyFeature(af);
        accessibility.setSelectedFeatureType(AccessibilityFeature.T_SPOKEN);
        accessibility.featureTypeSelected(null);
        accessibility.setSelectedFeature(AccessibilityFeature.F_TEXT_TO_SPEECH);
        accessibility.setFeatureInfo("Modified Info");
        accessibility.saveFeature();
        //Click Save Changes (need to clear persistence context first)
        entityManager.clear();
        accessibility.doSaveFeatures();
        JpaUnitils.flushDatabaseUpdates();
        //Make sure feature is updated
        entityManager.clear();
        accessibility.load();
        accessibility.setSelectedElementId("ae001");
        accessibility.doRefresh();
        List<AccessibilityFeature> list = accessibility.getFeatureListForSelectedElement();
        for (int i = 0; i < list.size(); i++) {
            af = list.get(i);
            if (af.getInfo().equals("Modified Info")) {
                assertEquals(AccessibilityFeature.T_SPOKEN, af.getType());
                assertEquals(AccessibilityFeature.F_TEXT_TO_SPEECH, af.getFeature());
                return;
            }
        }
        Assert.fail("Modified feature not found");
    }
    
    @Test
    public void testRemoveFeature() throws ManagerException {
        accessibility.load();
        assertEquals("[{\"id\":\"cde_11\",\"elementId\":\"ae001\",\"tagName\":\"OBJECT\",\"featureCount\":2}]", accessibility.getTagsJSON());
        //On 'Define Tags' tab select first tag
        accessibility.setSelectedElementId("ae001");
        accessibility.doRefresh();
        assertEquals(2, accessibility.getFeatureListForSelectedElement().size());
        //Click 'Remove' button on Feature #1
        accessibility.deleteFeature(accessibility.getFeatureListForSelectedElement().get(1));
        //Click Save Changes (need to clear persistence context first)
        entityManager.clear();
        accessibility.doSaveFeatures();
        //Make sure there is now only 1 feature associated with 1st element
        accessibility.setSelectedElementId("ae001");
        accessibility.doRefresh();
        assertEquals(1, accessibility.getFeatureListForSelectedElement().size());
        //Click 'Remove' on the sole feature
        accessibility.deleteFeature(accessibility.getFeatureListForSelectedElement().get(0));
        entityManager.clear();
        accessibility.doSaveFeatures();
        //Make sure there are no features associated with 1st element
        accessibility.setSelectedElementId("ae001");
        accessibility.doRefresh();
        assertEquals(0, accessibility.getFeatureListForSelectedElement().size());
    }
    
    @Test
    public void testAddInclusionOrder() throws ManagerException {
        accessibility321.load();
        accessibility321.setSelectedInclusionOrderType(InclusionOrder.T_TEXT_GRAPHICS_DEFAULT);
        accessibility321.setSelectedElementId("ae001");
        accessibility321.addTagToInclusionOrder();
        accessibility321.setSelectedElementId("ae002");
        accessibility321.addTagToInclusionOrder();
        accessibility321.doSaveInclusionOrder();
        List<InclusionOrder> list = accessibilityItemServices.findInclusionOrders(321);
        for (InclusionOrder io: list) {
            if (io.getType() == InclusionOrder.T_TEXT_GRAPHICS_DEFAULT) {
                assertEquals(InclusionOrder.T_TEXT_GRAPHICS_DEFAULT, io.getType());
                assertEquals(2, io.getElementList().size());
                return;
            }
        }
        Assert.fail("Not found added inclusion order");
    }
    
    @Test
    public void testAddAllTagsToInclusionOrder() throws ManagerException {
        accessibility321.load();
        accessibility321.setSelectedInclusionOrderType(InclusionOrder.T_TEXT_GRAPHICS_DEFAULT);
        accessibility321.addAllTagsToInclusionOrder();
        accessibility321.doSaveInclusionOrder();
        List<InclusionOrder> list = accessibilityItemServices.findInclusionOrders(321);
        for (InclusionOrder io: list) {
            if (io.getType() == InclusionOrder.T_TEXT_GRAPHICS_DEFAULT) {
                assertEquals(InclusionOrder.T_TEXT_GRAPHICS_DEFAULT, io.getType());
                assertEquals(2, io.getElementList().size());
                return;
            }
        }
        Assert.fail("Not found added inclusion order");
    }
    
    @Test
    public void testRemoveInclusionOrder() throws ManagerException {
        accessibility321.load();
        accessibility321.setSelectedInclusionOrderType(2);
        List<AccessibilityElement> ioeList = accessibility321.getInclusionOrderElements();
        assertEquals(2, ioeList.size());
        List<Integer> inclusionOrderTagsSelected = new ArrayList<Integer>();
        inclusionOrderTagsSelected.add(2);
        inclusionOrderTagsSelected.add(3);
        accessibility321.setInclusionOrderTagsSelected(inclusionOrderTagsSelected);
        accessibility321.deleteTagFromInclusionOrder();
        accessibility321.doSaveInclusionOrder();
        List<InclusionOrder> ioList = accessibilityItemServices.findInclusionOrders(321);
        for (InclusionOrder io: ioList) {
            if (io.getType() == 2) {
                Assert.fail("Delete failed");
            }
        }
    }
    
    @Test
    public void testModifyInclusionOrder() throws ManagerException {
        accessibility321.load();
        accessibility321.setSelectedInclusionOrderType(2);
        List<AccessibilityElement> ioeList = accessibility321.getInclusionOrderElements();
        assertEquals(2, ioeList.size());
        List<Integer> inclusionOrderTagsSelected = new ArrayList<Integer>();
        inclusionOrderTagsSelected.add(3);
        accessibility321.setInclusionOrderTagsSelected(inclusionOrderTagsSelected);
        accessibility321.moveInclusionOrderTagsUp();
        accessibility321.doSaveInclusionOrder();
        List<InclusionOrder> ioList = accessibilityItemServices.findInclusionOrders(321);
        int count = 0;
        for (InclusionOrder io: ioList) {
            if (io.getType() == 2) {
                for (InclusionOrderElement ioe: io.getElementList()) {
                    if (ioe.getAccessibilityElementId() == 3) {
                        assertTrue(ioe.getSequence() == 1);
                        count++;
                    }
                    if (ioe.getAccessibilityElementId() == 2) {
                        assertTrue(ioe.getSequence() == 2);
                        count++;
                    }
                }
            }
        }
        assertEquals("Inclusion order elements count", 2, count);
    }
    
}
