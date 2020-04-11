global with sharing class TechnicalAttribute {

    public TechnicalAttribute() {

    }
    @RemoteAction
    global static String JsrGetMetadata(String requestStr){     
        TechnicalAttributeImpl taImpl = new TechnicalAttributeImpl();     
        return JSON.serialize(taImpl.getMetaData());
     }

    @RemoteAction
    global static String JsrGetAttributesTemplateInstanceForIB(String ibId){     
        TechnicalAttributeImpl taImpl = new TechnicalAttributeImpl();     
        return JSON.serialize(taImpl.getAttributesTemplateInstanceForIB(ibId));
     }

    @RemoteAction
    global static String JsrSaveTechnicalAttributeDetails(String request){     
        TechnicalAttributeImpl taImpl = new TechnicalAttributeImpl();     
        return JSON.serialize(taImpl.saveTechnicalAttributeDetails(request));
     }

}