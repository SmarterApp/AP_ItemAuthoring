package com.pacificmetrics.orca.ejb;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import java.util.Arrays;
import java.util.Collection;

import org.junit.Test;
import org.unitils.UnitilsJUnit4;
import org.unitils.dbunit.annotation.DataSet;
import org.unitils.inject.annotation.TestedObject;
import org.unitils.orm.jpa.annotation.JpaEntityManagerFactory;

import com.pacificmetrics.orca.entities.Item;

/**
 * 
 * @author amiliteev
 * @modifier maumock
 * 
 */

@DataSet("ItemServicesTest.xml")
@JpaEntityManagerFactory(persistenceUnit = "test-cde-unit", configFile = "META-INF/persistence-test.xml")
public class ItemServicesTest extends UnitilsJUnit4 {

    @TestedObject
    private ItemServices itemServices;

    @Test
    public void testFindById() {
        assertTrue("ITEM-1".equals(this.itemServices.findItemById(1)
                .getExternalId()));
        assertTrue(this.itemServices.findItemById(5) == null);
    }

    @Test
    public void testFindByExternalId() {
        assertTrue(this.itemServices.findItemByExternalId("ITEM-2").getId() == 2);
        assertTrue(this.itemServices.findItemByExternalId("XXX") == null);
    }

    @Test
    public void testFindByItemBankAndExternalId() {
        assertTrue(this.itemServices.findItemByItemBankAndExternalId(14,
                "ITEM-2").getId() == 2);
        assertTrue(this.itemServices.findItemByItemBankAndExternalId(15,
                "ITEM-2") == null);
        assertTrue(this.itemServices.findItemByItemBankAndExternalId(14,
                "ITEM-3").getId() == 3);
        assertTrue(this.itemServices.findItemByItemBankAndExternalId(15,
                "ITEM-3").getId() == 4);
    }

    @Test
    @SuppressWarnings("boxing")
    public void testGetItemIds() {
        Collection<Long> items = this.itemServices.getItemIds(
                Arrays.asList(new String[] { "ITEM-1", "ITEM-2", "ITEM-3",
                        "ITEM-4" })).keySet();
        assertNotNull(items);
        assertTrue(items.size() == 4);
        assertTrue(items.contains(1L) && items.contains(2L)
                && items.contains(3L));
    }

    @Test
    public void testFindItemWithInteractionsById() {
        assertTrue(itemServices.findItemWithInteractionsById(1)
                .getItemInteractions().size() == 1);
        assertTrue(itemServices.findItemWithInteractionsById(2)
                .getItemInteractions().size() == 2);
        assertTrue(itemServices.findItemWithInteractionsById(3)
                .getItemInteractions().isEmpty());
    }

    @Test
    public void testGetItemAsHTML2() {
        Item itemOne = itemServices.findItemWithInteractionsById(1);
        String htmlOne = itemServices.getItemAsHTML2(itemOne);
        assertEquals(
                "<p id=\"content2\">Answer the following question.</p>This is Prompt<br><table><tr><td><b>A:&nbsp; </b><td>This is Choice 1<tr><td><b>B:&nbsp; </b><td>This is Choice 2</table><br/>",
                htmlOne);

        Item itemTwo = itemServices.findItemWithInteractionsById(2);
        String htmlTwo = itemServices.getItemAsHTML2(itemTwo);
        assertEquals(
                "Question 1:<br/>This is Prompt<br><table><tr><td><b>A:&nbsp; </b><td>This is Choice 1<tr><td><b>B:&nbsp; </b><td>This is Choice 2</table>Question 2:<br/>Enter text:<br><br/>",
                htmlTwo);
    }

}
