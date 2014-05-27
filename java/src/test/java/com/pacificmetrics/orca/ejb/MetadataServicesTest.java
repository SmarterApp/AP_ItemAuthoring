package com.pacificmetrics.orca.ejb;

import static org.junit.Assert.assertEquals;

import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import org.junit.Test;
import org.unitils.UnitilsJUnit4;
import org.unitils.dbunit.annotation.DataSet;
import org.unitils.inject.annotation.TestedObject;
import org.unitils.orm.jpa.annotation.JpaEntityManagerFactory;

import com.pacificmetrics.orca.entities.MetadataMapping;
import com.pacificmetrics.orca.test.InjectIntoByTypeExt;

@DataSet("MetadataServicesTest.xml")
@JpaEntityManagerFactory(persistenceUnit = "test-cde-unit", configFile = "META-INF/persistence-test.xml")
public class MetadataServicesTest extends UnitilsJUnit4 {

    @TestedObject
    MetadataServices metadataServices;
    
    @InjectIntoByTypeExt
    @PersistenceContext
    EntityManager entityManager;
    
    @Test
    public void testExistingData() {
        List<MetadataMapping> list = metadataServices.getAllMetadataMappings();
        assertEquals(list.size(), 2);
    }

    @Test
    public void testExistingDataForItems() {
        List<MetadataMapping> list = metadataServices.getMetadataMappingsForItems();
        assertEquals(list.size(), 1);
    }

}
