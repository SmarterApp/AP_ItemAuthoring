package com.pacificmetrics.orca.mbeans;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.ResourceBundle;
import java.util.logging.Logger;

import javax.annotation.PostConstruct;
import javax.ejb.EJB;
import javax.faces.bean.ManagedBean;
import javax.faces.bean.ViewScoped;
import javax.faces.component.UIComponent;
import javax.faces.event.ValueChangeEvent;
import javax.faces.event.ValueChangeListener;
import javax.faces.model.SelectItem;

import com.pacificmetrics.orca.ServerConfiguration;
import com.pacificmetrics.orca.ejb.ItemAlternateServices;
import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemAlternate;

/**
 * ItemAlternateManager is responsible for servicing requests for
 * ItemAlternate.xhtml
 * 
 * @author dbloom
 */
@ManagedBean(name = "itemAlternate")
@ViewScoped
public class ItemAlternateManager extends AbstractManager implements
		Serializable {

	static private Logger logger = Logger.getLogger(ItemAlternateManager.class
			.getName());

	private static final long serialVersionUID = 1L;

	/**
	 * "original" {@link Item}.
	 */
	private Item originalItem;

	/**
	 * Source {@link Item}. <code>null</code> if "original" item is not an
	 * {@link ItemAlternate}
	 */
	private Item sourceItem;

	/**
	 * {@link ItemAlternate}s for "original" {@link Item} stored by the
	 * {@link ItemAlternate#getAlternateItemId()}.
	 */
	private Map<Integer, ItemAlternate> itemAlternateMap = new HashMap<Integer, ItemAlternate>();;

	/**
	 * Underlying {@link Item} data for item alternates stored by the
	 * {@link Item#getId()}.
	 */
	private Map<Integer, Item> itemMap = new HashMap<Integer, Item>();

	/**
	 * {@link SelectItem}s for {@link ItemAlternate}s. Used to generate
	 * selection menu options for item alternate windows.
	 */
	private List<SelectItem> itemAlternateSelectItems = new ArrayList<SelectItem>();

	/**
	 * Active item alternate windows and associated {@link Item}s. A given index
	 * may return <code>null</code> if the user has not selected an item
	 * alternate.
	 */
	private List<Item> windows = new ArrayList<Item>();

	@EJB
	private ItemAlternateServices itemAlternateServices;

	@EJB
	private ItemServices itemServices;

	/**
	 * Load required backing data
	 */
	@PostConstruct
	public void load() {
		Integer itemId = null;

		if (getParameter("itemId") != null) {
			try {
				itemId = Integer.valueOf(getParameter("itemId"));
			} catch (NumberFormatException nfe) {
				// doesn't matter whether too long or wrong format, but could be
				// someone trying something so worth logging
				logger.warning(nfe.getMessage());
			}
		} else {
			error("Error.ItemAlternate.InvalidItemId");
			return;
		}

		if (itemId != null) {
			// TODO: update itemServices to check whether user has permissions to view item
			originalItem = itemServices.findItemById(itemId);
		} else {
			error("Error.ItemAlternate.InvalidItemId");
			return;
		}

		if (originalItem != null) {
			ItemAlternate originalItemAlternate = itemAlternateServices
					.findByAlternateItemId(originalItem.getId());

			// if the original item is also an alternate load the source
			// item
			if (originalItemAlternate != null) {
				sourceItem = itemServices.findItemById(originalItemAlternate
						.getItemId());
			}

			addWindow();

			itemAlternateMap = populateItemAlternateMap();
			itemMap = populateItemMap();
			itemAlternateSelectItems = populateItemAlternateSelectItems();
		} else {
			error("Error.ItemAlternate.ItemNotFound", String.valueOf(itemId));
			return;
		}
	}

	/* listeners */
	
	/**
	 * {@link ValueChangeListener} for the {@link ItemAlternate} window
	 * selection menus. Updates the appropriate window with the selected
	 * {@link ItemAlternate}.
	 * 
	 * TODO: use ajax call instead
	 * 
	 * @param event
	 *            ValueChangedEvent
	 */
	public void selectItemAlternateId(ValueChangeEvent event) {
		Object o1 = event.getNewValue();

		if (o1 != null) {
			Integer alternateId = Integer.valueOf(o1.toString());

			UIComponent selectOneMenu = event.getComponent();
			Map<String, Object> attributes = selectOneMenu.getAttributes();
			Object o2 = attributes.get("index");

			int index = Integer.valueOf(o2.toString());

			setSelectedItemAlternateId(index, alternateId);
		}
	}
	
	/* service methods */

	/**
	 * Add new window to the view
	 */
	public void addWindow() {
		// null represents an empty item alternate window
		if (windows.size() < 5) {
			windows.add(null);
		} else {
			error("Error.ItemAlternate.MaxWindows");
		}
	}

	/**
	 * Remove window from the view
	 * 
	 * @param index
	 */
	public void removeWindow(int index) {
		if (windows.size() > index) {
			windows.remove(index);
		}
	}

	/**
	 * @return List<Item> of displayed alternate {@link Item}s
	 */
	public List<Item> getWindows() {
		return windows;
	}

	/**
	 * @return List<SelectItem> of all available {@link ItemAlternate}s for the
	 *         "original" {@link Item}; used to construct the select box
	 */
	public List<SelectItem> getItemAlternateSelectItems() {
		return itemAlternateSelectItems;
	}

	/**
	 * Set the {@link ItemAlternate} selected in <code>index</code> window by
	 * {@link ItemAlternate#getAlternateItemId()}.
	 * 
	 * @param index
	 *            into the list of selected item alternates
	 * @param Integer
	 *            the item id (i_id) for the selected item alternate
	 */
	void setSelectedItemAlternateId(int index,
			Integer selectedItemAlternateId) {
		Item ia = null;

		if (itemMap.containsKey(selectedItemAlternateId)) {
			ia = itemMap.get(selectedItemAlternateId);
		} else if (sourceItem != null
				&& sourceItem.getId() == selectedItemAlternateId.intValue()) {
			ia = sourceItem;
		}

		if (ia != null) {
			if (windows.size() > index) {
				windows.set(index, ia);
			}
		}
	}

	/**
	 * Retrieve the url for rendering the "original" {@link Item}.
	 * 
	 * @return String url to render the "original" item
	 */
	public String getOriginalItemViewUrl() {
		String originalItemViewUrl = "";
		
		if (originalItem != null) {
			originalItemViewUrl = getViewUrl(originalItem.getId());
		}
		
		return originalItemViewUrl;
	}

	/**
	 * Retrieve the url for rendering the {@link Item#getId()}.
	 * 
	 * @param itemId
	 *            Integer representing the i_id of the requested item
	 * @return String url to render the requested item; <code>null</code> if
	 *         <code>itemId</code> is not the "original" item, source item, or
	 *         an alternate
	 */
	public String getViewUrl(Long itemId) {
		if (itemId == null) {
			return null;
		}
		
		logger.info("Retrieving view url for item id: " + itemId);

		final boolean isOriginalItem = (originalItem != null ? itemId.equals(originalItem.getId())
				: false);
		final boolean isSourceItem = (sourceItem != null ? itemId.equals(sourceItem
				.getId()) : false);
		final boolean isAlternateItem = itemAlternateMap.containsKey((int)(long)itemId);
		
		if (isOriginalItem || isSourceItem || isAlternateItem) {
			return ServerConfiguration
					.getProperty(ServerConfiguration.HTTP_SERVER_CGI_BIN_URL)
					+ "/itemSingleView.pl?itemId=" + itemId;
		}

		return null;
	}

	/**
	 * @return String representing the name of the "original" {@link Item}
	 */
	public String getOriginalItemName() {
		String originalItemName = "";
		
		if (originalItem != null) {
			originalItem.getExternalId();
		}

		return originalItemName;
	}

	/**
	 * @param itemAlternateId
	 *            Integer representing the
	 *            {@link ItemAlternate#getAlternateItemId()} of the requested
	 *            {@link ItemAlternate}
	 * @return String representing label for the alternate item or source item
	 */
	public String getAlternateLabel(Integer itemAlternateId) {
		String alternateLabel = "";

		if (itemAlternateMap.containsKey(itemAlternateId)) {
			ItemAlternate ia = itemAlternateMap.get(itemAlternateId);
			alternateLabel = ia.getAlternateType();
		} else if (sourceItem != null
				&& sourceItem.getId() == itemAlternateId.intValue()) {
			alternateLabel = ResourceBundle.getBundle("text").getString(
					"ItemAlternate.SourceItemLabel");
		}

		return alternateLabel;
	}

	/* data load methods */

	/**
	 * @return Map<Integer, ItemAlternate> map of {@link ItemAlternate}s stored
	 *         by the {@link ItemAlternate#getAlternateItemId()}.
	 */
	private Map<Integer, ItemAlternate> populateItemAlternateMap() {
		Map<Integer, ItemAlternate> itemAlternateMap = new HashMap<Integer, ItemAlternate>();

		long itemId = originalItem.getId();

		List<ItemAlternate> itemAlternates = itemAlternateServices
				.findItemAlternatesByItemId(itemId);

		for (ItemAlternate ia : itemAlternates) {
			itemAlternateMap.put(ia.getAlternateItemId(), ia);
		}

		return itemAlternateMap;
	}

	/**
	 * @return Map<Integer, Item> map of {@link ItemAlternate}s as {@link Item}
	 *         stored by the {@link Item#getId()}.
	 */
	private Map<Integer, Item> populateItemMap() {
		// ensure that itemAlternateMap is populated prior to loading itemMap
		if (itemAlternateMap.size() == 0) {
			itemAlternateMap = populateItemAlternateMap();
		}

		Map<Integer, Item> itemMap = new HashMap<Integer, Item>();

		for (ItemAlternate itemAlternate : itemAlternateMap.values()) {
			Integer itemAlternateId = itemAlternate.getAlternateItemId();
			Item item = itemServices.findItemById(itemAlternateId);
			itemMap.put(itemAlternateId, item);
		}
		
		return itemMap;
	}

	/**
	 * @return List<SelectItem> list of {@link SelectItem}s for selection menus
	 *         using {@link ItemAlternate#getAlternateItemId()} as the value and
	 *         {@link ItemAlternate#getAlternateType()} as the text.
	 */
	private List<SelectItem> populateItemAlternateSelectItems() {
		List<SelectItem> itemAlternateSelectItems = new ArrayList<SelectItem>();

		// original is itself an item alternate
		if (sourceItem != null) {
			String selectSourceText = ResourceBundle.getBundle("text")
					.getString("ItemAlternate.SelectSourceDefault");
			SelectItem si = new SelectItem(null, selectSourceText);
			si.setNoSelectionOption(true);
			itemAlternateSelectItems.add(si);

			String selectSourceItemText = ResourceBundle.getBundle("text")
					.getString("ItemAlternate.SourceItemLabel");
			si = new SelectItem(sourceItem.getId(), selectSourceItemText);
			itemAlternateSelectItems.add(si);
		}

		List<ItemAlternate> itemAlternates = itemAlternateServices
				.findItemAlternatesByItemId(originalItem.getId());

		// original has item alternates
		if (itemAlternates.size() > 0) {
			String selectAlternateText = ResourceBundle.getBundle("text")
					.getString("ItemAlternate.SelectAlternateDefault");
			SelectItem si = new SelectItem(null, selectAlternateText);
			si.setNoSelectionOption(true);
			itemAlternateSelectItems.add(si);

			for (ItemAlternate ia : itemAlternates) {
				si = new SelectItem(ia.getAlternateItemId(),
						ia.getAlternateType());
				itemAlternateSelectItems.add(si);
			}
		}

		return itemAlternateSelectItems;
	}
}
