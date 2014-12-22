package com.pacificmetrics.orca.loader;

import java.io.InputStream;
import java.util.List;

import com.pacificmetrics.orca.entities.Item;

public interface ItemImporter {

	public List<Item> importItems(InputStream inputStream) throws ItemImportException;
	
	public void initialized () throws ItemImportException;
	
	public void destroy() throws ItemImportException;
	
}
