@isTest(seeAllData = true)
private class INTF_ConfigSync_UT {
    static testMethod void INTF_ConfigSync_UT_Test(){
        SVMXC__ServiceMax_Processes__c pro = new SVMXC__ServiceMax_Processes__c();
        pro.SVMXC__Values__c = '{"wizards":["Checklist","Checklist for iPhone"],"sfms":["sfm_for_unit_test"],"sfactions":["other_action_for_UT"]}';
        pro.RecordTypeId = [select id from RecordType where Name = 'Application Profile'][0].Id;
        pro.SVMXC__ProcessID__c = 'iPad';
        pro.SVMXC__Installation_Key__c = EncodingUtil.base64Encode(Blob.valueOf(UserInfo.getOrganizationId().subString(0,15)));
        insert pro;
        
        INTF_WebServicesDef.INTF_SFMRequest req = new INTF_WebServicesDef.INTF_SFMRequest();
        INTF_ConfigSync oneCall = new INTF_ConfigSync();
        req.clientInfo = new List<INTF_WebServicesDef.SVMXClient>();
        INTF_WebServicesDef.SVMXClient cl = new INTF_WebServicesDef.SVMXClient();
        cl.clientType = 'iPad';
        cl.clientInfo = new List<String>{'appversion:16.49.002', 'appname:SVMX_MFL','userid:'+UserInfo.getUserId()};
        req.clientInfo.add(cl);
        
        req.valueMap = new List<INTF_WebServicesDef.SVMXMap>();
        req.value = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        INTF_WebServicesDef.INTF_SFMResponse res = oneCall.OneCallMetaSync(req);
        
        Boolean isCallBack = false;
        List<INTF_WebServicesDef.SVMXMap> callBackVM = new List<INTF_WebServicesDef.SVMXMap>();
        for(INTF_WebServicesDef.SVMXMap eachValueMap : res.valueMap)
        {
            if(eachValueMap.key == 'CALL_BACK' && eachValueMap.value != null && eachValueMap.value != '')
            {
                isCallBack = Boolean.valueOf(eachValueMap.value);
                callBackVM = eachValueMap.valueMap;
                break;
            }   
        }
        if(isCallBack)
        {
            req = new INTF_WebServicesDef.INTF_SFMRequest();
            req.valueMap = new List<INTF_WebServicesDef.SVMXMap>();
            req.value = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
            req.clientInfo = new List<INTF_WebServicesDef.SVMXClient>();
            cl.clientType = 'iPhone';
            req.clientInfo.add(cl);
            INTF_WebServicesDef.SVMXMap callbck = new INTF_WebServicesDef.SVMXMap('CALL_BACK', 'true');
            callbck.valueMap = callBackVM;
            req.valueMap.add(callbck);
            INTF_WebServicesDef.INTF_SFMResponse resp = (new INTF_ConfigSync()).OneCallMetaSync(req);
            
            for(INTF_WebServicesDef.SVMXMap eachValueMap : res.valueMap)
            {
                if(eachValueMap.key == 'CALL_BACK' && eachValueMap.value != null && eachValueMap.value != '')
                {
                    isCallBack = Boolean.valueOf(eachValueMap.value);
                    callBackVM = eachValueMap.valueMap;
                    break;
                }   
            }
            if(isCallBack)
            {
                req = new INTF_WebServicesDef.INTF_SFMRequest();
                req.valueMap = new List<INTF_WebServicesDef.SVMXMap>();
                req.value = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
                req.clientInfo = new List<INTF_WebServicesDef.SVMXClient>();
                cl.clientType = 'iPhone';
                req.clientInfo.add(cl);
                INTF_WebServicesDef.SVMXMap callbck2 = new INTF_WebServicesDef.SVMXMap('CALL_BACK', 'true');
                callbck2.valueMap = callBackVM;
                req.valueMap.add(callbck);
                resp = (new INTF_ConfigSync()).OneCallMetaSync(req);
            }
        }
    }
    
