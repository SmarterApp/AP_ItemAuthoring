package com.pacificmetrics.orca.ejb;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNotSame;
import static org.junit.Assert.assertNull;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import org.junit.Test;
import org.unitils.UnitilsJUnit4;
import org.unitils.dbunit.annotation.DataSet;
import org.unitils.inject.annotation.TestedObject;
import org.unitils.orm.jpa.JpaUnitils;
import org.unitils.orm.jpa.annotation.JpaEntityManagerFactory;

import com.pacificmetrics.common.ServiceException;
import com.pacificmetrics.orca.entities.AccessibilityElement;
import com.pacificmetrics.orca.entities.AccessibilityFeature;
import com.pacificmetrics.orca.entities.InclusionOrder;
import com.pacificmetrics.orca.test.InjectIntoByTypeExt;

@DataSet("AccessibilityPassageServicesTest.xml")
@JpaEntityManagerFactory(persistenceUnit = "test-cde-unit", configFile = "META-INF/persistence-test.xml")
public class AccessibilityPassageServicesTest extends UnitilsJUnit4 {
    
    
    @TestedObject
    AccessibilityPassageServices accessibilityPassageServices;
    
    @InjectIntoByTypeExt
    @PersistenceContext
    EntityManager entityManager;
    
    @Test
    public void testNoData() {
        assertNull(accessibilityPassageServices.findAccessibilityElementById(99));
        assertEquals(0, accessibilityPassageServices.findAccessibilityElements(55).size());
        assertNull(accessibilityPassageServices.findAccessibilityFeatureById(77));
        assertEquals(0, accessibilityPassageServices.findInclusionOrders(88).size());
    }
    
    @Test
    public void testFindAccessibilityElements() {
        assertEquals(2, accessibilityPassageServices.findAccessibilityElements(123).size());
        assertEquals(1, accessibilityPassageServices.findAccessibilityElements(321).size());
    }
    
    @Test 
    public void testFindInclusionOrders() {
        assertEquals(3, accessibilityPassageServices.findInclusionOrders(123).size());
    }

    @Test 
    public void testFindAccessibilityFeatureById() {
        {
            AccessibilityFeature af = accessibilityPassageServices.findAccessibilityFeatureById(1);
            assertNotNull(af);
            assertEquals(1, af.getElementId());
        }
        {
            AccessibilityFeature af = accessibilityPassageServices.findAccessibilityFeatureById(3);
            assertNotNull(af);
            assertEquals(2, af.getElementId());
        }
    }
    
    @Test
    public void testFeatureNew() throws ServiceException {
        AccessibilityFeature af = accessibilityPassageServices.insertFeature(0, 1, AccessibilityFeature.T_SPOKEN, AccessibilityFeature.F_AUDIO_FILE, null, "Some info");
        assertNotNull(af);
        assertEquals(4, af.getId());
        assertEquals(AccessibilityFeature.F_AUDIO_FILE, af.getFeature());
        AccessibilityElement ae = accessibilityPassageServices.findAccessibilityElementById(1);
        assertNotNull(ae);
        assertEquals(3, ae.getFeatureList().size());
    }
    
    @Test 
    public void deleteAccessibilityFeature() throws ServiceException {
        accessibilityPassageServices.deleteAccessibilityFeature(1);
        assertNull(accessibilityPassageServices.findAccessibilityFeatureById(1));
        accessibilityPassageServices.deleteAccessibilityFeature(2);
        //
        accessibilityPassageServices.entityManager.flush();
        AccessibilityElement ae = accessibilityPassageServices.findAccessibilityElementById(1);
        assertEquals(0, ae.getFeatureList().size());
    }
    
    @Test 
    public void testPersistInclusionOrders() {
        List<InclusionOrder> list = new ArrayList<InclusionOrder>();
        for (int i = 0; i < 5; i++) {
            InclusionOrder inclusionOrder = new InclusionOrder();
            inclusionOrder.setPassageId(321);
            list.add(inclusionOrder);
        }
        assertEquals(1, accessibilityPassageServices.findInclusionOrders(321).size());
        accessibilityPassageServices.persistInclusionOrders(list);
        assertEquals(6, accessibilityPassageServices.findInclusionOrders(321).size());
    }
    
    @Test
    public void testDeleteInclusionOrders() {
        assertEquals(3, accessibilityPassageServices.findInclusionOrders(123).size());
        accessibilityPassageServices.deleteInclusionOrders(123);
        assertEquals(0, accessibilityPassageServices.findInclusionOrders(123).size());
    }
    
