/**
 * 
 */
package com.pacificmetrics.common;

import java.util.ArrayList;
import java.util.List;

/**
 * 
 * Exception class used when an item does exist in the item bank.
 * 
 * @author maumock
 * 
 */
public class ItemNotFoundException extends Exception {

    /**
     * 
     */
    private static final long serialVersionUID = -1907421238263653895L;
    private final List<Long> missingItems=new ArrayList<Long>(0);

    /**
     * 
     */
    public ItemNotFoundException() {
    }

    /**
     * @param message
     */
    public ItemNotFoundException(String message) {
        super(message);
    }

    /**
     * @param message
     */
    public ItemNotFoundException(List<Long> listOfItems) {
        super("Missing items");
        if(listOfItems!=null){
            for(Long i:listOfItems){
                if(i==null){
                    continue;
                }
                this.missingItems.add(i);
            }
        }
    }

    /**
     * @param throwable
     */
    public ItemNotFoundException(Throwable throwable) {
        super(throwable);
    }

    /**
     * @param message
     * @param throwable
     */
    public ItemNotFoundException(String message, Throwable throwable) {
        super(message, throwable);
    }

    /**
     * @return the missingItems
     */
    public List<Long> getMissingItems() {
        return this.missingItems;
    }
}