    static testMethod void testObjectDefinition()
    {
        INTF_WebServicesDef.INTF_SFMRequest req = new INTF_WebServicesDef.INTF_SFMRequest();
        
        req.clientInfo = new List<INTF_WebServicesDef.SVMXClient>();
        INTF_WebServicesDef.SVMXClient clInfo = new INTF_WebServicesDef.SVMXClient();
        clInfo.clientInfo = new List<String>{'appversion:16.49.002', 'appname:SVMX_MFL','userid:'+UserInfo.getUserId(),'clientudid:123456789'};
        clInfo.clientType = 'iPad';
        req.clientInfo.add(clInfo);
        List<string> lstObjects = new List<string>{'SVMXC__Service_Order__c','SVMXC__Service_Order_Line__c'};
        req.values = lstObjects;
        INTF_WebServicesDef.INTF_SFMResponse resObjDef = (new INTF_ConfigSync()).getObjectDef(req); 
    }
    
    static testMethod void testHardcodedDescribe()
    {
        INTF_ConfigSync newSync = new INTF_ConfigSync();
        INTF_WebServicesDef.SVMXMap userDef = newSync.getUserObjDescribe(); 
        INTF_WebServicesDef.SVMXMap eventDef = newSync.getEventObjDescribe(); 
        INTF_WebServicesDef.SVMXMap taskDef = newSync.getTaskObjDescribe(); 
        INTF_WebServicesDef.SVMXMap attachmentDef = newSync.getAttachmentObjDescribe();
        INTF_WebServicesDef.SVMXMap businessHoursDef = newSync.getBusinessHoursObjDescribe();         
    }
    
    static testMethod void testFsaTags(){
        INTF_WebServicesDef.INTF_SFMRequest req = new INTF_WebServicesDef.INTF_SFMRequest();
        INTF_WebServicesDef.INTF_SFMResponse response = new INTF_WebServicesDef.INTF_SFMResponse();
        
        req.EventType = 'META_SYNC';
        req.EventName = 'FSA_TAGS';
        
        try{
            Test.startTest();
                response = (new INTF_ConfigSync()).getFsaTags(req);
            Test.stopTest();
        }catch(Exception Ex){
            System.debug(LoggingLevel.WARN, ' Exception :'+Ex.getMessage());
        }
        
    }
    
    static testMethod void testOneCallMetaSyncBatching(){
        INTF_WebServicesDef.INTF_SFMResponse resp = new INTF_WebServicesDef.INTF_SFMResponse();
        INTF_WebServicesDef.INTF_SFMRequest req = new INTF_WebServicesDef.INTF_SFMRequest();

        INTF_WebServicesDef.SVMXClient clInfo = new INTF_WebServicesDef.SVMXClient();
        clInfo.clientInfo = new List<String>{'appversion:16.49.002', 'appname:SVMX_MFL','userid:'+UserInfo.getUserId(),'clientudid:123456789'};
        clInfo.clientType = 'iPad';
        req.clientInfo = new List<INTF_WebServicesDef.SVMXClient>{clInfo};
        
        req.eventType = 'META_SYNC';
        req.eventName = 'ONE_CALL_SYNC';
        req.value = '123456789';
        req.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();

        SVMXC.INTF_WebServicesDef.SVMXMap innerVM = new SVMXC.INTF_WebServicesDef.SVMXMap('CALL_BACK_CONTEXT', '6');
        
        SVMXC.INTF_WebServicesDef.SVMXMap valueMap1 = new SVMXC.INTF_WebServicesDef.SVMXMap('CALL_BACK','TRUE');
        valueMap1.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();
        valueMap1.valueMap.add(innerVM);

        req.valueMap.add(valueMap1);
        
        try{
            test.StartTest();
                resp = SVMXC.INTF_WebServicesDef.INTF_MetaSync_WS(req);
            test.StopTest();
        }catch(Exception Ex){
            System.debug(LoggingLevel.WARN, ' Exception :'+Ex.getMessage());
        }       
    }
    
