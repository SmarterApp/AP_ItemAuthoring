package com.pacificmetrics.orca.mbeans;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import org.junit.Test;
import org.unitils.UnitilsJUnit4;
import org.unitils.dbunit.annotation.DataSet;
import org.unitils.inject.annotation.TestedObject;
import org.unitils.orm.jpa.annotation.JpaEntityManagerFactory;

import com.pacificmetrics.orca.ejb.ItemAlternateServices;
import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.test.InjectIntoByTypeExt;
import com.pacificmetrics.orca.test.TestParameter;
import com.pacificmetrics.orca.test.TestedManager;

/**
 * Unit test for {@link ItemAlternateManager}
 * 
 * @author dbloom
 */
@DataSet({"ItemAlternateManagerTest.xml"})
@JpaEntityManagerFactory(persistenceUnit = "test-cde-unit", configFile = "META-INF/persistence-test.xml")
public class ItemAlternateManagerTest extends UnitilsJUnit4 {
	@TestedObject
	@TestedManager
	@TestParameter(name="itemId", value="1") 
	ItemAlternateManager itemAlternate;
	
	@InjectIntoByTypeExt(target="itemAlternate")
	@TestedObject
	ItemServices itemServices;
	
	@InjectIntoByTypeExt(target="itemAlternate")
	@TestedObject
	ItemAlternateServices itemAlternateServices;
	
	@InjectIntoByTypeExt(target={"itemServices","itemAlternateServices"})
	@PersistenceContext
	EntityManager entityManager;
    
	@Test
	public void testLoad() {
		itemAlternate.load();
		
		// 9 item alternates plus the default selection
		assertEquals(10, itemAlternate.getItemAlternateSelectItems().size());
		
		assertEquals("Mandarin", itemAlternate.getAlternateLabel(2));
		assertEquals("Japanese", itemAlternate.getAlternateLabel(10));
		
		// default number of windows
		assertEquals(1, itemAlternate.getWindows().size());
	}
	
	@Test
	public void testAddRemoveWindows() {
		itemAlternate.load();
		
		assertEquals(1, itemAlternate.getWindows().size());
		
		itemAlternate.addWindow();
		assertEquals(2, itemAlternate.getWindows().size());
		
		// try to delete a window that doesn't exist
		itemAlternate.removeWindow(2);
		assertEquals(2, itemAlternate.getWindows().size());
		
		itemAlternate.removeWindow(1);
		assertEquals(1, itemAlternate.getWindows().size());
	}
	
	@Test
	public void testSelectItemAlternate() {
		itemAlternate.load();
		
		// try to select an item alternate for a window that does not exist
		itemAlternate.setSelectedItemAlternateId(1, 1);
		assertEquals(1, itemAlternate.getWindows().size());
		
		// try to select an item alternate that does not exist
		itemAlternate.addWindow();
		assertEquals(2, itemAlternate.getWindows().size());
		
		itemAlternate.setSelectedItemAlternateId(0, -1);
		assertNull(itemAlternate.getWindows().get(0));
		
		// select Spanish
		itemAlternate.setSelectedItemAlternateId(0, 3);
		assertEquals(3, itemAlternate.getWindows().get(0).getId());
		assertEquals("Spanish", itemAlternate.getAlternateLabel(3));
	}
}