@isTest
private class WSCH_ECO_Client_TechnicianServices_UT {

    static testMethod void ECO_Client_TechnicianServices_UT1() {
        SVMXC__Territory__c territory = createTerritory();
        SVMXC__ServiceMax_Processes__c prcessObjone = createDP(territory);
        
        SVMXC__Service_Group__c team = new SVMXC__Service_Group__c();
        team.Name = 'team1';
        insert team;
        
        SVMXC__Service_Group_Members__c technician1 = new SVMXC__Service_Group_Members__c();
        technician1.Name = 'Tech1';
        technician1.SVMXC__Service_Group__c = team.Id;
        insert technician1;
        
        
        SVMXC__SVMX_Optimizer__c optimizer = new SVMXC__SVMX_Optimizer__c();
        optimizer.SVMXC__WhatType__c = 'TECHNICIAN';
        optimizer.SVMXC__WhatId__c = technician1.Id + '_' + technician1.Name;
        optimizer.SVMXC__Optimizer_Connection_ID__c = prcessObjone.id + '_' + territory.id;
        optimizer.SVMXC__Optimizer_Change_Token__c = 'CHANGE_CREATE_TECH';
        optimizer.SVMXC__Optimizer_Status__c = 'OPT_COMPLETED';
        optimizer.SVMXC__Optimizer_Error_Text__c = 'Technician added through initJob call';
        insert optimizer;
        
        RestRequest req = new RestRequest();
        
        req.requestURI = '/services/apexrest/scheduling/eco/technician';
        String reqBody = '{"dispatchProcessGuid":"' + prcessObjone.id + '","territoryGuid":"' + territory.id + '"}';
        req.requestBody = Blob.valueOf(reqBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        
        Test.startTest();
        String response = WSCH_ECO_Client_TechnicianServices.doPost();
        Test.stopTest();
        //System.assertEquals('Empty or Invalid operation type', response);
    }
    
    static testMethod void ECO_Client_TechnicianServices_UT2() {
        SVMXC__Territory__c territory = createTerritory();
        SVMXC__ServiceMax_Processes__c prcessObjone = createDP(territory);
        
        SVMXC__Service_Group__c team = new SVMXC__Service_Group__c();
        team.Name = 'team1';
        insert team;
        
        SVMXC__Service_Group_Members__c technician1 = new SVMXC__Service_Group_Members__c();
        technician1.Name = 'Tech1';
        technician1.SVMXC__Service_Group__c = team.Id;
        insert technician1;
        
        
        SVMXC__SVMX_Optimizer__c optimizer = new SVMXC__SVMX_Optimizer__c();
        optimizer.SVMXC__WhatType__c = 'TECHNICIAN';
        optimizer.SVMXC__WhatId__c = technician1.Id + '_' + technician1.Name;
        optimizer.SVMXC__Optimizer_Connection_ID__c = prcessObjone.id + '_' + territory.id;
        optimizer.SVMXC__Optimizer_Change_Token__c = 'CHANGE_CREATE_TECH';
        optimizer.SVMXC__Optimizer_Status__c = 'OPT_COMPLETED';
        optimizer.SVMXC__Optimizer_Error_Text__c = 'Technician added through initJob call';
        insert optimizer;
        
        RestRequest req = new RestRequest();
        
        req.requestURI = '/services/apexrest/scheduling/eco/technician';
        String reqBody = '{"dispatchProcessGuid":"' + prcessObjone.id + '","territoryGuid":"' + territory.id + '","operation":"HORIZON_UPDATE"}';
        req.requestBody = Blob.valueOf(reqBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        
        Test.startTest();
        String response = WSCH_ECO_Client_TechnicianServices.doPost();
        Test.stopTest();
        //System.assertEquals('Technician Horizon Updated', response);
    }

    private static SVMXC__Territory__c createTerritory() {
        list<SVMXC__Territory__c> Territorylst = new List<SVMXC__Territory__c>();
        BusinessHours bh = [Select Id from BusinessHours where IsDefault=true];
        SVMXC__Territory__c Territory1 = new SVMXC__Territory__c();
        Territory1.name = 'ECO_Client_TechnicianServices_T1';
        Territory1.SVMXC__Territory_s_Business_Hours__c = bh.id;
        Territorylst.add(Territory1);
        insert Territorylst;
        
        return Territorylst[0];
    }
    
    private static SVMXC__ServiceMax_Processes__c createDP(SVMXC__Territory__c territory) {
        List<RecordType> RecType = new  List<RecordType>();
        string DispatchRTypeId;
        RecType = Database.Query('Select r.SystemModstamp, r.SobjectType, r.NamespacePrefix, r.Name, r.LastModifiedDate, r.LastModifiedById, r.IsActive, r.Id, r.DeveloperName, r.Description, r.CreatedDate, r.CreatedById, r.BusinessProcessId From RecordType r where SobjectType = \'SVMXC__ServiceMax_Processes__c\'');
        for(RecordType Rt : RecType)
        {
            if(Rt.Name == 'Dispatch Process')
            {
                DispatchRTypeId  = Rt.id;
            }
        }
        SVMXC__ServiceMax_Processes__c prcessObjone = new SVMXC__ServiceMax_Processes__c();
        prcessObjone.RecordTypeId = DispatchRTypeId;
        prcessObjone.SVMXC__Name__c = 'Test one';
        prcessObjone.SVMXC__Dispatch_Method__c = 'Real Time Optimization';
        prcessObjone.SVMXC__Email_On_Error__c = 'test@servicemax.com';
        prcessObjone.SVMXC__Email_On_Success__c = 'test@servicemax.com';
        prcessObjone.SVMXC__Weight_Time_Window__c = 1;
        prcessObjone.SVMXC__Weight_Total_Distance__c = 1;
        prcessObjone.SVMXC__Weight_Route_Distance__c = 1;
        prcessObjone.SVMXC__Weight_Route_Time__c = 1;
        prcessObjone.SVMXC__Weight_Node_Type__c = 1;
        prcessObjone.SVMXC__Values__c = territory.id + ':U,';
        prcessObjone.SVMXC__Route_Type__c = 'CLOSED';
        prcessObjone.SVMXC__Dispatch_Threshold__c = 30;
        prcessObjone.SVMXC__Optimizer_Sync_Interval__c = 30;
        prcessObjone.SVMXC__Calendar_End_Days__c = 5;
        insert prcessObjone;
        
        return prcessObjone;
    }
    
    static testMethod void ECO_Client_TechnicianServices_UT3() {
        List<String> lstStrings = new List<String>();
        lstStrings.add('1234');
        WSCH_ECO_Client_TechnicianServices.scheduleEventsInHorizon(lstStrings);
        WSCH_ECO_Client_TechnicianServices.scheduleWOsInHorizon(lstStrings);
        
        WSCH_ECO_Client_TechnicianServices.scheduleEventsInHorizon(null);
        WSCH_ECO_Client_TechnicianServices.scheduleWOsInHorizon(null);
    }
    
    static testMethod void manageWOsInHorizon() {
        SVMXC__Territory__c territory = createTerritory();
        SVMXC__ServiceMax_Processes__c prcessObjone = createDP(territory);
        
        SVMXC__Service_Group__c team = new SVMXC__Service_Group__c();
        team.Name = 'team1';
        insert team;
        
        SVMXC__Service_Group_Members__c technician1 = new SVMXC__Service_Group_Members__c();
        technician1.Name = 'Tech1';
        technician1.SVMXC__Service_Group__c = team.Id;
        insert technician1;
        
        
        SVMXC__SVMX_Optimizer__c optimizer = new SVMXC__SVMX_Optimizer__c();
        optimizer.SVMXC__WhatType__c = 'TECHNICIAN';
        optimizer.SVMXC__WhatId__c = technician1.Id + '_' + technician1.Name;
        optimizer.SVMXC__Optimizer_Connection_ID__c = prcessObjone.id + '_' + territory.id;
        optimizer.SVMXC__Optimizer_Change_Token__c = 'CHANGE_CREATE_TECH';
        optimizer.SVMXC__Optimizer_Status__c = 'OPT_COMPLETED';
        optimizer.SVMXC__Optimizer_Error_Text__c = 'Technician added through initJob call';
        insert optimizer;
        
        RestRequest req = new RestRequest();
        
        req.requestURI = '/services/apexrest/scheduling/eco/technician';
        String reqBody = '{"dispatchProcessGuid":"' + prcessObjone.id + '","territoryGuid":"' + territory.id + '","operation":"WO_UPDATE"}';
        req.requestBody = Blob.valueOf(reqBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        
        Test.startTest();
        String response = WSCH_ECO_Client_TechnicianServices.doPost();
        Test.stopTest();
    }
    
    static testMethod void manageNonWOEventsInHorizon() {
        SVMXC__Territory__c territory = createTerritory();
        SVMXC__ServiceMax_Processes__c prcessObjone = createDP(territory);
        
        SVMXC__Service_Group__c team = new SVMXC__Service_Group__c();
        team.Name = 'team1';
        insert team;
        
        SVMXC__Service_Group_Members__c technician1 = new SVMXC__Service_Group_Members__c();
        technician1.Name = 'Tech1';
        technician1.SVMXC__Service_Group__c = team.Id;
        insert technician1;
        
        
        SVMXC__SVMX_Optimizer__c optimizer = new SVMXC__SVMX_Optimizer__c();
        optimizer.SVMXC__WhatType__c = 'TECHNICIAN';
        optimizer.SVMXC__WhatId__c = technician1.Id + '_' + technician1.Name;
        optimizer.SVMXC__Optimizer_Connection_ID__c = prcessObjone.id + '_' + territory.id;
        optimizer.SVMXC__Optimizer_Change_Token__c = 'CHANGE_CREATE_TECH';
        optimizer.SVMXC__Optimizer_Status__c = 'OPT_COMPLETED';
        optimizer.SVMXC__Optimizer_Error_Text__c = 'Technician added through initJob call';
        insert optimizer;
        
        RestRequest req = new RestRequest();
        
        req.requestURI = '/services/apexrest/scheduling/eco/technician';
        String reqBody = '{"dispatchProcessGuid":"' + prcessObjone.id + '","territoryGuid":"' + territory.id + '","operation":"NON_WO_EVENT_UPDATE"}';
        req.requestBody = Blob.valueOf(reqBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        
        Test.startTest();
        String response = WSCH_ECO_Client_TechnicianServices.doPost();
        WSCH_ECO_Client_TechnicianServices.createOptimizerObject('id', 'CHANGE_CREATE_TECH','TECHNICIAN',prcessObjone.Id,territory.Id,technician1);
        Test.stopTest();
    }
}