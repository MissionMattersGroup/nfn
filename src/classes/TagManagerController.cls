public with sharing class TagManagerController {

    public final Tag__c tag { get; set; }
    public String parentId { get; set; }
    public String objName { get; set; }
    public String parentName {get; set; }
    public String filterString { get; set; }
    public Map<String, TempTag> masterTagMap { get; set; }
    public Map<String, Tag__c> existingTagMap { get; set; }
    public Map<String, Boolean> tagRenderedMap { get; set; }
    private String lookupObjectName { get; set; }

    public class TempTag {
        public Tag_Value__c tagValue { get; set; }
        public Boolean isChecked { get; set; }
        public Boolean isNew { get; set; }

        public TempTag(Tag_Value__c tv) {
            tagValue = tv;
            isChecked = false;
            isNew = true;
        }
    }

    public TagManagerController(ApexPages.StandardController std) {
        this.tag = (Tag__c)std.getRecord();
        parentId = ApexPages.CurrentPage().getParameters().get('parentId');
        objName = Id.valueOf(parentId).getSobjectType().getDescribe().getName();
        parentName = String.valueOf(Database.query('SELECT Id, Name FROM ' + objName + ' WHERE Id = \'' + parentId + '\'')[0].get('Name'));
        masterTagMap = new Map<String, TempTag>();
        existingTagMap = new Map<String, Tag__c>();
        tagRenderedMap = new Map<String, Boolean>();
        for(Tag_Value__c tag : [SELECT Id, Name FROM Tag_Value__c WHERE RecordType.Name = :ApexPages.CurrentPage().getParameters().get('rt')]) {
            TempTag tt = new TempTag(tag);
            masterTagMap.put(tag.Name, tt);
            tagRenderedMap.put(tag.Name, true);
        }
        updateTagMaps();
    }

    public void updateTagMaps() {
        lookupObjectName = objName.endswith('__c') ? objName : objName + '__c';
        String selectStarQuery = QueryUtility.getSelectStarQuery('Tag__c').replace('SELECT ', 'SELECT Tag_Name__r.Name, ');
        for(SObject so : Database.query(selectStarQuery + ' WHERE ' + lookupObjectName + ' = \'' + parentId + '\'')) {
            Tag__c tag = (Tag__c)so;
            existingTagMap.put(tag.Tag_Name__r.Name, tag);
            TempTag tt = masterTagMap.get(tag.Tag_Name__r.Name);
            tt.isNew = false;
            tt.isChecked = true;
            masterTagMap.put(tag.Tag_Name__r.Name, tt);
        }
    }

    public PageReference save() {
        List<Tag__c> insertTagList = new List<Tag__c>();
        List<Tag__c> deleteTagList = new List<Tag__c>();
        for(String tagName : masterTagMap.keySet()) {
            if(masterTagMap.get(tagName).isChecked && masterTagMap.get(tagName).isNew) {
                Tag__c newTag = new Tag__c(Tag_Name__c = masterTagMap.get(tagName).tagValue.Id);
                newTag.put(lookupObjectName, (Id)parentId);
                insertTagList.add(newTag);
            } else if(!masterTagMap.get(tagName).isChecked && !masterTagMap.get(tagName).isNew) {
                deleteTagList.add(existingTagMap.get(tagName));
            }
        }
        if(!insertTagList.isEmpty()) insert insertTagList;
        if(!deleteTagList.isEmpty()) Database.delete(deleteTagList, false);
        return new PageReference('/'+parentId);
    }

    public void clearFilter() {
        filterString = '';
        updateRenderedTagMap();
    }

    public void updateRenderedTagMap() {
        for(String tagName : tagRenderedMap.keySet()) {
            if(filterString.length() > 2) tagRenderedMap.put(tagName, tagName.containsIgnoreCase(filterString));
            else tagRenderedMap.put(tagName, true);
        }
    }
}
