package com.pacificmetrics.orca.mbeans;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.Query;

import junit.framework.Assert;

import org.apache.myfaces.custom.fileupload.UploadedFile;
import org.junit.Test;
import org.unitils.UnitilsJUnit4;
import org.unitils.dbunit.annotation.DataSet;
import org.unitils.inject.annotation.TestedObject;
import org.unitils.mock.Mock;
import org.unitils.mock.annotation.AfterCreateMock;
import org.unitils.orm.jpa.annotation.JpaEntityManagerFactory;

import com.pacificmetrics.common.web.ManagerException;
import com.pacificmetrics.orca.ejb.ItemBankServices;
import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.ejb.StatServices;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemBank;
import com.pacificmetrics.orca.test.InjectIntoByTypeExt;
import com.pacificmetrics.orca.test.TestedManager;

@DataSet({"PsychometricsImportManagerTest.xml", "../common/ItemBanks.xml"})
@JpaEntityManagerFactory(persistenceUnit = "test-cde-unit", configFile = "META-INF/persistence-test.xml")
public class PsychometricsImportManagerTest extends UnitilsJUnit4 {

    @TestedObject
    @TestedManager
    PsychometricsImportManager psychometricsImport;
    
    @InjectIntoByTypeExt(target="psychometricsImport")
    @TestedObject
    StatServices statServices;
    
    @InjectIntoByTypeExt(target="psychometricsImport")
    Mock<ItemBankServices> mockItemBankServices;
    
    @InjectIntoByTypeExt(target="statServices")
    Mock<ItemServices> mockItemServices;
    
    @InjectIntoByTypeExt(target="psychometricsImport")
    Mock<UploadedFile> mockUploadedFile;
    
    Mock<UploadedFile> mockUploadedFileBad1;
    
    Mock<UploadedFile> mockUploadedFileBad2;
    
    Mock<UploadedFile> mockUploadedFileBad3;
    
    Mock<UploadedFile> mockUploadedFileBad4;
    
    Mock<UploadedFile> mockUploadedFileBad5;
    
    @InjectIntoByTypeExt(target={"statServices"})
    @PersistenceContext
    EntityManager entityManager;

    @AfterCreateMock
    void initMock(Object mock, String name, Class<?> type) throws IOException {
        if (type.equals(ItemBankServices.class)) {
            @SuppressWarnings("unchecked")
            List<ItemBank> itemBankList = new ArrayList<ItemBank>(entityManager.createNamedQuery("allItemBanks").getResultList());
            mockItemBankServices.returns(itemBankList).getItemBanksForUser(null);
        }
        if (type.equals(ItemServices.class)) {
            Item item = new Item();
            item.setItemBankId(15);
            mockItemServices.returns(item).findItemByExternalId(null);
        }
        //
        if (type.equals(UploadedFile.class)) {
            if (mock == mockUploadedFile) {
                mockUploadedFile.returns("stat1.csv").getName();
                mockUploadedFile.returns("ID,key1,key2\nITEM-1,0.28,0.84\nITEM-2,0.77,0.41".getBytes()).getBytes();
            }
            if (mock == mockUploadedFileBad1) {
                mockUploadedFileBad1.returns("stat1.xxx").getName();
            }
            if (mock == mockUploadedFileBad2) {
                mockUploadedFileBad2.returns("stat1.csv").getName();
                mockUploadedFileBad2.returns("ID,key1,key2\nITEM-1,0.84\nITEM-2,0.77,0.41".getBytes()).getBytes();
            }
            if (mock == mockUploadedFileBad3) {
                mockUploadedFileBad3.returns("stat1.csv").getName();
                mockUploadedFileBad3.returns("ID,key1,key2\nITEM-1,,0.84\nITEM-2,0.77,0.41".getBytes()).getBytes();
            }
            if (mock == mockUploadedFileBad4) {
                mockUploadedFileBad4.returns("stat1.csv").getName();
                mockUploadedFileBad4.returns("ID,key1,key2\n".getBytes()).getBytes();
            }
            if (mock == mockUploadedFileBad5) {
                mockUploadedFileBad5.returns("stat1.csv").getName();
                mockUploadedFileBad5.returns("ID,key1,key2\nITEM-1,0.28,0.84\nIT\u00A9EM-2,0.77,0.41".getBytes()).getBytes();
            }
        }
    }
    
    public PsychometricsImportManagerTest() {
    }

    @Test
    public void testItemBankSelected() {
        psychometricsImport.setSelectedItemBankId(15);
        psychometricsImport.itemBankSelected(null);
        assertEquals(2, psychometricsImport.getAdministrations().size());
    }
    
    @Test
    public void testUpload() {
        try {
            psychometricsImport.setSelectedItemBankId(15);
            psychometricsImport.setIdentifier("NEW-ADM-1");
            psychometricsImport.upload();
        } catch (ManagerException e) {
            Assert.fail("Unexpected exception: " + e);
        }
        Query query = entityManager.createNativeQuery("select count(*) from stat_item_value where " +
        		                                      "sa_id in (select sa_id from stat_administration " +
        		                                      "where sa_identifier = 'NEW-ADM-1')");
        assertTrue(((Number)query.getSingleResult()).intValue() == 4);
    }

    @Test
    public void testUploadFail1() {
        try {
            psychometricsImport.setUploadedFile(mockUploadedFileBad1.getMock());
            psychometricsImport.setSelectedItemBankId(15);
            psychometricsImport.setIdentifier("NEW-ADM-1");
            psychometricsImport.upload();
            //expecting error message in context
            assertFalse(psychometricsImport.messageContext.getMessages().isEmpty());
        } catch (ManagerException e) {
        }
    }

    @Test
    public void testUploadFail2() {
        try {
            psychometricsImport.setUploadedFile(mockUploadedFileBad2.getMock());
            psychometricsImport.setSelectedItemBankId(15);
            psychometricsImport.setIdentifier("NEW-ADM-1");
            psychometricsImport.upload();
            //expecting error message in context
            assertFalse(psychometricsImport.messageContext.getMessages().isEmpty());
        } catch (ManagerException e) {
        }
    }

    @Test
    public void testUploadFail3() {
        try {
            psychometricsImport.setUploadedFile(mockUploadedFileBad3.getMock());
            psychometricsImport.setSelectedItemBankId(15);
            psychometricsImport.setIdentifier("NEW-ADM-1");
            psychometricsImport.upload();
            //expecting error message in context
            assertFalse(psychometricsImport.messageContext.getMessages().isEmpty());
        } catch (ManagerException e) {
        }
    }

    @Test
    public void testUploadFail4() {
        try {
            psychometricsImport.setUploadedFile(mockUploadedFileBad4.getMock());
            psychometricsImport.setSelectedItemBankId(15);
            psychometricsImport.setIdentifier("NEW-ADM-1");
            psychometricsImport.upload();
            //expecting error message in context
            assertFalse(psychometricsImport.messageContext.getMessages().isEmpty());
        } catch (ManagerException e) {
        }
    }

    @Test
    public void testUploadFail5() {
        try {
            psychometricsImport.setUploadedFile(mockUploadedFileBad5.getMock());
            psychometricsImport.setSelectedItemBankId(15);
            psychometricsImport.setIdentifier("NEW-ADM-1");
            psychometricsImport.upload();
            //expecting error message in context
            assertFalse(psychometricsImport.messageContext.getMessages().isEmpty());
        } catch (ManagerException e) {
        }
    }

}
