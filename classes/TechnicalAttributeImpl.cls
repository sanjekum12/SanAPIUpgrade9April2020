public with sharing class TechnicalAttributeImpl {

    public Object getMetaData() {
        
        TechnicalAttributeUtils objUtils = new TechnicalAttributeUtils();   
        return objUtils.getMetaData();        
    }

    public Object getAttributesTemplateInstanceForIB(String ibId) {
        
        TechnicalAttributeUtils objUtils = new TechnicalAttributeUtils();   
        return objUtils.getAttributesTemplateInstanceForIB(ibId);        
    }

    public Object saveTechnicalAttributeDetails(String request) {
        
        TechnicalAttributeUtils objUtils = new TechnicalAttributeUtils();   
        return objUtils.saveTechnicalAttributeDetails(request);        
    }

}