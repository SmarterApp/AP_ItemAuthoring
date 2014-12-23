package com.pacificmetrics.orca.entities;

import java.io.Serializable;
import java.util.List;

import javax.persistence.Basic;
import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.OneToMany;
import javax.persistence.OrderBy;
import javax.persistence.Table;

@Entity
@Table(name="inclusion_order")
@NamedQueries({
	@NamedQuery(name="ioByItemId", 
		        query="select io from InclusionOrder io where io.itemId = :i_id"),
   	@NamedQuery(name="ioDeleteForItemId", 
                query="delete from InclusionOrder io where io.itemId = :i_id"),
    @NamedQuery(name="ioByPassageId", 
                query="select io from InclusionOrder io where io.passageId = :p_id"),
    @NamedQuery(name="ioDeleteForPassageId", 
                query="delete from InclusionOrder io where io.passageId = :p_id")
                
		        
})

public class InclusionOrder implements Serializable {

	private static final long serialVersionUID = 1L;
	
	static public final int T_BRAILLE_DEFAULT = 1; 
	static public final int T_TEXT_AUDIO_DEFAULT = 2; 
	static public final int T_TEXT_AUDIO_ON_DEMAND = 3;
	static public final int T_TEXT_GRAPHICS_DEFAULT = 4; 
	static public final int T_TEXT_GRAPHICS_ON_DEMAND = 5;
	static public final int T_GRAPHICS_ON_DEMAND = 6;
	static public final int T_NON_VISUAL_DEFAULT = 7; 

	static public final String[] TYPES = new String[] {"", "Braille : Default", 
													       "Spoken, Text Only : Default", 
													       "Spoken, Text Only : On Demand", 
		                                                   "Spoken, Text and Graphics : Default", 
		                                                   "Spoken, Text and Graphics : On Demand", 
		                                                   "Spoken, Graphics Only : On Demand", 
		                                                   "Spoken, Non-visual : Default"};
	
	@Id
    @GeneratedValue(strategy=GenerationType.IDENTITY)
	@Column(name="io_id")
	private int id;
	
    @Basic
    @Column(name="i_id")
    private long itemId;
    
    @Basic
    @Column(name="p_id")
    private int passageId;
    
	@Basic
	@Column(name="io_type")
	private int type;
	
	@OneToMany(fetch=FetchType.EAGER, cascade=CascadeType.PERSIST, mappedBy="inclusionOrder")
	@OrderBy("sequence")
	private List<InclusionOrderElement> elementList;

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public long getItemId() {
		return itemId;
	}

	public void setItemId(long itemId) {
		this.itemId = itemId;
	}

	public int getType() {
		return type;
	}

	public void setType(int type) {
		this.type = type;
	}

	public List<InclusionOrderElement> getElementList() {
		return elementList;
	}

	public void setElementList(List<InclusionOrderElement> elementList) {
		this.elementList = elementList;
	}

    public int getPassageId() {
        return passageId;
    }

    public void setPassageId(int passageId) {
        this.passageId = passageId;
    }
	
}