    static testMethod void testSFMMetaBatching(){
        INTF_WebServicesDef.INTF_SFMResponse resp = new INTF_WebServicesDef.INTF_SFMResponse();
        INTF_WebServicesDef.INTF_SFMRequest req = new INTF_WebServicesDef.INTF_SFMRequest();

        INTF_WebServicesDef.SVMXClient clInfo = new INTF_WebServicesDef.SVMXClient();
        clInfo.clientInfo = new List<String>{'appversion:16.49.002', 'appname:SVMX_MFL','userid:'+UserInfo.getUserId(),'clientudid:123456789'};
        clInfo.clientType = 'iPad';
        req.clientInfo = new List<INTF_WebServicesDef.SVMXClient>{clInfo};
        
        req.eventType = 'META_SYNC';
        req.eventName = 'ONE_CALL_SYNC';
        req.value = '123456789';
        req.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();

        SVMXC.INTF_WebServicesDef.SVMXMap innerVM = new SVMXC.INTF_WebServicesDef.SVMXMap('CALL_BACK_CONTEXT', '3');
        innerVM.values = NULL;

        SVMXC.INTF_WebServicesDef.SVMXMap pnoVM = new SVMXC.INTF_WebServicesDef.SVMXMap('PROCESS_PNO_LASTID', '3');
        pnoVM.values = new List<string>{'a120G00000AkwZLQAZ'};

        SVMXC.INTF_WebServicesDef.SVMXMap tmVM = new SVMXC.INTF_WebServicesDef.SVMXMap('PROCESS_TM_LASTID', '3');
        tmVM.values = new List<string>{''};

        SVMXC.INTF_WebServicesDef.SVMXMap csdVM = new SVMXC.INTF_WebServicesDef.SVMXMap('PROCESS_CSD_LASTID', '3');
        csdVM.values = new List<string>{'a120G00000AzJEtQAN'};

        SVMXC.INTF_WebServicesDef.SVMXMap valueMap1 = new SVMXC.INTF_WebServicesDef.SVMXMap('CALL_BACK','TRUE');
        valueMap1.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();
        valueMap1.valueMap.add(innerVM);
        valueMap1.valueMap.add(pnoVM);
        valueMap1.valueMap.add(tmVM);
        valueMap1.valueMap.add(csdVM);

        req.valueMap.add(valueMap1);
        
        try{
            test.StartTest();
                resp = SVMXC.INTF_WebServicesDef.INTF_MetaSync_WS(req);
            test.StopTest();
        }catch(Exception Ex){
            System.debug(LoggingLevel.WARN, ' Exception :'+Ex.getMessage());
        }       
    }
    
    static testMethod void testBatchingContext11(){
        INTF_WebServicesDef.INTF_SFMResponse resp = new INTF_WebServicesDef.INTF_SFMResponse();
        INTF_WebServicesDef.INTF_SFMRequest req = new INTF_WebServicesDef.INTF_SFMRequest();

        INTF_WebServicesDef.SVMXClient clInfo = new INTF_WebServicesDef.SVMXClient();
        clInfo.clientInfo = new List<String>{'appversion:16.49.002', 'appname:SVMX_MFL','userid:'+UserInfo.getUserId(),'clientudid:123456789'};
        clInfo.clientType = 'iPad';
        req.clientInfo = new List<INTF_WebServicesDef.SVMXClient>{clInfo};
        
        req.eventType = 'META_SYNC';
        req.eventName = 'ONE_CALL_SYNC';
        req.value = '123456789';
        req.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();

        SVMXC.INTF_WebServicesDef.SVMXMap innerVM = new SVMXC.INTF_WebServicesDef.SVMXMap('CALL_BACK_CONTEXT', '11');
        innerVM.values = NULL;

        SVMXC.INTF_WebServicesDef.SVMXMap valueMap1 = new SVMXC.INTF_WebServicesDef.SVMXMap('CALL_BACK','TRUE');
        valueMap1.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();
        valueMap1.valueMap.add(innerVM);
        
        req.valueMap.add(valueMap1);
        
        try{
            test.StartTest();
                resp = SVMXC.INTF_WebServicesDef.INTF_MetaSync_WS(req);
            test.StopTest();
        }catch(Exception Ex){
            System.debug(LoggingLevel.WARN, ' Exception :'+Ex.getMessage());
        }       
    }
    
