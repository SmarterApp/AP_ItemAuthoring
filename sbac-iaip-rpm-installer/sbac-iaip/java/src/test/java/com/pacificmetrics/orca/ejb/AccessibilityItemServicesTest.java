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

@DataSet("AccessibilityItemServicesTest.xml")
@JpaEntityManagerFactory(persistenceUnit = "test-cde-unit", configFile = "META-INF/persistence-test.xml")
public class AccessibilityItemServicesTest extends UnitilsJUnit4 {

    @TestedObject
    AccessibilityItemServices accessibilityItemServices;

    @InjectIntoByTypeExt
    @PersistenceContext
    EntityManager entityManager;

    @Test
    public void testNoData() {
        assertNull(accessibilityItemServices.findAccessibilityElementById(99));
        assertEquals(0, accessibilityItemServices.findAccessibilityElements(55)
                .size());
        assertNull(accessibilityItemServices.findAccessibilityFeatureById(77));
        assertEquals(0, accessibilityItemServices.findInclusionOrders(88)
                .size());
    }

    @Test
    public void testFindAccessibilityElements() {
        assertEquals(2, accessibilityItemServices
                .findAccessibilityElements(123).size());
        assertEquals(1, accessibilityItemServices
                .findAccessibilityElements(321).size());
    }

    @Test
    public void testFindInclusionOrders() {
        assertEquals(3, accessibilityItemServices.findInclusionOrders(123)
                .size());
    }

    @Test
    public void testFindAccessibilityFeatureById() {
        AccessibilityFeature afOne = accessibilityItemServices
                .findAccessibilityFeatureById(1);
        assertNotNull(afOne);
        assertEquals(1, afOne.getElementId());

        AccessibilityFeature afTwo = accessibilityItemServices
                .findAccessibilityFeatureById(3);
        assertNotNull(afTwo);
        assertEquals(2, afTwo.getElementId());
    }

    @Test
    public void testFeatureNew() throws ServiceException {
        AccessibilityFeature af = accessibilityItemServices.insertFeature(0, 1,
                AccessibilityFeature.T_SPOKEN,
                AccessibilityFeature.F_AUDIO_FILE, null, "Some info");
        assertNotNull(af);
        assertEquals(4, af.getId());
        assertEquals(AccessibilityFeature.F_AUDIO_FILE, af.getFeature());
        AccessibilityElement ae = accessibilityItemServices
                .findAccessibilityElementById(1);
        assertNotNull(ae);
        assertEquals(3, ae.getFeatureList().size());
    }

    @Test
    public void deleteAccessibilityFeature() throws ServiceException {
        accessibilityItemServices.deleteAccessibilityFeature(1);
        assertNull(accessibilityItemServices.findAccessibilityFeatureById(1));
        accessibilityItemServices.deleteAccessibilityFeature(2);
        //
        accessibilityItemServices.entityManager.flush();
        AccessibilityElement ae = accessibilityItemServices
                .findAccessibilityElementById(1);
        assertEquals(0, ae.getFeatureList().size());
    }

    @Test
    public void testPersistInclusionOrders() {
        List<InclusionOrder> list = new ArrayList<InclusionOrder>();
        for (int i = 0; i < 5; i++) {
            InclusionOrder inclusionOrder = new InclusionOrder();
            inclusionOrder.setItemId(321);
            list.add(inclusionOrder);
        }
        assertEquals(1, accessibilityItemServices.findInclusionOrders(321)
                .size());
        accessibilityItemServices.persistInclusionOrders(list);
        assertEquals(6, accessibilityItemServices.findInclusionOrders(321)
                .size());
    }

    @Test
    public void testDeleteInclusionOrders() {
        assertEquals(3, accessibilityItemServices.findInclusionOrders(123)
                .size());
        accessibilityItemServices.deleteInclusionOrders(123);
        assertEquals(0, accessibilityItemServices.findInclusionOrders(123)
                .size());
    }

    @Test
    public void testReplaceInclusionOrders() {
        List<InclusionOrder> list = new ArrayList<InclusionOrder>();
        for (int i = 0; i < 7; i++) {
            InclusionOrder inclusionOrder = new InclusionOrder();
            inclusionOrder.setItemId(123);
            list.add(inclusionOrder);
        }
        assertEquals(3, accessibilityItemServices.findInclusionOrders(123)
                .size());
        accessibilityItemServices.replaceInclusionOrders(123, list);
        assertEquals(7, accessibilityItemServices.findInclusionOrders(123)
                .size());
    }

