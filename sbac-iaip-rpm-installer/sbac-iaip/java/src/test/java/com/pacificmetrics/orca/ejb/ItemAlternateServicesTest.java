package com.pacificmetrics.orca.ejb;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import org.junit.Test;
import org.unitils.UnitilsJUnit4;
import org.unitils.dbunit.annotation.DataSet;
import org.unitils.inject.annotation.TestedObject;
import org.unitils.orm.jpa.annotation.JpaEntityManagerFactory;

import com.pacificmetrics.orca.entities.ItemAlternate;
import com.pacificmetrics.orca.test.InjectIntoByTypeExt;

/**
 * Unit test for {@link ItemAlternateServices}
 * 
 * @author dbloom
 */
@DataSet("ItemAlternateServicesTest.xml")
@JpaEntityManagerFactory(persistenceUnit = "test-cde-unit", configFile = "META-INF/persistence-test.xml")
public class ItemAlternateServicesTest extends UnitilsJUnit4 {

	@TestedObject
	ItemAlternateServices alternateServices;

	@InjectIntoByTypeExt
	@PersistenceContext
	EntityManager entityManager;

	@Test
	public void testFindById() {
		ItemAlternate ia = alternateServices.findItemAlternateById(1);
		assertNotNull(ia);
		assertEquals(ia.getItemId(), 1);
		assertEquals(ia.getAlternateItemId(), 2);
		assertEquals(ia.getAlternateType(), "Simplified");

		ia = alternateServices.findItemAlternateById(4);
		assertNotNull(ia);
		assertEquals(ia.getItemId(), 2);
		assertEquals(ia.getAlternateItemId(), 5);
		assertEquals(ia.getAlternateType(), "Simplified");
	}

	@Test
	public void testFindByItemId() {
		List<ItemAlternate> ias = alternateServices
				.findItemAlternatesByItemId(2);
		assertNotNull(ias);
		assertEquals(ias.size(), 1);

		ias = alternateServices.findItemAlternatesByItemId(1);
		assertNotNull(ias);
		assertEquals(ias.size(), 3);
	}

	@Test
	public void testFindByAlternateItemId() {
		// check that item alternate service returns null when item alternate does not exist
		ItemAlternate ia = alternateServices.findByAlternateItemId(1);
		assertEquals(null, ia);

		ia = alternateServices.findByAlternateItemId(3);
		assertNotNull(ia);
		assertEquals(3, ia.getAlternateItemId());
	}
}
