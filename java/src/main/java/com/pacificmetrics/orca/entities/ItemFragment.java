package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;

@Entity
@Table(name="item_fragment")
@NamedQueries({
	@NamedQuery(name="itemFragmentsById", 
		    query="select if from ItemFragment if where if.itemId = :i_id")
})
public class ItemFragment implements Serializable {

	private static final long serialVersionUID = 1L;
	
	static public final int IF_STEM = 1;
	static public final int IF_CHOICE = 2;
	static public final int IF_PROMPT = 6;

	@Id
	@Column(name="if_id")
	private int id;
	
    @Basic
    @Column(name="i_id")
    private int itemId;
    
    @Basic
    @Column(name="ii_id")
    private int itemInteractionId;
    
	@Basic
	@Column(name="if_type")
	private int type;
	
	@Basic
    @Column(name="if_set_seq")
    private int matchSequence;
	
	@Basic
	@Column(name="if_seq")
	private int sequence;

    @Basic
    @Column(name = "if_identifier", length = 100)
    private String identifier;

	@Basic
	@Column(name="if_text", length=10000)
	private String text;

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public int getItemId() {
		return itemId;
	}

	public void setItemId(int itemId) {
		this.itemId = itemId;
	}

	public int getType() {
		return type;
	}

	public void setType(int type) {
		this.type = type;
	}

	public int getSequence() {
		return sequence;
	}

	public void setSequence(int sequence) {
		this.sequence = sequence;
	}

	public String getText() {
		return text;
	}

	public void setText(String text) {
		this.text = text;
	}

    public int getItemInteractionId() {
        return itemInteractionId;
    }

    public void setItemInteractionId(int itemInteractionId) {
        this.itemInteractionId = itemInteractionId;
    }

    public String getIdentifier() {
        return identifier;
    }

    public void setIdentifier(String identifier) {
        this.identifier = identifier;
    }

    public int getMatchSequence() {
        return matchSequence;
    }

    public void setMatchSequence(int matchSequence) {
        this.matchSequence = matchSequence;
    }
	
}
