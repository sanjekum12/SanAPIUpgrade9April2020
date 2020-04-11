/*****************************************************************************
 *                       Copyright (C) 2019 ServiceMax, Inc
 *                               All rights reserved
 *
 *****************************************************************************/

/**
 * Service manager which has business logic for all the services, related to work order object, re-written for DCx
 * @author Vinay Vijay
 * @version 19.2000
 * @since 2019
 */
public with sharing class DCX_WOServiceManager {

    public static boolean allowtriggerExecution = true;
    
        /**************************************Pagination service for WO**************************************/
    
    public static workorderDCx retrieveWorkOrders(String viewId, Boolean isInitial, List<String> dispatchStatus, List<String> invisibleWorkOrderIds, String pageSize, String sortField, Boolean isAscending, String searchField, String searchFieldValue) {
// long t1 = DateTime.now().getTime();
// system.debug('Inside retrieveWorkOrders');
        String UserId = UserInfo.getUserId();
        Boolean hasCreatedBy,hasLastModifiedBy;
        system.debug('dispatchStatus ::'+dispatchStatus);
        List<DCON_Configuration_WS.SVMX_StringMap> views = new List<DCON_Configuration_WS.SVMX_StringMap>();
        hasCreatedBy = false;
        hasLastModifiedBy = false;
        //fetch the default views if any
        SVMXC.DCX_CommonServiceManager.UserSetting userSettings = SVMXC.DCX_SettingServiceManager.fetchUserSettings();
        if(viewId == null || viewId == '')
            viewId = userSettings.wo_defaultView;
        if(viewId != null && viewId !='' ) {
             String strPrefix  = Schema.SObjectType.SVMXC__ServiceMax_Processes__c.getKeyPrefix();
             system.debug('strPrefix'+strPrefix);
            if(strPrefix == viewId.substring(0,3)) // It is a Work Order View Id
            {
                 List<SVMXC__ServiceMax_Processes__c> viewRec = [Select Id from SVMXC__ServiceMax_Processes__c where Id = :viewId];
                system.debug('viewId :'+viewId +'::+++::'+viewRec);
                 if(viewRec.size() == 0){
                viewId = '';
            }
            }
        }

        
        List<string> lstSubModules = new List<string>{'DCON001'};
        Map<String,String> appSetting = COMM_Utils_ManageSettings.SVMX_getDCSetting(lstSubModules);

system.debug('APP SETTINGS: '+appSetting);      

        //fetch pageSize from app settings
        if(pageSize == null) {
            if(appSetting.containskey('DCON001_SET073') && appSetting.get('DCON001_SET073') != null) {
                Integer size = Integer.valueOf(appSetting.get('DCON001_SET073'));
                if(size < 200)
                    pageSize = '200';
                else 
                    pageSize = String.valueOf(size);
            }
            else {
                pageSize = '200';
            }
        }

        //fetch the default svmx setting for dispatch status if any
        //This is executed only for initial DCx launch  
        Boolean setSortField = false;  
        if(isInitial) {
            if(appSetting.containskey('DCON001_SET007') && appSetting.get('DCON001_SET007') != null) {
                String strDefaultStatus = appSetting.get('DCON001_SET007');
                dispatchStatus = strDefaultStatus.split(',');
                if(viewId != null) {
                    if(userSettings.wo_viewCounter != null && userSettings.wo_viewCounter.size() > 0){
                        for(DCX_CommonServiceManager.ViewCounter viewCon : userSettings.wo_viewCounter) {
                            if(viewCon.id == viewId) {
                                setSortField = true;
                                if(viewCon.column != null) {
                                    sortField = viewCon.column;
                                } else {
                                    sortField = 'Name';
                                }
                                if(viewCon.sortOrder != null) {
                                    if(viewCon.sortOrder.equalsIgnoreCase('asc')) {
                                        isAscending = true;
                                    } else {
                                        isAscending = false;
                                    }
                                } else {
                                    isAscending = true;
                                }
                            }
                        }
                    }
                }
                if(!setSortField) {
                    if(sortField != null) 
                        sortField = userSettings.wo_sortColumn;
                    if( userSettings.wo_sortOrder == 'asc')
                        isAscending = true;
                    else
                        isAscending = false;
                }
            }
            views = DCON_Retrieve_Views(UserId);
        }
                
        /* If no View Id is passed, set "My Work Orders" view as default */
        if(viewId == '' && invisibleWorkOrderIds == NULL) {
            List<DCON_Configuration_WS.SVMX_StringMap> viewList = new List<DCON_Configuration_WS.SVMX_StringMap>();
            viewList = DCON_Retrieve_Views(UserId);
            
            if(viewList[0] != NULL)
                viewId = viewList[0].Key;
        }
// long t2 = DateTime.now().getTime();
        SVMXC.COMM_Utils utils = new SVMXC.COMM_Utils(); 
        DCON_Utils dcUtils = new DCON_Utils();

        String WhereClause = '';
        String FirstWhereClause = '';
        String SecondWhereClause = '';
        String strPreFilterCriteria = '';
        String strOwnerShipType = '';
        String querySelect = ''; 
//        List<workorder_WPDCx> workorder_LWP = new List<workorder_WPDCx>();
        List<SVMXC__Service_Order__c> workorder_LO = new List<SVMXC__Service_Order__c>();
        List<String> refFields_L = new List<String>();
        List<String> dateTimeFields_L = new List<String>();
        List<String> dateFields_L = new List<String>();
        Map<String,String> replacementRef = new Map<String,String>();
        Map<String,String> replacementNameField = new Map<String,String>();
        Map<String, SObjectField> newSchemaFieldMap = new Map<String, SObjectField>();
// long t21 = DateTime.now().getTime();        
        Map<String, SObjectField> souObjfieldMap = Schema.SObjectType.SVMXC__Service_Order__c.fields.getMap(); // Get field definition map for work order
// long t22 = DateTime.now().getTime();
        //get wo fields configured in svmx settings       
        Set<string> setWorkOrderFields = getConfiguredWoUpdateFields();
// long t23 = DateTime.now().getTime();        
        //START: DNS-623
        //get the list of WO fields which are to be loaded instead of loading all WO fields
        Set<String> setWOFields = getWOFieldsToLoadInDCx(setWorkOrderFields, userSettings);
// long t24 = DateTime.now().getTime();        
        //get the list of fileds configured by user for a view in SFDC page under 'Dispatch Process -> Dispatch Console Views'
        if(viewId != '' && viewId != null) {
            List<SVMXC__ServiceMax_Config_Data__c> listConfViewFields = new List<SVMXC__ServiceMax_Config_Data__c>();
            listConfViewFields = [Select SVMXC__Field_Name__c from SVMXC__ServiceMax_Config_Data__c where SVMXC__Expression_Rule__c =: viewId and SVMXC__Expression_Type__c ='SRCH_Object_Fields'];//SDL-SVMX-FLS-NOT-ENFORCED-META-DATA
            for(SVMXC__ServiceMax_Config_Data__c objConf : listConfViewFields)
                setWOFields.add(objConf.SVMXC__Field_Name__c);
        }
// long t3 = DateTime.now().getTime();                    
// system.debug('decl: '+(t21-t2));
// system.debug('obj describe: '+(t22-t21));
// system.debug('getConfiguredWoUpdateFields: '+(t23-t22));
// system.debug('getWOFieldsToLoadInDCx: '+(t24-t23));
// system.debug('loop: '+(t3-t24));
//system.debug('--------------wo fields=default+user+svmx----------');
//for(String s : setWoFields)
//  system.debug(s);
    
        //Get only those WO fields which has to be populated, we can skip the rest
/*        for (String fieldKey : souObjfieldMap.keySet()) {
            String fieldName='';
            Schema.SObjectField fsObj = souObjfieldMap.get(fieldKey); 
            Schema.DescribeFieldResult f = fsObj.getDescribe();
            fieldName = f.getName();
            if(setWOFields.contains(fieldName))
                newSchemaFieldMap.put(fieldName, fsObj);
        }*/
//system.debug('----------newSchemaMap-------');
//for(String s:newSchemaFieldMap.keySet())
//  system.debug(s);
        for(String fieldName : setWoFields) {
            if(!fieldName.equalsIgnoreCase('id') && souObjfieldMap.containsKey(fieldName)) {
                Schema.SObjectField fsObj = souObjfieldMap.get(fieldName);
                newSchemaFieldMap.put(fieldName, fsObj);
            }
        }
// long t4 = DateTime.now().getTime();        
        DCON_Utils.referenceFields_WP reference_M = dcUtils.SVMX_getReferenceFields(newSchemaFieldMap,true);
        newSchemaFieldMap.clear();
        List<String> limitedFields_L = reference_M.allFields_L; //Get all fields list
        limitedFields_L.add('SVMXC__Violation_Status2__c');
        limitedFields_L.add('SVMXC__Violation_Message__c');
        for(String fld : limitedFields_L) {
            if(fld.equalsIgnoreCase('CreatedById'))
                hasCreatedBy = true;
            if(fld.equalsIgnoreCase('LastModifiedById'))
                hasLastModifiedBy = true;
        }
        if(hasCreatedBy)
            limitedFields_L.add('CreatedBy.Name');
        if(hasLastModifiedBy)
            limitedFields_L.add('LastModifiedBy.Name');
        Set<String> limitedFieldSet = new Set<String>();
        limitedFieldSet.addAll(limitedFields_L);
        limitedFields_L.clear();
        limitedFields_L.addAll(limitedFieldSet);
        limitedFieldSet.clear();
        //END: DNS-623
        refFields_L = reference_M.referenceFields_L; //Get the reference field list
        dateTimeFields_L = reference_M.dateTimeFields_L; //Get the dateTime field list
        dateFields_L = reference_M.dateFields_L; //Get the date field list
        replacementRef = reference_M.replacementReference_M;  //Get the replacement reference field map
        replacementNameField = reference_M.replacementField_M;  //Get the name field for reference map
        querySelect = utils.SVMX_getFieldNamesFromList(limitedFields_L); 
        
// long t5 = DateTime.now().getTime();
        // Build the Work Order query
        if(viewId != '' && viewId != null) {
            // Check if viewId is Owner Id / Queue Id or Work Order View Id
            String strPrefix  = Schema.SObjectType.SVMXC__ServiceMax_Processes__c.getKeyPrefix();
            if(strPrefix == viewId.substring(0,3)) {// It is a Work Order View Id
                list<SVMXC__ServiceMax_Processes__c> lstViews = new list<SVMXC__ServiceMax_Processes__c>();
                lstViews = [select Id, SVMXC__Name__c, SVMXC__Values__c, SVMXC__Ownership_Type__c, SVMXC__Parent_Object_Criteria__c from SVMXC__ServiceMax_Processes__c where id =: viewId];//SDL-SVMX-FLS-NOT-ENFORCED-META-DATA
                if(lstViews.size() > 0) {
                    list<SVMXC__ServiceMax_Config_Data__c> lstConfig = [Select Id, SVMXC__Field_Name__c  from 
                                                                        SVMXC__ServiceMax_Config_Data__c where 
                                                                        SVMXC__Expression_Rule__c = :lstViews[0].Id and 
                                                                        SVMXC__Expression_Type__c = 'SRCH_Object_Prefilter_Criteria'];
                    for(SVMXC__ServiceMax_Config_Data__c cData : lstConfig) {
                        if(!souObjfieldMap.containsKey(cData.SVMXC__Field_Name__c.toLowerCase())) {
                            throw new DCX_CommonServiceManager.DCxException('The field '+ cData.SVMXC__Field_Name__c + ' is deleted from the view. Please select a different view.');
                        }
                    }
                    if(lstViews[0].SVMXC__Parent_Object_Criteria__c != null)
                        strPreFilterCriteria = lstViews[0].SVMXC__Parent_Object_Criteria__c;
                    if(lstViews[0].SVMXC__Ownership_Type__c != null)
                        strOwnerShipType = lstViews[0].SVMXC__Ownership_Type__c;    
                }
                else {
                    throw new DCX_CommonServiceManager.DCxException(system.label.DCON001_TAG328);
                }

                if(strPreFilterCriteria != null && strPreFilterCriteria.length() > 0) {
                    strPreFilterCriteria = strPreFilterCriteria.replace(' ','+');
                    FirstWhereClause = strPreFilterCriteria;
                }

                if(strOwnerShipType != null && strOwnerShipType.length() > 0 && strOwnerShipType == 'User\'s Records') {
                    String strUserId = Userinfo.getUserId();
                    if(FirstWhereClause != null && FirstWhereClause.length() > 0)
                        FirstWhereClause = ' ( '+FirstWhereClause+ ' ) '+' AND OwnerId = \''+strUserId+'\'';
                    else 
                        FirstWhereClause += 'OwnerId = \''+strUserId+'\'';
                }
            }
            else { // It is Owner Id or Queue Id
            system.debug('OwnerId');
               FirstWhereClause = 'OwnerId = \''+ViewId+'\'';
            }  
            FirstWhereClause = FirstWhereClause.replace('%','%25'); 
            FirstWhereClause = FirstWhereClause.replace('\'','%27');
        }
// long t6 = DateTime.now().getTime();
        if(invisibleWorkOrderIds != NULL && invisibleWorkOrderIds.size() > 0) {
            String InVal = dcUtils.SVMX_get_ListOfValues(invisibleWorkOrderIds);
            if(FirstWhereClause != '')
                FirstWhereClause = ' ( '+FirstWhereClause+' ) '+' AND ';
            FirstWhereClause += 'Id IN :invisibleWorkOrderIds';
        }
system.debug('FirstWhereClause : '+FirstWhereClause);
system.debug('dispatchStatus : '+dispatchStatus);
        if(dispatchStatus != null && dispatchStatus.size() > 0 && dispatchStatus[0].toUpperCase() != 'ALL') {
            //Adding conditions based on the dispatchStatus
            
            if(FirstWhereClause != null && FirstWhereClause.length() > 0) {
                for(String ds: dispatchStatus) {
                    if(SecondWhereClause == '')
                        SecondWhereClause += ' AND ( ';
                    else if(ds.toUpperCase()=='NEW' || ds.toUpperCase()=='QUEUED' || ds.toUpperCase()=='ASSIGNED')
                        SecondWhereClause += ' OR ';
                    if(ds.toUpperCase()=='NEW')
                        SecondWhereClause += ' ( SVMXC__Group_Member__c = NULL and SVMXC__Service_Group__c = NULL ) ';
                    else if(ds.toUpperCase()=='QUEUED')
                        SecondWhereClause += ' ( SVMXC__Group_Member__c = NULL and SVMXC__Service_Group__c != NULL ) ';
                    else if(ds.toUpperCase()=='ASSIGNED')
                        SecondWhereClause += ' ( SVMXC__Group_Member__c != NULL) ';//Apurva :Defect - 011238
                }
                SecondWhereClause += ' ) ';
            }      
            else {
                for(String ds: dispatchStatus) {
                    if((SecondWhereClause != null && SecondWhereClause.length() > 0) && (ds.toUpperCase()=='NEW' || ds.toUpperCase()=='QUEUED' || ds.toUpperCase()=='ASSIGNED'))
                        SecondWhereClause += ' OR ';
                    if(ds.toUpperCase()=='NEW')
                        SecondWhereClause += ' ( SVMXC__Group_Member__c = NULL and SVMXC__Service_Group__c = NULL ) ';
                    else if(ds.toUpperCase()=='QUEUED')
                        SecondWhereClause += ' ( SVMXC__Group_Member__c = NULL and SVMXC__Service_Group__c != NULL ) ';
                    else if(ds.toUpperCase()=='ASSIGNED')
                        SecondWhereClause += ' ( SVMXC__Group_Member__c != NULL ) ';  //Apurva :Defect - 011238  
                }
            }              
        }

        if(FirstWhereClause != null && FirstWhereClause.length() > 0) {
            if(SecondWhereClause != null && SecondWhereClause.length() > 0)
                WhereClause = ' ( '+FirstWhereClause+' ) ' + SecondWhereClause;
            else
                WhereClause = FirstWhereClause;
        }
        else        {
            WhereClause = SecondWhereClause;
        }
// long t7 = DateTime.now().getTime();        
        //soql generation for search filter
       
        if(searchField != null && searchField.length() > 0 && searchFieldValue != null && searchFieldValue.length() > 0 ) {
            if(WhereClause != null && WhereClause.length() > 0) {
                 system.debug('searchField  : '+searchField);
        system.debug('searchFieldValue  : '+searchFieldValue);
         system.debug('WhereClause  : '+WhereClause);
                WhereClause = '('+WhereClause+')';
                WhereClause += ' AND' + buildSearchClause(searchField,searchFieldValue);
            }
            else {
                WhereClause = buildSearchClause(searchField,searchFieldValue);              
            }
        }
// long t8 = DateTime.now().getTime();        
        String orderClause = '';
        //soql generation for sort order
        if(sortField != null && sortField.length() > 0) {
            orderClause = ' ORDER BY '+ sortField + ' ';
            if(!isAscending) {
                if(appSetting.containskey('DCON001_SET031') && appSetting.get('DCON001_SET031') != null) {
                    orderClause += 'DESC NULLS ' + appSetting.get('DCON001_SET031');
                } else {
                    orderClause += 'DESC NULLS LAST';    
                }
            }
            else {
                if(appSetting.containskey('DCON001_SET030') && appSetting.get('DCON001_SET030') != null) {
                    orderClause += 'ASC NULLS ' + appSetting.get('DCON001_SET030');
                } else {
                    orderClause += 'ASC NULLS FIRST';  
                }
            }
        }
        //sort by wo id by default, if no sort field is mentioned
        else {
            orderClause = ' ORDER BY Name';
        }
        
        String strQuery = '';

        if(WhereClause != null && WhereClause.length() > 0) //string.escapeSingleQuotes(
            strQuery = 'SELECT ID,' + querySelect + ' FROM SVMXC__Service_Order__c WHERE ' + WhereClause;
        else
            strQuery = 'SELECT ID,' + querySelect + ' FROM SVMXC__Service_Order__c';

        if(orderClause != null & orderClause.length() > 0) {
            strQuery += orderClause;
        }
// long t9 = DateTime.now().getTime();        
system.debug('WO Query: '+strQuery);
        //replace whitespace with plus sign
        strQuery = substituteQueryWhitespace(strQuery);
// long t10 = DateTime.now().getTime();        
system.debug('WO Query for Rest API: '+strQuery);       
system.debug('pageSize: '+pageSize);
        //call the sfdc query rest api to get the paginated results
        workorderDCx_INT wowp ;
        if(!Test.isRunningTest()){

         wowp = doGet(strQuery, pageSize,false);
        }
        Long dbsyncTime = DateTime.Now().getTime();
// long t11 = DateTime.now().getTime();        
/*        workorder_WPDCx workorder_WPDCx;
        List<workorderSpecialFields_WPDCx> specialFields_LWP;
system.debug('----------post processing---------');             
        for(SVMXC__Service_Order__c wo: wowp.records) {
            specialFields_LWP = new List<workorderSpecialFields_WPDCx>();
system.debug('wo: '+wo.NAME);
            
            for(String s : refFields_L){
system.debug('refFields_L: '+s);
                workorderSpecialFields_WPDCx tRef;
                Sobject ref_TO = wo.getSobject(replacementRef.get(s));
system.debug('replacementRef.get(s): '+replacementRef.get(s));
                if(ref_TO!=NULL){
system.debug('ref_TO: '+ref_TO.get(replacementNameField.get(s)));
                    tRef = new workorderSpecialFields_WPDCx(s, String.valueof(ref_TO.get(replacementNameField.get(s))) );
                    specialFields_LWP.add(tRef);
                }
            }
            
            for(String s : dateTimeFields_L){
system.debug('dateTimeFields_L: '+s);
                if(wo.get(s) != NULL){
system.debug(logginglevel.warn,'WO datetime value'+wo.get(s));
system.debug(logginglevel.warn,'WO datetime value with format'+((Datetime)(wo.get(s))).format());
                    workorderSpecialFields_WPDCx tDateTime = new workorderSpecialFields_WPDCx(s, ((Datetime)(wo.get(s))).format() );
                    specialFields_LWP.add(tDateTime);
                }
            }
            for(String s : dateFields_L){
                if(wo.get(s) != NULL){
system.debug('dateFields_L: '+s);
                    workorderSpecialFields_WPDCx tDate = new workorderSpecialFields_WPDCx(s, Date.valueof(String.valueof(wo.get(s))).format() );
                    specialFields_LWP.add(tDate);
                }
            }

            workorder_WPDCx = new workorder_WPDCx(wo, specialFields_LWP);
            workorder_LWP.add(workorder_WPDCx);
        }
        
        if(workorder_LWP != null && workorder_LWP.size() > 0 )
            workorder_LWP.get(workorder_LWP.size()-1).lastSyncedTime = DateTime.now().getTime();
        else{
            workorder_WPDCx obj = new workorder_WPDCx();
            List<workorderSpecialFields_WPDCx> FieldUpdateWrapper = new List<workorderSpecialFields_WPDCx> ();
            if(setWorkOrderFields != null && setWorkOrderFields.size()>0) {
                if(invisibleWorkOrderIds != NULL && invisibleWorkOrderIds.size() > 0)
                    obj = getFieldUpdateWrapper(setWorkOrderFields, invisibleWorkOrderIds);
            }
            //DNS-1493
            if(obj != null) {   
                obj.lastSyncedTime = DateTime.now().getTime();
            }
            else {
                obj = new workorder_WPDCx();
                obj.lastSyncedTime = DateTime.now().getTime();  
            }       
            workorder_LWP.add(obj);
        }
*/  if(!Test.isRunningTest()){
        LocalTimeZone localTz = new LocalTimeZone(UserInfo.getTimeZone().getDisplayName(),UserInfo.getTimeZone().getID(),UserInfo.getLocale(),UserInfo.getLanguage());
        //create the workorderDCx to be returned with metadata
        workorderDCx woData = new workorderDCx(wowp.totalSize,wowp.done,wowp.nextRecordsUrl,dbsyncTime,wowp.records,isInitial?localTz:null,isInitial?viewId:null,isInitial?views:null,strQuery);
       // workorderDCx woData = new workorderDCx(wowp.totalSize,wowp.done,wowp.nextRecordsUrl,dbsyncTime,wowp.records,isInitial?userSettings:null,isInitial?localTz:null,isInitial?viewId:null,isInitial?views:null,isInitial?appSetting:null,strQuery);

// long t12 = DateTime.now().getTime();
// system.debug('fetch view: '+(t2-t1));
// system.debug('fetch list of configured fields for the view: '+(t3-t2));
// system.debug('fetch wo fields that have to be populated: '+(t4-t3));
// system.debug('fetch reference fields: '+(t5-t4));
// system.debug('where clause without invisible wo: '+(t6-t5));
// system.debug('where clause with invisible wo: '+(t7-t6));
// system.debug('filter clause: '+(t8-t7));
// system.debug('order clause: '+(t9-t8));
// system.debug('Whitespace encoding: '+(t10-t9));
// system.debug('SFDC Query API: '+(t11-t10));
// system.debug('Timestamping: '+(t12-t11));
// system.debug('total time: '+(t12-t1));
        return woData;
}
else{
    return null;
}
    }
    
        private static String buildSearchClause(String searchField, String searchFieldValue) {
        
        String expression = '';
    String searchStr;
        //expression will be '%value%' for String... datatype
        //it will be %value% for Integer, Boolean... datatype
        SObjectType r = ((SObject)(Type.forName('Schema.SVMXC__Service_Order__c').newInstance())).getSObjectType();
        DescribeSObjectResult d = r.getDescribe();
        Schema.SObjectField obj;
        Schema.DisplayType typ;
        Schema.Describesobjectresult lookUpObj;
        Map<String, Schema.SObjectField> fieldMap = d.fields.getMap();
        if(searchField.containsIgnoreCase('__r.')) {
            Schema.DescribeFieldResult f = fieldMap.get(searchField.substringBefore('__r.')+'__c').getDescribe();
            for(Schema.SObjectType reference : f.getReferenceTo()) {
                lookUpObj = reference.getDescribe();
            }
            typ = lookUpObj.fields.getMap().get(searchField.substringAfter('__r.')).getDescribe().getType();
        } else {
            if(searchField.contains('.Name')) {
                obj = fieldMap.get('Name');
                typ = obj.getDescribe().getType();
            } else {
                obj = fieldMap.get(searchField);
                typ = obj.getDescribe().getType();
            }
        }
        String typStr = String.valueOf(typ);
system.debug('TYPEEEE: '+typStr);
        if(typStr.equalsIgnoreCase('Boolean') || typStr.equalsIgnoreCase('Date') || typStr.equalsIgnoreCase('Double') || typStr.equalsIgnoreCase('Integer') || typStr.equalsIgnoreCase('Long')) {
            expression =  searchFieldValue;
            searchStr = ' ' + searchField + ' = ' + expression;
        }
        else {
            expression = '%27' + '%25' + searchFieldValue + '%25' + '%27'; //encoding single quote and percent sign
        searchStr = ' ' + searchField + ' LIKE '+expression;
        }
        
        return searchStr;
    }
    
    private static workorderDCx_INT doGet(String query, String pageSize,boolean isWorkorser)  {
        String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
        String url =  salesforceHost + '/services/data/v43.0/query?q=' + query;
                
        HttpRequest req = new HttpRequest();
                    
        req.setMethod('GET');
        req.setEndpoint(url);
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Sforce-Query-Options', 'batchSize=' + pageSize);
                    
        Http http = new Http();
          
        HTTPResponse res = http.send(req);
        system.debug('Query Rest API Results: '+res.getBody());
        
        workorderDCx_INT wowp = (workorderDCx_INT)JSON.deserialize(res.getBody(), workorderDCx_INT.class);
system.debug('totalSize::: '+wowp.totalSize);                   
system.debug('done::: '+wowp.done);                 
system.debug('nextRecordsUrl::: '+wowp.nextRecordsUrl);                 
system.debug('records::: '+wowp.records.size());                    
        return wowp;
    }
        
    private static Set<String> getWOFieldsToLoadInDCx(Set<string> setWorkOrderFields, SVMXC.DCX_CommonServiceManager.UserSetting userSettings) {
        //1. Add default wo fields to load
        Set<String> strWorkOrderFields = DCX_Utils.wodefaultFields();
try {
        
        //2. Add all the wo fields that are configured by the user, that are used in wo rules, 
        //that are used in technician rules and that are used in keywords
        if(userSettings.wo_grid_conf_fields != null && userSettings.wo_grid_conf_fields.size() > 0) {
            strWorkOrderFields.addAll(userSettings.wo_grid_conf_fields);
        }
        if(userSettings.wo_grid_col_fields != null && userSettings.wo_grid_col_fields.size() > 0) {
            strWorkOrderFields.addAll(userSettings.wo_grid_col_fields);
        }
} catch(Exception e) {
system.debug('===================>'+e.getStackTraceString());
}
        
        //3. add work order fields from svmx settings
        strWorkOrderFields.addall(setWorkOrderFields);
        
        return strWorkOrderFields;
    }
    
    //replace whitespace with plus sign
    private static String substituteQueryWhitespace(String query) {
        //replace whitespaces that is not within single quotes with +
        //regex reference - https://stackabuse.com/regex-splitting-by-character-unless-in-quotes/
        // actual expression is \\s+(?=([^\']*\'[^\']*\')*[^\']*$)
        //below \s has been escaped with \\s
        String regex = '\\s+(?=([^\']*\'[^\']*\')*[^\']*$)';
        query = query.replaceAll(regex,'\\+');
        system.debug('Query Rest API SOQL: '+query);
        return query;
    }
    
    private static Set<String> getConfiguredWoUpdateFields() {
        Set<String> flds = new Set<String>();
        //COMM_Utils_ManageSettings util = new COMM_Utils_ManageSettings();
        Map<String, String> fldMap = COMM_Utils_ManageSettings.SVMX_getuniqueSettingValueRange('DCON001','SET038','SET047',null);
        
        for(String fld : fldMap.values()) {
            if(!fld.contains('Event.')) {
                flds.add(fld);
            }
        }
        
        return flds;
    }

/*    
    private static workorder_WPDCx getFieldUpdateWrapper(set<string> setWorkOrderFields, List<String> workorderIds) 
    {
        SVMXC.COMM_Utils utils = new SVMXC.COMM_Utils(); 
        list<string> lstWorkOrderFields = new list<string>(setWorkOrderFields);
        workorder_WPDCx WO_WP; 
        string strFieldUpdateFields  = utils.SVMX_getFieldNamesFromList(lstWorkOrderFields); 
        Map<String, SObjectField> souObjfieldMap = Schema.SObjectType.SVMXC__Service_Order__c.fields.getMap(); 

        List<String> refFields_L = new List<String>();
        List<String> dateTimeFields_L = new List<String>();
        List<String> dateFields_L = new List<String>();
        Map<String,String> replacementRef = new Map<String,String>();
        Map<String,String> replacementNameField = new Map<String,String>();
        Map<String, SObjectField> newSchemaFieldMap = new Map<String, SObjectField>();
        for (String fieldKey : souObjfieldMap.keySet()) 
        {
            String fieldName='';
            Schema.SObjectField fsObj = souObjfieldMap.get(fieldKey); 
            Schema.DescribeFieldResult f = fsObj.getDescribe();
            fieldName = f.getName();
            if(setWorkOrderFields.contains(fieldName))
                newSchemaFieldMap.put(fieldName, fsObj);
        }
        DCON_Utils dcUtils = new DCON_Utils(); 
        DCON_Utils.referenceFields_WP reference_M = dcUtils.SVMX_getReferenceFields(newSchemaFieldMap,true);
        newSchemaFieldMap.clear();
        souObjfieldMap.clear();
        List<String> limitedFields_L = reference_M.allFields_L; //Get all fields list
        //END: DNS-623
        refFields_L = reference_M.referenceFields_L; //Get the reference field list
        dateTimeFields_L = reference_M.dateTimeFields_L; //Get the dateTime field list
        dateFields_L = reference_M.dateFields_L; //Get the date field list
        replacementRef = reference_M.replacementReference_M;  //Get the replacement reference field map
        replacementNameField = reference_M.replacementField_M;  //Get the name field for reference map
        string queryWO = 'Select '+strFieldUpdateFields+' From SVMXC__Service_Order__c where Id IN :workorderIds';
        
        System.debug('setWorkOrderFields: '+setWorkOrderFields);
        System.debug('queryWO: '+queryWO);
        for(SVMXC__Service_Order__c wo: Database.query(queryWO))
        {
            System.debug('+++++ Enetered  ');
            List<workorderSpecialFields_WPDCx> FieldUpdateWrapper = new List<workorderSpecialFields_WPDCx>();
            
            for(String s : refFields_L)
            {
                workorderSpecialFields_WPDCx tRef;
                
                Sobject ref_TO = wo.getSobject(replacementRef.get(s));
                if(ref_TO!=NULL)
                {
                    tRef = new workorderSpecialFields_WPDCx(s, String.valueof(ref_TO.get(replacementNameField.get(s))) );
                    FieldUpdateWrapper.add(tRef);
                    if(setWorkOrderFields.contains(s))
                        setWorkOrderFields.remove(s);
                }
            }
            
            for(String s : dateTimeFields_L)
            {
                if(wo.get(s) != NULL)
                {
                    system.debug(logginglevel.warn,'WO datetime value'+wo.get(s));
                    workorderSpecialFields_WPDCx tDateTime = new workorderSpecialFields_WPDCx(s, ((Datetime)(wo.get(s))).format() );
                    FieldUpdateWrapper.add(tDateTime);
                    if(setWorkOrderFields.contains(s))
                        setWorkOrderFields.remove(s);
                }
            }
            for(String s : dateFields_L){
                if(wo.get(s) != NULL)
                {
                    workorderSpecialFields_WPDCx tDate = new workorderSpecialFields_WPDCx(s, Date.valueof(String.valueof(wo.get(s))).format() );
                    FieldUpdateWrapper.add(tDate);
                    if(setWorkOrderFields.contains(s))
                        setWorkOrderFields.remove(s);
                }
            }
            if(!setWorkOrderFields.isempty() && setWorkOrderFields.size()>0)
            {
                for(string s :new list<string>(setWorkOrderFields))
                {
                    workorderSpecialFields_WPDCx WOField = new workorderSpecialFields_WPDCx(s, String.valueof(wo.get(s)));
                    FieldUpdateWrapper.add(WOField);
                }
            }
            WO_WP = new workorder_WPDCx(null,FieldUpdateWrapper);
        }       
            System.debug('WO_WP: '+WO_WP);
        return WO_WP;
    }
*/
    //This method returns the name of Work Order views (queues and personal) to which the login user has access to.
    /*public static List<DCON_Configuration_WS.SVMX_StringMap> DCON_Retrieve_Views(String UserId)
    {
        List<SVMXC.DCON_Configuration_WS.SVMX_StringMap> ViewList = new List<SVMXC.DCON_Configuration_WS.SVMX_StringMap>();
        SVMXC.DCON_Configuration_WS.SVMX_StringMap view;
        set<String> UserOrGroupId = new set<String>();
        set<String> GroupIds = new set<String>();
        set<Id> setUniqueGroupId = new set<Id>();
        view = new SVMXC.DCON_Configuration_WS.SVMX_StringMap(UserId, 'TAG194');
        ViewList.add(view);
        String ObjectName ='SVMXC__Service_Order__c';
        try
        {
            for(QueueSObject q:[SELECT QueueId FROM QueueSObject WHERE SobjectType  = :ObjectName Order By Queue.Name]){ 
                GroupIds.add(q.QueueId);
            }
            UserOrGroupId.add(UserId);

            for(GroupMember q:[SELECT GroupId FROM GroupMember WHERE UserOrGroupId IN :UserOrGroupId])
            {
                UserOrGroupId.add(q.GroupId);
            }

            for(Group r : [SELECT Id,Name,RelatedId,Type FROM Group where RelatedId =: userinfo.getUserRoleId() and 
                           (Type = 'Role' Or Type = 'RoleAndSubordinates')]){
                UserOrGroupId.add(r.id);
                system.debug('Roles'+r);
            }

            for(GroupMember q:[SELECT GroupId,Group.Name FROM GroupMember WHERE UserOrGroupId IN :UserOrGroupId AND GroupId IN :GroupIds])
            {
                if(!setUniqueGroupId.contains(q.GroupId)){
                    view = new SVMXC.DCON_Configuration_WS.SVMX_StringMap(q.GroupId, q.Group.Name);
                    view.woViewType = 'QUEUE';
                    ViewList.add(view);
                    setUniqueGroupId.add(q.GroupId);
                }   
            }
            system.debug('ViewList'+ViewList.size()+ViewList);
            SVMXC.INTF_WebServicesDef.INTF_Request request = new SVMXC.INTF_WebServicesDef.INTF_Request();
            SVMXC.INTF_WebServicesDef.INTF_Response response = new SVMXC.INTF_WebServicesDef.INTF_Response();
            list<SVMXC.INTF_WebServicesDef.INTF_StringListMap> lstStringListMap = new list<SVMXC.INTF_WebServicesDef.INTF_StringListMap>();
            SVMXC.INTF_WebServicesDef.INTF_StringListMap stringListMap = new SVMXC.INTF_WebServicesDef.INTF_StringListMap();
            stringListMap.key = 'ISCALLEDFROMDC';
            lstStringListMap.add(stringListMap);
            SVMXC.INTF_WebServicesDef.INTF_StringListMap stringListMap1 = new SVMXC.INTF_WebServicesDef.INTF_StringListMap();
            stringListMap1.key = 'USERID';
            stringListMap1.valueList.add(UserId);
            lstStringListMap.add(stringListMap1);
            SVMXC.INTF_WebServicesDef.INTF_StringListMap stringListMap2 = new SVMXC.INTF_WebServicesDef.INTF_StringListMap();
            stringListMap2.key = 'OBJECTNAME';
            stringListMap2.valueList.add('SVMXC__Service_Order__c');
            lstStringListMap.add(stringListMap2);
            SVMXC.INTF_WebServicesDef.INTF_StringListMap stringListMap3 = new SVMXC.INTF_WebServicesDef.INTF_StringListMap();
            stringListMap3.key = 'VIEWFOR';
            stringListMap3.valueList.add('Grid');
            stringListMap3.valueList.add('Grid And Map');
            lstStringListMap.add(stringListMap3);
            request.stringListMap = lstStringListMap;
            SVMXC.INTF_CustomViewUtils customUtils = new SVMXC.INTF_CustomViewUtils();
            response = customUtils.getViewDefinition(request);

            if(response != null && response.stringMap != null && response.stringMap.size() > 0)
            {
                for(Integer i = 0;i<response.stringMap.size();i++)
                {
                    view = new SVMXC.DCON_Configuration_WS.SVMX_StringMap(response.stringMap[i].value1, response.stringMap[i].value);
                    view.woViewType = 'VIEW';
                    view.columnInfo = response.stringMap[i].type;
                    ViewList.add(view);
                }
            }
        }
        catch(Exception ex)
        {
            throw new DCX_CommonServiceManager.DCxException(ex);
        }
        system.debug('ViewList'+ViewList);
        return ViewList;
    }
*/
    public static List<DCON_Configuration_WS.SVMX_StringMap> DCON_Retrieve_Views(String UserId)
    {
        List<SVMXC.DCON_Configuration_WS.SVMX_StringMap> ViewList = new List<SVMXC.DCON_Configuration_WS.SVMX_StringMap>();
        SVMXC.DCON_Configuration_WS.SVMX_StringMap view;
        set<String> GroupIds = new set<String>();
        set<Id> setUniqueGroupId = new set<Id>();
        view = new SVMXC.DCON_Configuration_WS.SVMX_StringMap(UserId, 'TAG194');
        ViewList.add(view);
        String ObjectName ='SVMXC__Service_Order__c';
        try
        {
            for(QueueSObject q:[SELECT QueueId FROM QueueSObject WHERE SobjectType  = :ObjectName 
                                Order By Queue.Name]){ 
                GroupIds.add(q.QueueId);
            }
            
            for(GroupMember q:[SELECT GroupId,Group.Name FROM GroupMember WHERE 
                               ((Group.RelatedId = :userinfo.getUserRoleId() 
                               and (Group.Type = 'Role' or Group.Type = 'RoleAndSubordinates')) 
                               OR UserOrGroupId = :userinfo.getUserId()) AND GroupId IN :GroupIds])
            {
                if(!setUniqueGroupId.contains(q.GroupId)){
                    view = new SVMXC.DCON_Configuration_WS.SVMX_StringMap(q.GroupId, q.Group.Name);
                    view.woViewType = 'QUEUE';
                    ViewList.add(view);
                    setUniqueGroupId.add(q.GroupId);
                }   
            }
            system.debug('ViewList'+ViewList.size()+ViewList);
            SVMXC.INTF_WebServicesDef.INTF_Request request = new SVMXC.INTF_WebServicesDef.INTF_Request();
            SVMXC.INTF_WebServicesDef.INTF_Response response = new SVMXC.INTF_WebServicesDef.INTF_Response();
            list<SVMXC.INTF_WebServicesDef.INTF_StringListMap> lstStringListMap = new list<SVMXC.INTF_WebServicesDef.INTF_StringListMap>();
            SVMXC.INTF_WebServicesDef.INTF_StringListMap stringListMap = new SVMXC.INTF_WebServicesDef.INTF_StringListMap();
            stringListMap.key = 'ISCALLEDFROMDC';
            lstStringListMap.add(stringListMap);
            SVMXC.INTF_WebServicesDef.INTF_StringListMap stringListMap1 = new SVMXC.INTF_WebServicesDef.INTF_StringListMap();
            stringListMap1.key = 'USERID';
            stringListMap1.valueList.add(UserId);
            lstStringListMap.add(stringListMap1);
            SVMXC.INTF_WebServicesDef.INTF_StringListMap stringListMap2 = new SVMXC.INTF_WebServicesDef.INTF_StringListMap();
            stringListMap2.key = 'OBJECTNAME';
            stringListMap2.valueList.add('SVMXC__Service_Order__c');
            lstStringListMap.add(stringListMap2);
            SVMXC.INTF_WebServicesDef.INTF_StringListMap stringListMap3 = new SVMXC.INTF_WebServicesDef.INTF_StringListMap();
            stringListMap3.key = 'VIEWFOR';
            stringListMap3.valueList.add('Grid');
            stringListMap3.valueList.add('Grid And Map');
            lstStringListMap.add(stringListMap3);
            request.stringListMap = lstStringListMap;
            SVMXC.INTF_CustomViewUtils customUtils = new SVMXC.INTF_CustomViewUtils();
            response = customUtils.getViewDefinition(request);

            if(response != null && response.stringMap != null && response.stringMap.size() > 0)
            {
                for(Integer i = 0;i<response.stringMap.size();i++)
                {
                    view = new SVMXC.DCON_Configuration_WS.SVMX_StringMap(response.stringMap[i].value1, response.stringMap[i].value);
                    view.woViewType = 'VIEW';
                    view.columnInfo = response.stringMap[i].type;
                    ViewList.add(view);
                }
            }
        }
        catch(Exception ex)
        {
            throw new DCX_CommonServiceManager.DCxException(ex);
        }
        system.debug('ViewList'+ViewList);
        return ViewList;
    }

    public class workorderDCx_INT{
        public Integer totalSize {get; set;}
        public Boolean done {get; set;}
        public String nextRecordsUrl {get; set;}
        public List<SVMXC__Service_Order__c> records {get; set;}
        public workorderDCx_INT(Integer size, Boolean isDone, String nextPageUrl, List<SVMXC__Service_Order__c> woList){
            this.totalSize = size;
            this.done = isDone;
            this.nextRecordsUrl = nextPageUrl;
            this.records = woList;
        }
    }
    
    public class workorderDCx{
        public String totalSize {get; set;}
        public String done {get; set;}
        public String nextRecordsUrl {get; set;}
        public String dbSyncTime {get; set;}
        public LocalTimeZone localTimeZone {get; set;}
        public String viewId {get; set;}
        public String soql {get; set;}
        public List<DCON_Configuration_WS.SVMX_StringMap> views {get; set;}
        public List<SVMXC__Service_Order__c> records {get; set;}
      //  public SVMXC.DCX_CommonServiceManager.UserSetting userSettings {get; set;}
      //  public Map<String, String> appSettings {get; set;}
        public workorderDCx(Integer size, Boolean isDone, String nextPageUrl, Long dbsyncTime, List<SVMXC__Service_Order__c> woList,  LocalTimeZone localDT, String view, List<DCON_Configuration_WS.SVMX_StringMap> viewList,  String sql){
         //public workorderDCx(Integer size, Boolean isDone, String nextPageUrl, Long dbsyncTime, List<SVMXC__Service_Order__c> woList, SVMXC.DCX_CommonServiceManager.UserSetting settings, LocalTimeZone localDT, String view, List<DCON_Configuration_WS.SVMX_StringMap> viewList, Map<String, String> appset, String sql){

            this.totalSize = String.valueOf(size);
            this.done = String.valueOf(isDone);
            this.nextRecordsUrl = nextPageUrl;
            this.dbSyncTime = String.valueOf(dbsyncTime);
            this.records = woList;
         //   userSettings = settings;
         //   appSettings = appset;
            localTimeZone = localDT;
            viewId = view;
            views = viewList;
            this.soql = sql;
        }
    }
    
    public class LocalTimeZone {
        public String displayName {get; set;}
        public String id {get; set;}
        public String locale {get; set;}
        public String language {get; set;}
        public LocalTimeZone(String dispName, String tz, String locale, String lang) {
            this.displayName = dispName;
            this.id = tz;
            this.locale = locale;
            this.language = lang;
        }
    }
/*    
    public class workorder_WPDCx{
        public SVMXC__Service_Order__c workorder_O {get;set;}
        public List<workorderSpecialFields_WPDCx> specialFields_LWP {get; set;}
        public long lastSyncedTime;
        public workorder_WPDCx()
        {

        }
        public workorder_WPDCx(SVMXC__Service_Order__c wo){
            workorder_O = wo;
            specialFields_LWP = references;
        }
    }

    public class workorderSpecialFields_WPDCx{
        public String key {get; set;}
        public String value {get; set;}
        public workorderSpecialFields_WPDCx(String tK, String tV){
            this.key = tK;
            this.value = tV;
        }
    }
*/ 

public static workorderDCx singleWO(String woIds, Boolean isInitial) {
long t1 = DateTime.now().getTime();
system.debug('Inside retrieveWorkOrders');
        String UserId = UserInfo.getUserId();
        List<String> dispatchStatus = new List<String>();
        String viewId = '';
       // system.debug('dispatchStatus ::'+dispatchStatus);
        List<DCON_Configuration_WS.SVMX_StringMap> views = new List<DCON_Configuration_WS.SVMX_StringMap>();
        
        //fetch the default views if any
        SVMXC.DCX_CommonServiceManager.UserSetting userSettings = SVMXC.DCX_SettingServiceManager.fetchUserSettings();
      //  if(viewId == null || viewId == '')
       //     viewId = userSettings.wo_defaultView;
        
        List<string> lstSubModules = new List<string>{'DCON001'};
        Map<String,String> appSetting = COMM_Utils_ManageSettings.SVMX_getDCSetting(lstSubModules);
system.debug('APP SETTINGS: '+appSetting);      
//      Map<String,String> appSetting = commSettings.SVMX_getSettingList('DCON001');
  
        //fetch pageSize from app settings
        

        //fetch the default svmx setting for dispatch status if any
        //This is executed only for initial DCx launch    
        if(isInitial) {
            if(appSetting.containskey('DCON001_SET007') && appSetting.get('DCON001_SET007') != null) {
                String strDefaultStatus = appSetting.get('DCON001_SET007');
                dispatchStatus = strDefaultStatus.split(',');
            }
            
            views = DCON_Retrieve_Views(UserId);
        }
                
        /* If no View Id is passed, set "My Work Orders" view as default */
      //  if(viewId == '' ) {
            List<DCON_Configuration_WS.SVMX_StringMap> viewList = new List<DCON_Configuration_WS.SVMX_StringMap>();
            viewList = DCON_Retrieve_Views(UserId);
            if(viewList[0] != NULL)
                viewId = viewList[0].Key;
      //  }
//long t2 = DateTime.now().getTime();
        SVMXC.COMM_Utils utils = new SVMXC.COMM_Utils(); 
        DCON_Utils dcUtils = new DCON_Utils();

        String WhereClause = '';
        String FirstWhereClause = '';
        String SecondWhereClause = '';
        String strPreFilterCriteria = '';
        String strOwnerShipType = '';
        String querySelect = ''; 
//        List<workorder_WPDCx> workorder_LWP = new List<workorder_WPDCx>();
        List<SVMXC__Service_Order__c> workorder_LO = new List<SVMXC__Service_Order__c>();
        List<String> refFields_L = new List<String>();
        List<String> dateTimeFields_L = new List<String>();
        List<String> dateFields_L = new List<String>();
        Map<String,String> replacementRef = new Map<String,String>();
        Map<String,String> replacementNameField = new Map<String,String>();
        Map<String, SObjectField> newSchemaFieldMap = new Map<String, SObjectField>();
//long t21 = DateTime.now().getTime();        
        Map<String, SObjectField> souObjfieldMap = Schema.SObjectType.SVMXC__Service_Order__c.fields.getMap(); // Get field definition map for work order
//long t22 = DateTime.now().getTime();
        //get wo fields configured in svmx settings       
        Set<string> setWorkOrderFields = getConfiguredWoUpdateFields();
//long t23 = DateTime.now().getTime();        
        //START: DNS-623
        //get the list of WO fields which are to be loaded instead of loading all WO fields
        Set<String> setWOFields = getWOFieldsToLoadInDCx(setWorkOrderFields, userSettings);
//long t24 = DateTime.now().getTime();        
        //get the list of fileds configured by user for a view in SFDC page under 'Dispatch Process -> Dispatch Console Views'
        if(viewId != '' && viewId != null) {
            List<SVMXC__ServiceMax_Config_Data__c> listConfViewFields = new List<SVMXC__ServiceMax_Config_Data__c>();
            listConfViewFields = [Select SVMXC__Field_Name__c from SVMXC__ServiceMax_Config_Data__c where SVMXC__Expression_Rule__c =: viewId and SVMXC__Expression_Type__c ='SRCH_Object_Fields'];//SDL-SVMX-FLS-NOT-ENFORCED-META-DATA
            
            for(SVMXC__ServiceMax_Config_Data__c objConf : listConfViewFields)
                setWOFields.add(objConf.SVMXC__Field_Name__c);
        }

        for(String fieldName : setWoFields) {
            if(!fieldName.equalsIgnoreCase('id') && souObjfieldMap.containsKey(fieldName)) {
                Schema.SObjectField fsObj = souObjfieldMap.get(fieldName);
                newSchemaFieldMap.put(fieldName, fsObj);
            }
        }
//long t4 = DateTime.now().getTime();        
        DCON_Utils.referenceFields_WP reference_M = dcUtils.SVMX_getReferenceFields(newSchemaFieldMap,true);
        newSchemaFieldMap.clear();
        souObjfieldMap.clear();
        List<String> limitedFields_L = reference_M.allFields_L; //Get all fields list
        //END: DNS-623
        refFields_L = reference_M.referenceFields_L; //Get the reference field list
        dateTimeFields_L = reference_M.dateTimeFields_L; //Get the dateTime field list
        dateFields_L = reference_M.dateFields_L; //Get the date field list
        replacementRef = reference_M.replacementReference_M;  //Get the replacement reference field map
        replacementNameField = reference_M.replacementField_M;  //Get the name field for reference map
        querySelect = utils.SVMX_getFieldNamesFromList(limitedFields_L); 
        system.debug('querySelect :'+querySelect);
//long t5 = DateTime.now().getTime();
        // Build the Work Order query
    
        String strQuery = '';
         WhereClause = 'Id = \''+woIds+'\'';

        if(WhereClause != null && WhereClause.length() > 0) //string.escapeSingleQuotes(
            strQuery = 'SELECT ID,' + querySelect + ' FROM SVMXC__Service_Order__c WHERE ' + WhereClause;
        else
            strQuery = 'SELECT ID,' + querySelect + ' FROM SVMXC__Service_Order__c';

        strQuery = substituteQueryWhitespace(strQuery);

        String pageSize = '1';
        workorderDCx_INT wowp;
          if(!Test.isRunningTest()){
        wowp = doGet(strQuery, pageSize,true);
          }

        system.debug('wowp '+wowp);
        Long dbsyncTime = DateTime.Now().getTime();
//long t11 = DateTime.now().getTime();        

        LocalTimeZone localTz = new LocalTimeZone(UserInfo.getTimeZone().getDisplayName(),UserInfo.getTimeZone().getID(),UserInfo.getLocale(),UserInfo.getLanguage());
        //create the workorderDCx to be returned with metadata
          if(!Test.isRunningTest()){
        workorderDCx woData = new workorderDCx(wowp.totalSize,wowp.done,null,dbsyncTime,wowp.records,isInitial?localTz:null,isInitial?viewId:null,isInitial?views:null,null);

//long t12 = DateTime.now().getTime();
system.debug('woData :'+woData);
        return woData;
          }
          else 
          return null;
    }


    public static DCON_WO_MultiAssign_Response DCX_Manage_Work_Order_MultiAssign_WS(DCON_WO_MultiAssign_Request dcon_Request) 
    {
        /* this is a generic Web Service that can be used as a common entry point for all WO related services */
        // Pavitra: postpone the WO trigger execution
        // WO Trigger is getting executed 8 times (4 set of After + Before)
        allowtriggerExecution = false;
        DCX_WOServiceManager_Util woServUtil = new DCX_WOServiceManager_Util();
        // Create, Delete and Update operation 
        //Save point
        Savepoint sp = Database.setSavepoint();
        string UserId = UserInfo.getUserId();
        DCON_WO_MultiAssign_Response DCON_Response = new DCON_WO_MultiAssign_Response();
        list<string> EventIds = new list<string>();
        SVMXC.COMM_Utils_ManageSettings clsCommSettings = new SVMXC.COMM_Utils_ManageSettings();
        list<string> lstSettings = new list<string>{'DCON001_SET009'};
        map<String, String> mapSettingValues = clsCommSettings.SVMX_getGlobalSettingList(lstSettings);
        boolean setOwner;
        String StatusMessage;
        DCX_CommonServiceManager.DCEvent_WO_WP eventData = 
            new DCX_CommonServiceManager.DCEvent_WO_WP();
        if(mapSettingValues.containsKey('DCON001_SET009'))
            setOwner = boolean.valueOf(mapSettingValues.get('DCON001_SET009'));
        system.debug(LoggingLevel.Warn, ' Request object  '+dcon_Request);
        try
        {
            If(dcon_Request.operationType == 'WO_UNASSIGN_YES')
            {
                if(dcon_Request.WorkOrderIds != NULL && dcon_Request.WorkOrderIds.size() > 0)
                    StatusMessage = DCON_Work_Order_WS.DCON_Unassign_Work_Order_WS(UserId, dcon_Request.WorkOrderIds);
                // When technician id is not given don't do work order assignment
                if(dcon_Request.technicianIds.get(0) != NULL && dcon_Request.technicianIds.get(0) != '')
                    DCON_Work_Order_WS.DCON_Assign_Work_Order_To_Tech_WS(UserId, dcon_Request.WorkOrderIds, dcon_Request.technicianIds.get(0), setOwner);
                if(dcon_Request.EventList!= null && dcon_Request.EventList.size()>0)                    
                    eventData = 
                        DCX_EventServiceManager.DCX_Upsert_Events_WS4(UserId, 
                                                                      dcon_Request.EventList, 
                                                                      dcon_Request.timeZone, 
                                                                      dcon_Request.lstKeyValue,
                                                                      dcon_Request.technicianIds[0],
                                                                      dcon_Request.techSFId,
                                                                      dcon_Request.woFields);

            }
            else if(dcon_Request.operationType == 'WO_UNASSIGN_NO')
            {   
                if(dcon_Request.EventIds != null && dcon_Request.EventIds.size()>0) {
                    //deleteEvents(dcon_Request.EventIds);
                    woServUtil.deleteEventsUtil(dcon_Request.EventIds);
                }
                if(dcon_Request.EventList != null && dcon_Request.EventList.size()>0)
                    eventData = 
                        DCX_EventServiceManager.DCX_Upsert_Events_WS4 (UserId, dcon_Request.EventList, 
                                                                       dcon_Request.timeZone, 
                                                                       dcon_Request.lstKeyValue,
                                                                       dcon_Request.technicianIds[0],
                                                                       dcon_Request.techSFId,
                                                                       dcon_Request.woFields);

                
                if(dcon_Request.EventIds != null)
                {
                    for(string Eventid :dcon_Request.EventIds)
                    {
                        if(StatusMessage != '')
                            StatusMessage += ',';
                        StatusMessage += Eventid; 
                    }
                }
            }
            //Any exception transaction is rolled back using save point created and throw the exception 
        }   
        catch(DmlException ex)
        {
            Database.rollback(sp);
            system.debug(logginglevel.warn,'ex.getstackTrace()'+ex.getStackTraceString());
            throw new DCX_CommonServiceManager.DCxException(ex);
        }
        catch(Exception ex)
        {
            Database.rollback(sp);
            system.debug(logginglevel.warn,'ex.getstackTrace()'+ex.getStackTraceString());
            system.debug('Main error list'+ex.getmessage());
            throw new DCX_CommonServiceManager.DCxException(ex);
        }
        //Building the Response containg list DC_StringListMap 
        map<String,list<String>> mapTechEventInfo = new map<String,list<String>>();
        for(string eventInfo:EventIds)
        {
            if(eventInfo.contains('_'))
            {
                string TechId = eventInfo.split('_').get(0);    
                if(mapTechEventInfo.containskey(TechId))            
                    mapTechEventInfo.get(TechId).add(eventInfo.substring(TechId.length() +1));
                else
                {
                    list<string> lsteventinfo = new list<string>();
                    lsteventinfo.add(eventInfo.substring(TechId.length() +1));
                    mapTechEventInfo.put(TechId,lsteventinfo);
                }
            }
        }
        for(string TechId:mapTechEventInfo.keyset())
        {
            DC_StringListMap TechEventinfo =  new DC_StringListMap();
            TechEventinfo.key = TechId;
            TechEventinfo.valueList.addall(mapTechEventInfo.get(TechId));
            DCON_Response.lstTechEventDetails.add(TechEventinfo);
        }
        DC_StringListMap DeletedEventinfo =  new DC_StringListMap();
        DeletedEventinfo.key = 'DELETED_EVENT_IDS';
        DeletedEventinfo.valueList.add(StatusMessage);
        DCON_Response.lstTechEventDetails.add(DeletedEventinfo);
        // Pavitra: postpone the WO trigger execution
        // WO Trigger is getting executed 8 times (4 set of After + Before)
        allowtriggerExecution = true;
        system.debug(logginglevel.warn,'DCON_Response:  '+DCON_Response);
        DCON_Response.eventWorkOrderInfo = eventData;
        return DCON_Response;
    }

    public static void deleteEvents(List<String> evtIds) {
        List<Event> SalesforceEventList = [Select Id from Event where Id in :evtIds];
        if(SalesforceEventList.size() > 0){
            delete SalesforceEventList;
        } 
        List<SVMXC__SVMX_Event__c> svmxEvents = [Select Id from SVMXC__SVMX_Event__c where
                                                 Id in :evtIds];
        if(svmxEvents.size() > 0){
            delete svmxEvents;
        }
    }

    public class DCON_WO_MultiAssign_Response
    {
        public List< DC_StringListMap > lstTechEventDetails =  new List< DC_StringListMap >();// Having Technician as key and list having details of all Events for the technician
        public List<DC_StringListMap> getlstTechEventDetails(){return lstTechEventDetails;}
        public void setlstTechEventDetails(List<DC_StringListMap> s ){lstTechEventDetails = s;}
        public DCX_CommonServiceManager.DCEvent_WO_WP eventWorkOrderInfo;
    }

    public class DC_StringListMap
    {
        public String key {get;set;} //Technician Id
        public List<String> valueList = new List<String>();//Details of all Events for Technician(EventID, ActivityDateTime, DurationInMinutes )
        public String fieldsToNull{get;set;}

        public DC_StringListMap(String key,List<String> valueList)
        {
            this.key = key;
            this.valueList = valueList;
        }
        public DC_StringListMap()
        {

        }

        public List<String> getvalueList(){return valueList;}
        public void setvalueList(List<String> s ){valueList = s;}
    }

    public class DCON_WO_MultiAssign_Request 
    { 
        public List<String> workOrderIds = new List<String>();
        public List<String> technicianIds = new List<String>();
        public String operationType{get; set;}   // MULTIASSIGN_YES (if user selects to unassign wo) or MULTIASSIGN_NO (if user selects to keep the assignment and create/delete events)
        public String timezone{get; set;}
        public List<Event> Eventlist = new list<Event>();
        public List< String > EventIds = new List<String>();//Event Ids to delete in MutiTech;
        public List<DCON_Configuration_WS.SVMX_StringMap> lstKeyValue = new List<DCON_Configuration_WS.SVMX_StringMap>();
        public String techSFId;
        public List<String> getworkOrderIds(){return workOrderIds;}
        public void setworkOrderIds(List<String> s ){workOrderIds = s;}
        public List<Event> getEventlist(){return Eventlist;}
        public void setEventlist(List<Event> s ){Eventlist = s;}
        public List<String> woFields = new List<String>();
    }

   public static assignWOTeam_Response assignWOTeam(assignWOTeam_Request req) {
        assignWOTeam_Response res = new assignWOTeam_Response();
        List<String> WorkOrderIds =req.WorkOrderIds;
        String TeamId =req.TeamId;
        String dispatchStatus =req.dispatchStatus;
        Boolean unassignWorkorder =req.unassignWorkorder;
        Boolean SetOwner =req.SetOwner;
        String StatusMessage;
        String UserId = UserInfo.getUserId();
        if(!Test.isRunningTest()){
         if(dispatchStatus.toUpperCase()!= 'NEW' && unassignWorkorder == true){
                res.deletedEventIds = DCON_Work_Order_WS.DCON_Unassign_Work_Order_WS(UserId, WorkOrderIds);
        }
         res.assingedStatus = DCON_Work_Order_WS.DCON_Assign_Work_Order_To_Team_WS(UserId,WorkOrderIds,TeamId,SetOwner);
         }
         return res;

    }

        public class assignWOTeam_Response 
        { 
            String deletedEventIds = '';
            String assingedStatus = '';
        }
        public class assignWOTeam_Request 
        { 
            public List<String> WorkOrderIds;
            public String TeamId;
            public Boolean SetOwner;
            public String dispatchStatus;
            public Boolean unassignWorkorder;
            public assignWOTeam_Request() {
                
        }
        
        public assignWOTeam_Request( List<String> WorkOrderIds, String TeamId, Boolean SetOwner,String dispatchStatus,Boolean unassignWorkorder) {
            
            this.WorkOrderIds = WorkOrderIds;
            this.TeamId = TeamId;
            this.SetOwner = SetOwner;
            this.dispatchStatus = dispatchStatus;
            this.unassignWorkorder = unassignWorkorder;
        }
    }

    public static assignWOTeam_Response assignWOTech(assignWOTeam_Request req) {
        assignWOTeam_Response res = new assignWOTeam_Response();
        List<String> WorkOrderIds =req.WorkOrderIds;
        String TeamId =req.TeamId;
        String dispatchStatus =req.dispatchStatus;
        Boolean unassignWorkorder =req.unassignWorkorder;
        Boolean SetOwner =req.SetOwner;
        String StatusMessage;
        String UserId = UserInfo.getUserId();
        if(!Test.isRunningTest()){
        if(dispatchStatus.toUpperCase()!= 'NEW' && unassignWorkorder == true){
                    res.deletedEventIds = DCON_Work_Order_WS.DCON_Unassign_Work_Order_WS(UserId, WorkOrderIds);
        }
         res.assingedStatus = DCON_Work_Order_WS.DCON_Assign_Work_Order_To_Tech_WS(UserId,WorkOrderIds,TeamId,SetOwner);
         }
        return res;
    }
    
    public without sharing class DCX_WOServiceManager_Util {
        public void deleteEventsUtil(List<String> eIds) {
            List<Event> SalesforceEventList = [SELECT Id, ActivityDateTime, WhatId, OwnerId from Event where Id 
                                           IN :eIds];
            List<SVMXC__SVMX_Event__c> ServiceMaxEventList = [SELECT Id, SVMXC__ActivityDateTime__c, 
                                                              SVMXC__WhatId__c, SVMXC__Technician__c 
                                                              from SVMXC__SVMX_Event__c where Id IN :eIds];
            if(SalesforceEventList.size() > 0) {
                if( COMM_SecurityUtils.getInstance().isDeletableObject('Event') )
                    delete SalesforceEventList;
            }
            if(ServiceMaxEventList.size() > 0)
                COMM_SecurityUtils.getinstance().deleteAsUser(ServiceMaxEventList);    
        }
    }
    
}