    @Test
    public void testReplaceInclusionOrders() {
        List<InclusionOrder> list = new ArrayList<InclusionOrder>();
        for (int i = 0; i < 7; i++) {
            InclusionOrder inclusionOrder = new InclusionOrder();
            inclusionOrder.setPassageId(123);
            list.add(inclusionOrder);
        }
        assertEquals(3, accessibilityPassageServices.findInclusionOrders(123).size());
        accessibilityPassageServices.replaceInclusionOrders(123, list);
        assertEquals(7, accessibilityPassageServices.findInclusionOrders(123).size());
    }
    
    @Test
    public void testDeleteAccessibilityElements() {
        assertEquals(2, accessibilityPassageServices.findAccessibilityElements(123).size());
        accessibilityPassageServices.deleteAccessibilityElements(123, Collections.singletonList("ae002"));
        List<AccessibilityElement> list = accessibilityPassageServices.findAccessibilityElements(123);
        assertEquals(1, list.size());
        assertEquals("ae002", list.get(0).getName());
    }
    
    @Test
    public void testDeleteAccessibilityElementsNoRetain() {
        assertEquals(2, accessibilityPassageServices.findAccessibilityElements(123).size());
        accessibilityPassageServices.deleteAccessibilityElements(123, null);
        List<AccessibilityElement> list = accessibilityPassageServices.findAccessibilityElements(123);
        assertEquals(0, list.size());
    }
    
    @Test
    public void testGetFeaturesForType() {
        //assertEquals(AccessibilityFeature.F_TEXT_TO_SPEECH, (int)accessibilityPassageServices.getFeaturesForType(AccessibilityFeature.T_SPOKEN).get(2));
        //commented out for DE1054
    }
    
    @Test
    public void testDeleteAccessibilityFeaturesNotInList() {
        AccessibilityElement ae = accessibilityPassageServices.findAccessibilityElementById(1);
        assertEquals(2, ae.getFeatureList().size());
        accessibilityPassageServices.deleteAccessibilityFeaturesForElement(1);
        entityManager.refresh(ae);
        assertEquals(0, ae.getFeatureList().size());
    }
    
    @Test
    public void testReplaceAccessibilityFeatures() {
        Map<Integer, List<AccessibilityFeature>> featuresMap = new HashMap<Integer, List<AccessibilityFeature>>();
        {
            List<AccessibilityFeature> features = new ArrayList<AccessibilityFeature>();
            for (int i = 0; i < 3; i++) {
                AccessibilityFeature af = new AccessibilityFeature();
                af.setElementId(1);
                features.add(af);
            }
            featuresMap.put(1, features);
        }
        {
            List<AccessibilityFeature> features = new ArrayList<AccessibilityFeature>();
            for (int i = 0; i < 4; i++) {
                AccessibilityFeature af = new AccessibilityFeature();
                af.setElementId(2);
                features.add(af);
            }
            featuresMap.put(2, features);
        }
        accessibilityPassageServices.replaceAccessibilityFeatures(featuresMap);
        JpaUnitils.flushDatabaseUpdates();
        assertEquals(3, accessibilityPassageServices.findAccessibilityElementById(1).getFeatureList().size());
        assertEquals(4, accessibilityPassageServices.findAccessibilityElementById(2).getFeatureList().size());
    }
    
    @Test 
    public void testReplaceAccessibilityElements() {
        List<AccessibilityElement> elements = accessibilityPassageServices.findAccessibilityElements(123);
        assertEquals(2, elements.size());
        List<AccessibilityElement> newElements = new ArrayList<AccessibilityElement>();
        newElements.add(elements.get(0));
        {
            AccessibilityElement ae = new AccessibilityElement();
            ae.setPassageId(123);
            ae.setName("ae009");
            newElements.add(ae);
        }
        {
            AccessibilityElement ae = new AccessibilityElement();
            ae.setPassageId(123);
            ae.setName("ae010");
            newElements.add(ae);
        }
        accessibilityPassageServices.replaceAccessibilityElements(123, newElements);
        assertEquals(3, accessibilityPassageServices.findAccessibilityElements(123).size());
    }

    @Test 
    public void testReplaceModifyAccessibilityElements() {
        List<AccessibilityElement> elements = accessibilityPassageServices.findAccessibilityElements(123);
        assertEquals(2, elements.size());
        accessibilityPassageServices.entityManager.clear();
        elements.get(0).setContentName("new0");
        elements.get(1).setContentName("new1");
        List<String> modifiedElements = new ArrayList<String>();
        modifiedElements.add(elements.get(1).getName());
        accessibilityPassageServices.replaceAccessibilityElements(123, elements, modifiedElements);
        accessibilityPassageServices.entityManager.flush();
        accessibilityPassageServices.entityManager.clear();
        List<AccessibilityElement> newElements = accessibilityPassageServices.findAccessibilityElements(123);
        assertEquals("new1", newElements.get(1).getContentName());
        assertNotSame("new0", newElements.get(0).getContentName()); //only one element should have been modified; verifying that 
    }

}