    static testMethod void testBatchingContext12(){
        INTF_WebServicesDef.INTF_SFMResponse resp = new INTF_WebServicesDef.INTF_SFMResponse();
        INTF_WebServicesDef.INTF_SFMRequest req = new INTF_WebServicesDef.INTF_SFMRequest();

        INTF_WebServicesDef.SVMXClient clInfo = new INTF_WebServicesDef.SVMXClient();
        clInfo.clientInfo = new List<String>{'appversion:16.49.002', 'appname:SVMX_MFL','userid:'+UserInfo.getUserId(),'clientudid:123456789'};
        clInfo.clientType = 'iPad';
        req.clientInfo = new List<INTF_WebServicesDef.SVMXClient>{clInfo};
        
        req.eventType = 'META_SYNC';
        req.eventName = 'ONE_CALL_SYNC';
        req.value = '123456789';
        req.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();

        SVMXC.INTF_WebServicesDef.SVMXMap innerVM = new SVMXC.INTF_WebServicesDef.SVMXMap('CALL_BACK_CONTEXT', '12');
        innerVM.values = NULL;

        SVMXC.INTF_WebServicesDef.SVMXMap valueMap1 = new SVMXC.INTF_WebServicesDef.SVMXMap('CALL_BACK','TRUE');
        valueMap1.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();
        valueMap1.valueMap.add(innerVM);
        
        req.valueMap.add(valueMap1);
        
        try{
            test.StartTest();
                resp = SVMXC.INTF_WebServicesDef.INTF_MetaSync_WS(req);
            test.StopTest();
        }catch(Exception Ex){
            System.debug(LoggingLevel.WARN, ' Exception :'+Ex.getMessage());
        }       
    }
    
    static testMethod void testBatchingContext78910(){
        INTF_WebServicesDef.INTF_SFMResponse resp = new INTF_WebServicesDef.INTF_SFMResponse();
        INTF_WebServicesDef.INTF_SFMRequest req = new INTF_WebServicesDef.INTF_SFMRequest();

        INTF_WebServicesDef.SVMXClient clInfo = new INTF_WebServicesDef.SVMXClient();
        clInfo.clientInfo = new List<String>{'appversion:16.49.002', 'appname:SVMX_MFL','userid:'+UserInfo.getUserId(),'clientudid:123456789'};
        clInfo.clientType = 'iPad';
        req.clientInfo = new List<INTF_WebServicesDef.SVMXClient>{clInfo};
        
        req.eventType = 'META_SYNC';
        req.eventName = 'ONE_CALL_SYNC';
        req.value = '123456789';
        req.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();

        SVMXC.INTF_WebServicesDef.SVMXMap innerVM = new SVMXC.INTF_WebServicesDef.SVMXMap('CALL_BACK_CONTEXT', '7');
        innerVM.values = NULL;

        SVMXC.INTF_WebServicesDef.SVMXMap valueMap1 = new SVMXC.INTF_WebServicesDef.SVMXMap('CALL_BACK','TRUE');
        valueMap1.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();
        valueMap1.valueMap.add(innerVM);
        
        req.valueMap.add(valueMap1);
        
        try{
            test.StartTest();
            resp = SVMXC.INTF_WebServicesDef.INTF_MetaSync_WS(req);
            
                //Context8
            req.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();
    
            innerVM = new SVMXC.INTF_WebServicesDef.SVMXMap('CALL_BACK_CONTEXT', '8');
            innerVM.values = NULL;
    
            valueMap1 = new SVMXC.INTF_WebServicesDef.SVMXMap('CALL_BACK','TRUE');
            valueMap1.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();
            valueMap1.valueMap.add(innerVM);
            
            req.valueMap.add(valueMap1);
            
            resp = SVMXC.INTF_WebServicesDef.INTF_MetaSync_WS(req);
            
            //Context9
            
            req.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();
    
            innerVM = new SVMXC.INTF_WebServicesDef.SVMXMap('CALL_BACK_CONTEXT', '9');
            innerVM.values = NULL;
    
            valueMap1 = new SVMXC.INTF_WebServicesDef.SVMXMap('CALL_BACK','TRUE');
            valueMap1.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();
            valueMap1.valueMap.add(innerVM);
            
            req.valueMap.add(valueMap1);
            
            resp = SVMXC.INTF_WebServicesDef.INTF_MetaSync_WS(req);
            
            //Context10
            
            req.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();
    
            innerVM = new SVMXC.INTF_WebServicesDef.SVMXMap('CALL_BACK_CONTEXT', '10');
            innerVM.values = NULL;
    
            valueMap1 = new SVMXC.INTF_WebServicesDef.SVMXMap('CALL_BACK','TRUE');
            valueMap1.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();
            valueMap1.valueMap.add(innerVM);
            
            req.valueMap.add(valueMap1);
            
            resp = SVMXC.INTF_WebServicesDef.INTF_MetaSync_WS(req);
            test.StopTest();
        
        }catch(Exception Ex){
            System.debug(LoggingLevel.WARN, ' Exception :'+Ex.getMessage());
        }
    }
    
