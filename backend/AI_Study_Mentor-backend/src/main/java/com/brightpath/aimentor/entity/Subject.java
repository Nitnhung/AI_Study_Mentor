package com.brightpath.aimentor.entity;

import jakarta.persistence.*;

@Entity @Table(name = "subjects")
public class Subject {
    @Id @Column(length = 36) private String subjectId;
    @Column(unique = true, nullable = false, length = 100) private String subjectName;
    @Column(columnDefinition = "TEXT") private String description;

    public Subject() {}
    public Subject(String id, String name, String desc) {
        this.subjectId = id; this.subjectName = name; this.description = desc;
    }

    public String getSubjectId() { return subjectId; }
    public void setSubjectId(String v) { subjectId = v; }
    public String getSubjectName() { return subjectName; }
    public void setSubjectName(String v) { subjectName = v; }
    public String getDescription() { return description; }
    public void setDescription(String v) { description = v; }
}
