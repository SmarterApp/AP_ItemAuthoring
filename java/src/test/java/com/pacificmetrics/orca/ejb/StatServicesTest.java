package com.pacificmetrics.orca.ejb;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import java.util.Arrays;
import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import junit.framework.Assert;

import org.junit.Test;
import org.unitils.UnitilsJUnit4;
import org.unitils.database.annotations.Transactional;
import org.unitils.database.util.TransactionMode;
import org.unitils.dbunit.annotation.DataSet;
import org.unitils.inject.annotation.TestedObject;
import org.unitils.orm.jpa.JpaUnitils;
import org.unitils.orm.jpa.annotation.JpaEntityManagerFactory;

import com.pacificmetrics.common.ServiceException;
import com.pacificmetrics.orca.entities.StatAdministration;
import com.pacificmetrics.orca.entities.StatItemValue;
import com.pacificmetrics.orca.entities.StatKey;
import com.pacificmetrics.orca.test.InjectIntoByTypeExt;

@DataSet("StatServicesTest.xml")
@JpaEntityManagerFactory(persistenceUnit = "test-cde-unit", configFile = "META-INF/persistence-test.xml")
public class StatServicesTest extends UnitilsJUnit4 {

    @TestedObject
    StatServices statServices;

    @InjectIntoByTypeExt
    @PersistenceContext
    EntityManager entityManager;

    @Test
    public void testFindAdministrationById() {
        StatAdministration sa = statServices.findAdministrationById(1);
        assertNotNull(sa);
        assertEquals("ADM-1", sa.getIdentifier());
        assertNull(statServices.findAdministrationById(10));
    }
    
    @Test
    public void testFindAdministrations() {
        {
            List<StatAdministration> list = statServices.findAdministrations(1);
            assertNotNull(list);
            assertEquals(2, list.size());
        }
        {
            List<StatAdministration> list = statServices.findAdministrations(11);
            assertNotNull(list);
            assertEquals(1, list.size());
        }
        {
            List<StatAdministration> list = statServices.findAdministrations(3);
            assertNotNull(list);
            assertEquals(0, list.size());
        }
    }
    
    @Test
    public void testMergeStatAdministration() {
        StatAdministration sa = new StatAdministration();
        sa.setIdentifier("NEW-ADM-1");
        sa.setItemBankId(11);
        sa.setStatusId(0);
        try {
            sa = statServices.merge(sa);
            assertNotNull(sa);
            assertEquals(4, sa.getId());
        } catch (ServiceException e) {
            Assert.fail("Unexpected exception: " + e);
        }
        statServices.updateStatus(4, 1);
        sa = statServices.findAdministrationById(4);
        assertEquals(1, sa.getStatusId());
    }
    
    @Test
    @Transactional(value=TransactionMode.ROLLBACK) //need to rollback transaction in case of failure; unitils commits transaction by default 
    public void testMergeStatAdministrationFail() {
        StatAdministration sa = new StatAdministration();
        sa.setIdentifier("1234567890123456789012345678901234567890");
        sa.setItemBankId(11);
        sa.setStatusId(0);
        try {
            sa = statServices.merge(sa);
            Assert.fail("Exception should have been thrown");
        } catch (ServiceException e) {
        }
    }
    
    @Test
    public void testMergeStatItemValue() {
        StatItemValue siv = new StatItemValue();
        siv.setItemId(1);
        siv.setNumericValue(0.1);
        siv.setStatAdministrationId(1);
        siv.setStatKeyId(1);
        siv = statServices.merge(siv);
        assertNotNull(siv);
        assertEquals(2, siv.getId());
    }
    
    @Test
    public void testDeleteStatAdministration() {
        statServices.deleteStatAdministration(3);
        StatAdministration sa = statServices.findAdministrationById(3);
        assertNull(sa);
        assertEquals(0, statServices.findAdministrations(11).size());
    }
    
    @Test
    public void testFindStatKeys() {
        List<StatKey> keys = statServices.findStatKeys(Arrays.asList(new String[] {"KEY1", "KEY2", "KEY4"}));
        assertEquals(2, keys.size());
        List<String> keyNames = statServices.getKeyNames(keys);
        assertEquals(2, keyNames.size());
        assertTrue(keyNames.contains("KEY1"));
        assertTrue(keyNames.contains("KEY2"));
        assertFalse(keyNames.contains("KEY4"));
    }


}

