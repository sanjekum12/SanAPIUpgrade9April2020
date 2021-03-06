public with sharing class INTF_IB_PopulateName 
{
	SVMXC.INTF_BuildSobjectFromKeyValue sobjectfromkevalue = new SVMXC.INTF_BuildSobjectFromKeyValue();
	public INTF_IB_PopulateName(){}
	
	public SVMXC.INTF_WebServicesDef.INTF_PageData populateName(SVMXC.INTF_WebServicesDef.INTF_TargetRecord sfmtargetrec)
	{
		system.debug('sfmtargetrec'+sfmtargetrec);
		SVMXC.INTF_WebServicesDef.INTF_PageData PageData = new SVMXC.INTF_WebServicesDef.INTF_PageData();
        String SourceId = '';
        Boolean IsValidate = true;
        SVMXC.INTF_WebServicesDef.INTF_TargetRecordObject HdrTargetRecordObject = new SVMXC.INTF_WebServicesDef.INTF_TargetRecordObject();//Second member of the INTF_TargetRecord Class
        if(sfmtargetrec.headerRecord != null)
            HdrTargetRecordObject = sfmtargetrec.headerRecord;
        system.debug('HdrTargetRecordObject'+HdrTargetRecordObject);
        String HeaderObjName = '';
        List<SVMXC.INTF_WebServicesDef.INTF_Record> HeaderRecord = new List<SVMXC.INTF_WebServicesDef.INTF_Record>();
        Sobject HdrSObject;
        //Get the Header SFM Records...
        if(HdrTargetRecordObject.objName != null)
            HeaderObjName = HdrTargetRecordObject.objName;  
        if(HdrTargetRecordObject.records.size() > 0)
            HeaderRecord = HdrTargetRecordObject.records;
        map<String,Sobject> HeaderSobjMap = new map<String,Sobject>();
        list<SVMXC.INTF_WebServicesDef.INTF_StringMap> HdrTargetRecordAsKeyValue = new list<SVMXC.INTF_WebServicesDef.INTF_StringMap>();
        if(HeaderRecord.size() > 0)
        {
            if(HeaderRecord[0].targetRecordAsKeyValue != null && HeaderRecord[0].targetRecordAsKeyValue.size() > 0 && HeaderObjName != null && HeaderObjName.length() > 0)
            {
                HdrTargetRecordAsKeyValue = HeaderRecord[0].targetRecordAsKeyValue;
                HeaderSobjMap = sobjectfromkevalue.BuildSobjectFromKeyValue(HeaderRecord[0].targetRecordAsKeyValue,HeaderObjName,null,null);        
            }
            if(HeaderRecord[0].sourceRecordId != null)
            	SourceId = HeaderRecord[0].sourceRecordId;
        }
        if(HeaderSobjMap.size() > 0)
        {
            HdrSObject = HeaderSobjMap.values();
        }
        system.debug('HdrSObject'+HdrSObject);  
        //Logic for populate name field from serial number
        SVMXC.COMM_Utils_ManageSettings settings = new SVMXC.COMM_Utils_ManageSettings();
        Map<String, String> AllSubModuleSettings = settings.SVMX_getSettingList('IPRD001'); 
    	String SetngForReqSN = AllSubModuleSettings.get('SET003'); //setting for Serial Number to be mandatory
        if(SourceId != null && SourceId.length() > 0)
        {
        	SVMXC__Installed_Product__c IB = [select id,SVMXC__Product__c from SVMXC__Installed_Product__c where Id =: SourceId];
        	if(IB != null && IB.SVMXC__Product__c != null && HdrSObject.get('SVMXC__Product__c') != null)
        	{
        		if(IB.SVMXC__Product__c == HdrSObject.get('SVMXC__Product__c'))
        		{
        			IsValidate = false;
        			PageData.response.message = system.label.SFM002_TAG042;
        		}	
        	}	
        }
        //SET003
        if(SetngForReqSN.toUpperCase() == 'TRUE' && HdrSObject.get('SVMXC__Serial_Lot_Number__c') == null)
        {
        	IsValidate = false;
        	PageData.response.message = system.label.SFM002_TAG028;
        }
        String SN = '';
        if(HdrSObject.get('SVMXC__Serial_Lot_Number__c') != null)
        	SN =  String.valueof(HdrSObject.get('SVMXC__Serial_Lot_Number__c'));
        system.debug('SerialNo'+SN);
        if(SN != null && SN.length() > 0)
        	HdrSObject.put('Name',SN);
        system.debug('HdrSObject'+HdrSObject);	
        map<String, Schema.SObjectField> FieldMap = Schema.SObjectType.SVMXC__Installed_Product__c.fields.getMap();
        list<String> FieldList = new list<String>();  
        if(FieldMap.size() > 0)
        {
        	for(String s : FieldMap.keyset())
        	{
        		FieldList.add(FieldMap.get(s).getDescribe().getName());
        	}
        }
        //Create a map of field/value1 
        map<String,String> fieldValue1 = new map<String,String>();  
        if(HdrTargetRecordAsKeyValue.size() > 0)
        {
        	for(Integer i = 0;i<HdrTargetRecordAsKeyValue.size();i++)
        	{
        		if(HdrTargetRecordAsKeyValue[i].value1 != null)
        			fieldValue1.put(HdrTargetRecordAsKeyValue[i].key,HdrTargetRecordAsKeyValue[i].value1);
        	}
        }
        //Create update key/value for the Header object
        list<SVMXC.INTF_WebServicesDef.INTF_StringMap> TargetRecordAsKeyValue = new list<SVMXC.INTF_WebServicesDef.INTF_StringMap>();
        if(FieldList.size() > 0 && HdrSObject != null)
        {
            for(Integer i = 0 ;i<FieldList.size();i++)
            {
                if(FieldList[i].toUpperCase() != 'ID')
                {
	                SVMXC.INTF_WebServicesDef.INTF_StringMap temp = new SVMXC.INTF_WebServicesDef.INTF_StringMap();
		            temp.key = FieldList[i];
		           	temp.value = String.valueof(HdrSObject.get(FieldList[i]));
		            if(fieldValue1.containskey(FieldList[i]))
		            	temp.value1 =  fieldValue1.get(FieldList[i]);
		            system.debug('Keyvalue'+temp.key+' '+temp.value);
		            TargetRecordAsKeyValue.add(temp);
                }    
            }
        }
        system.debug('TargetRecordAsKeyValue'+TargetRecordAsKeyValue);
        HeaderRecord[0].targetRecordAsKeyValue = null;
        HeaderRecord[0].targetRecordAsKeyValue = TargetRecordAsKeyValue;
        //Build page Data..
        SVMXC.INTF_buildPageData buildpagedata = new SVMXC.INTF_buildPageData();
        system.debug('sfmtargetrec'+sfmtargetrec);
        if(IsValidate == false)
        {
        	PageData.response.success = false;
        	pagedata.eventType = sfmtargetrec.eventType;
        	return PageData;
        }
        else
        {
        	system.debug('Entered...');
        	PageData = buildpagedata.INTF_buildPageData(sfmtargetrec);
        	system.debug('PageData'+PageData);
        	PageData.response.success = true;
        	return PageData;
        }	
	}
}