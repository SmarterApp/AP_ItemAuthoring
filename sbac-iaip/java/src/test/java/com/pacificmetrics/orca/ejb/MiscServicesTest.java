package com.pacificmetrics.orca.ejb;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.junit.Assert;
import org.junit.Test;
import org.unitils.UnitilsJUnit4;
import org.unitils.database.annotations.Transactional;
import org.unitils.database.util.TransactionMode;
import org.unitils.dbunit.annotation.DataSet;
import org.unitils.inject.annotation.TestedObject;
import org.unitils.orm.jpa.annotation.JpaEntityManagerFactory;
import com.pacificmetrics.orca.test.InjectIntoByTypeExt;

@DataSet("MiscServicesTest.xml")
@JpaEntityManagerFactory(persistenceUnit = "test-cde-unit", configFile = "META-INF/persistence-test.xml")
public class MiscServicesTest extends UnitilsJUnit4 {

	private static final Log LOGGER = LogFactory.getLog(MiscServicesTest.class);
	
    @TestedObject
    MiscServices miscServices;
    
    @InjectIntoByTypeExt
    @PersistenceContext
    EntityManager entityManager;
    
    @Test
    public void testCodeNotFound() {
        Integer code = miscServices.getLookupCode("dev_state", "ds_name", null, "ds_id", "Unknown");
        assertNull(code);
    }

    @Test
    public void testCodeNotNumeric() {
        Integer code = miscServices.getLookupCode("dev_state", "ds_name", null, "ds_name", "Rejected");
        assertNull(code);
    }

    @Test
    public void testCode1() {
        Integer code = miscServices.getLookupCode("dev_state", "ds_name", null, "ds_id", "Assigned");
        assertEquals(1, code.intValue());
    }

    @Test
    public void testCode9() {
        Integer code = miscServices.getLookupCode("dev_state", "ds_name", null, "ds_id", "Rejected");
        assertEquals(9, code.intValue());
    }

    @Test
    public void testPrefix() {
        Integer code = miscServices.getLookupCode("dev_state", "ds_name", "State:", "ds_id", "Accepted");
        assertEquals(2, code.intValue());
    }

    @Test
    @Transactional(value=TransactionMode.ROLLBACK) //need to rollback transaction in case of failure; unitils commits transaction by default
    public void testTableNotExists() {
        try {
            miscServices.getLookupCode("aaa", "bbb", null, "ccc", "ddd");
            Assert.fail("Exception should have been thrown");
        } catch (Exception e) {
        	LOGGER.error(e.getMessage(),e);
        }
    }


}
