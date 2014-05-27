/**
 * 
 */
package com.pacificmetrics.orca.export;

import java.io.InputStream;
import java.io.OutputStream;
import java.util.List;

import com.pacificmetrics.orca.entities.Item;

/**
 * @author maumock
 * 
 */
public interface ItemExporter {
    public InputStream export(List<Item> items) throws ItemExportException;

    public void initialize() throws ItemExportException;

    public void destroy() throws ItemExportException;
}