    static testMethod void testGetExpMeta(){
        INTF_WebServicesDef.INTF_SFMResponse resp = new INTF_WebServicesDef.INTF_SFMResponse();
        INTF_WebServicesDef.INTF_SFMRequest req = new INTF_WebServicesDef.INTF_SFMRequest();

        INTF_WebServicesDef.SVMXClient clInfo = new INTF_WebServicesDef.SVMXClient();
        clInfo.clientInfo = new List<String>{'appversion:16.49.002', 'appname:SVMX_MFL','userid:'+UserInfo.getUserId(),'clientudid:123456789'};
        clInfo.clientType = 'iPad';
        req.clientInfo = new List<INTF_WebServicesDef.SVMXClient>{clInfo};
        
        req.eventType = 'META_SYNC';
        req.eventName = 'ONE_CALL_SYNC';
        req.value = '123456789';
        req.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();
        
        Set<String> expressionIds = new Set<String>();
        for(SVMXC__ServiceMax_Processes__c eachPro: [select SVMXC__Submodule__c from SVMXC__ServiceMax_Processes__c where Recordtype.Name= 'Process Node Objects' AND SVMXC__Submodule__c != NULL LIMIT 5]){
            expressionIds.add(eachPro.SVMXC__Submodule__c);
        }

        try{
            test.StartTest();
                    String svmxGrpProfileId = (new INTF_ConfigSync()).getSVMXGrpProfileId(userinfo.getProfileId());
                (new INTF_ConfigSync()).addExpsMetaToResponse(resp,expressionIds,svmxGrpProfileId); 
                
            test.StopTest();
        }catch(Exception Ex){
            System.debug(LoggingLevel.WARN, ' Exception :'+Ex.getMessage());
        }       
    }
    
    static testMethod void testGetQuestionsMeta(){
        INTF_WebServicesDef.INTF_SFMResponse resp = new INTF_WebServicesDef.INTF_SFMResponse();
        INTF_WebServicesDef.INTF_SFMRequest req = new INTF_WebServicesDef.INTF_SFMRequest();

        INTF_WebServicesDef.SVMXClient clInfo = new INTF_WebServicesDef.SVMXClient();
        clInfo.clientInfo = new List<String>{'appversion:16.49.002', 'appname:SVMX_MFL','userid:'+UserInfo.getUserId(),'clientudid:123456789'};
        clInfo.clientType = 'iPad';
        req.clientInfo = new List<INTF_WebServicesDef.SVMXClient>{clInfo};
        
        req.eventType = 'META_SYNC';
        req.eventName = 'ONE_CALL_SYNC';
        req.value = '123456789';
        req.valueMap = new List<SVMXC.INTF_WebServicesDef.SVMXMap>();
        
        Set<String> setPageLayoutIds = new Set<String>();
        
        for(SVMXC__ServiceMax_Processes__c processTM: [select SVMXC__Page_Layout__c from SVMXC__ServiceMax_Processes__c where Recordtype.Name= 'Target Manager' AND SVMXC__Page_Layout__c != NULL LIMIT 5]){
            setPageLayoutIds.add(processTM.SVMXC__Page_Layout__c);
        }

        try{
            test.StartTest();
                    String svmxGrpProfileId = (new INTF_ConfigSync()).getSVMXGrpProfileId(userinfo.getProfileId());
                (new INTF_ConfigSync()).addQuestionMetaToResponse(resp, setPageLayoutIds, svmxGrpProfileId);
                
                (new INTF_ConfigSync()).addCallBackContextForLimit(resp, '10', new List<String>{'a120G00000AkwZLQAZ'}, '60');
                (new INTF_ConfigSync()).addCallBackContextForExpressions(resp, '10', new List<String>{'a120G00000AkwZLQAZ'}, new List<String>{'a120G00000AkwZLQAZ'});
                
            test.StopTest();
        }catch(Exception Ex){
            System.debug(LoggingLevel.WARN, ' Exception :'+Ex.getMessage());
        }       
    }
}