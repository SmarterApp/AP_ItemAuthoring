package com.pacificmetrics.orca.cache;

import static org.junit.Assert.assertEquals;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import org.junit.Test;
import org.unitils.UnitilsJUnit4;
import org.unitils.dbunit.annotation.DataSet;
import org.unitils.inject.annotation.TestedObject;
import org.unitils.mock.Mock;
import org.unitils.orm.jpa.annotation.JpaEntityManagerFactory;

import com.pacificmetrics.orca.ejb.MiscServices;
import com.pacificmetrics.orca.test.CallCounter;
import com.pacificmetrics.orca.test.InjectIntoByTypeExt;

@DataSet("LookupCacheTest.xml")
@JpaEntityManagerFactory(persistenceUnit = "test-cde-unit", configFile = "META-INF/persistence-test.xml")
public class LookupCacheTest extends UnitilsJUnit4 {

    @TestedObject
    MiscServices miscServices;
    
    @InjectIntoByTypeExt(target={"miscServices"})
    @PersistenceContext
    EntityManager entityManager;
    
    Mock<MiscServices> miscServicesMock;
    
    @Test
    public void testGetLookupCode() {
        LookupCache lookupCache = new LookupCache(miscServices);
        Integer value3 = lookupCache.getLookupCode("dev_state", "ds_name", null, "ds_id", "Assigned");
        assertEquals(3, value3.intValue());
        Integer value8 = lookupCache.getLookupCode("dev_state", "ds_name", null, "ds_id", "Final");
        assertEquals(8, value8.intValue());
    }

    @Test
    public void testGetLookupCode2() {
        
        CallCounter callCounter = new CallCounter();
        miscServicesMock.performs(callCounter).getLookupCode(null, null, null, null, null);
        
        LookupCache lookupCache = new LookupCache(miscServicesMock.getMock());
        //Only three of below calls should result in invocation of MiscServices.getLookupCode() method
        //In other cases values should be retrieved from cache
        lookupCache.getLookupCode("dev_state", "ds_name", null, "ds_id", "XXX");
        lookupCache.getLookupCode("dev_state", "ds_name", null, "ds_id", "YYY");
        lookupCache.getLookupCode("dev_state", "ds_name", null, "ds_id", "XXX");
        lookupCache.getLookupCode("dev_state", "ds_name", null, "ds_id", "XXX");
        lookupCache.getLookupCode("dev_state", "ds_name", null, "ds_id", "YYY");
        lookupCache.getLookupCode("dev_state", "ds_xxx", null, "ds_id", "YYY");
        
        assertEquals(3, callCounter.getCount());
    }
    
    @Test
    public void testGetLookupCodeMultiThread() throws InterruptedException {
        
        CallCounter callCounter = new CallCounter();
        miscServicesMock.performs(callCounter).getLookupCode(null, null, null, null, null);

        final LookupCache lookupCache = new LookupCache(miscServicesMock.getMock());
        
        int activeThreadCount = Thread.activeCount();
        
        Runnable r = new Runnable() {
            @Override
            public void run() {
                lookupCache.getLookupCode("dev_state", "ds_name", null, "ds_id", "XXX");
                lookupCache.getLookupCode("dev_state", "ds_name", null, "ds_id", "YYY");
                lookupCache.getLookupCode("dev_state", "ds_name", null, "ds_id", "ZZZ");
            }
        };
        
        //Starting 100 simultaneous threads that launch above Runnable
        for (int i = 0; i < 100; i++) {
            new Thread(r).start();
        }
        
        //Wait for all threads to complete
        while (Thread.activeCount() != activeThreadCount) {
            Thread.sleep(10);
        }
        
        //Only 3 calls should be made to MiscServices.getLookupCode() method
        assertEquals(3, callCounter.getCount());
    }

}