    @Test
    public void testDeleteAccessibilityElements() {
        assertEquals(2, accessibilityItemServices
                .findAccessibilityElements(123).size());
        accessibilityItemServices.deleteAccessibilityElements(123,
                Collections.singletonList("ae002"));
        List<AccessibilityElement> list = accessibilityItemServices
                .findAccessibilityElements(123);
        assertEquals(1, list.size());
        assertEquals("ae002", list.get(0).getName());
    }

    @Test
    public void testDeleteAccessibilityElementsNoRetain() {
        assertEquals(2, accessibilityItemServices
                .findAccessibilityElements(123).size());
        accessibilityItemServices.deleteAccessibilityElements(123, null);
        List<AccessibilityElement> list = accessibilityItemServices
                .findAccessibilityElements(123);
        assertEquals(0, list.size());
    }

    @Test
    public void testGetFeaturesForType() {
        // Do nothing because of X and Y.
    }

    @Test
    public void testDeleteAccessibilityFeaturesNotInList() {
        AccessibilityElement ae = accessibilityItemServices
                .findAccessibilityElementById(1);
        assertEquals(2, ae.getFeatureList().size());
        accessibilityItemServices.deleteAccessibilityFeaturesForElement(1);
        entityManager.refresh(ae);
        assertEquals(0, ae.getFeatureList().size());
    }

    @Test
    public void testReplaceAccessibilityFeatures() {
        Map<Integer, List<AccessibilityFeature>> featuresMap = new HashMap<Integer, List<AccessibilityFeature>>();

        List<AccessibilityFeature> featuresOne = new ArrayList<AccessibilityFeature>();
        for (int i = 0; i < 3; i++) {
            AccessibilityFeature af = new AccessibilityFeature();
            af.setElementId(1);
            featuresOne.add(af);
        }
        featuresMap.put(1, featuresOne);

        List<AccessibilityFeature> featuresTwo = new ArrayList<AccessibilityFeature>();
        for (int i = 0; i < 4; i++) {
            AccessibilityFeature af = new AccessibilityFeature();
            af.setElementId(2);
            featuresTwo.add(af);
        }
        featuresMap.put(2, featuresTwo);

        accessibilityItemServices.replaceAccessibilityFeatures(featuresMap);
        JpaUnitils.flushDatabaseUpdates();
        assertEquals(3,
                accessibilityItemServices.findAccessibilityElementById(1)
                        .getFeatureList().size());
        assertEquals(4,
                accessibilityItemServices.findAccessibilityElementById(2)
                        .getFeatureList().size());
    }

    @Test
    public void testReplaceAccessibilityElements() {
        List<AccessibilityElement> elements = accessibilityItemServices
                .findAccessibilityElements(123);
        assertEquals(2, elements.size());
        List<AccessibilityElement> newElements = new ArrayList<AccessibilityElement>();
        newElements.add(elements.get(0));
        AccessibilityElement aeOne = new AccessibilityElement();
        aeOne.setItemId(123);
        aeOne.setName("ae009");
        newElements.add(aeOne);

        AccessibilityElement aeTwo = new AccessibilityElement();
        aeTwo.setItemId(123);
        aeTwo.setName("ae010");
        newElements.add(aeTwo);

        accessibilityItemServices
                .replaceAccessibilityElements(123, newElements);
        assertEquals(3, accessibilityItemServices
                .findAccessibilityElements(123).size());
    }

    @Test
    public void testReplaceModifyAccessibilityElements() {
        List<AccessibilityElement> elements = accessibilityItemServices
                .findAccessibilityElements(123);
        assertEquals(2, elements.size());
        accessibilityItemServices.entityManager.clear();
        elements.get(0).setContentName("new0");
        elements.get(1).setContentName("new1");
        List<String> modifiedElements = new ArrayList<String>();
        modifiedElements.add(elements.get(1).getName());
        accessibilityItemServices.replaceAccessibilityElements(123, elements,
                modifiedElements);
        accessibilityItemServices.entityManager.flush();
        accessibilityItemServices.entityManager.clear();
        List<AccessibilityElement> newElements = accessibilityItemServices
                .findAccessibilityElements(123);
        assertEquals("new1", newElements.get(1).getContentName());
        // only one element should have been modified; verifying that
        assertNotSame("new0", newElements.get(0).getContentName());
    }

}
