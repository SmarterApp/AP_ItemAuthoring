package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;

@Entity
@Table(name="item_interaction")
public class ItemInteraction implements Serializable {

	private static final long serialVersionUID = 1L;
	
    static public final int II_CHOICE = 1;
	static public final int II_TEXT = 2;
	static public final int II_EXT_TEXT = 3;

	@Id
	@Column(name="ii_id")
	private int id;
	
    @Basic
    @Column(name="i_id")
    private int itemId;
    
    @Basic
    @Column(name="ii_name")
    private String name;
    
	@Basic
	@Column(name="ii_type")
	private int type;
	
	@Basic
    @Column(name="ii_max_score")
    private int maxScore;
	
	@Basic
	@Column(name="ii_correct")
	private String correct;
	
	@Basic
	@Column(name="ii_attribute_list")
	private String attributes;
	
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

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getAttributes() {
        return attributes;
    }

    public void setAttributes(String attributes) {
        this.attributes = attributes;
    }

    public String getCorrect() {
        return correct;
    }

    public void setCorrect(String correct) {
        this.correct = correct;
    }

    public int getMaxScore() {
        return maxScore;
    }

    public void setMaxScore(int maxScore) {
        this.maxScore = maxScore;
    }

}
