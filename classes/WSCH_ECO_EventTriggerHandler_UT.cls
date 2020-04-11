@isTest
public with sharing class WSCH_ECO_EventTriggerHandler_UT {
    //Test Method for handleSFECOEventInsert
     static testMethod void test_handleSFECOEventInsert() {
         WSCH_ECO_EventTriggerHandler handler = new WSCH_ECO_EventTriggerHandler();
    
        SVMXC__Territory__c testTer = createECOTerritory();
        SVMXC__ServiceMax_Processes__c testProcess = createECODispatchProcess(testTer.id);
        SVMXC__Service_Group_Members__c tectTechnician = createECOTechnician(testTer.id);
        
        Event sfTestEvent = createSFEvent(tectTechnician.id);
        List<Event> sfEevents = new List<Event>();
        sfEevents.add(sfTestEvent);  
        
        List<Event> sfEeventsOld = new List<Event>();
        sfEeventsOld = sfEevents;  
        
        SVMXC__SVMX_Event__c svmxEvent = createSVMXECOEVENT(tectTechnician.id);
        List<SVMXC__SVMX_Event__c> svmxEvents = new List<SVMXC__SVMX_Event__c>();
        svmxEvents.add(svmxEvent);
        
        List<SVMXC__SVMX_Event__c> svmxEventsOld = new List<SVMXC__SVMX_Event__c>();
        svmxEventsOld = svmxEvents;
                
        WSCH_ECO_EventTriggerHandler.handleSFECOEventInsert(sfEevents);
        WSCH_ECO_EventTriggerHandler.handleSFECOEventUpdate(sfEevents,sfEeventsOld);
        WSCH_ECO_EventTriggerHandler.handleSFECOEventDelete(sfEevents);
        WSCH_ECO_EventTriggerHandler.handleSVMXECOEventInsert(svmxEvents);
        WSCH_ECO_EventTriggerHandler.handleSVMXECOEventUpdate(svmxEvents,svmxEventsOld);
        WSCH_ECO_EventTriggerHandler.handleSVMXECOEventDelete(svmxEvents);
        WSCH_ECO_EventTriggerHandler.changeSvmxEventToken(svmxEvents[0],svmxEventsOld[0]);
        WSCH_ECO_EventTriggerHandler.changeSFEventToken(sfEevents[0],sfEeventsOld[0]);
        
        //Negative Test Cases to cover the catch block
        WSCH_ECO_EventTriggerHandler.manageNonWorkOrderECOEvents(null);
     }

    
    //private supporting methods
    private static Event createSFEvent(String techId){
        Event ev = new Event();
        ev.EventSubtype  = 'Event';
        ev.StartDateTime = system.today();
        ev.EndDateTime = system.today() + 1;
        ev.WhatId = techId;
        insert ev;
        return ev;
    }
    
    private  static SVMXC__SVMX_Event__c createSVMXECOEVENT(String technician){
        SVMXC__SVMX_Event__c svmxEv = new SVMXC__SVMX_Event__c();
        svmxEv.Name = 'EVMX_EV_UT';
        svmxEv.SVMXC__Technician__c =  technician;
        svmxEv.SVMXC__StartDateTime__c= system.today();
        svmxEv.SVMXC__EndDateTime__c = system.today() + 1;
        
         insert svmxEv;
         return svmxEv;
    }
    
    private static SVMXC__Service_Group_Members__c createECOTechnician(String terId){
        SVMXC__Service_Group_Members__c technician = new SVMXC__Service_Group_Members__c();
        technician.Name = 'ECO_Tech_UT';
        technician.SVMXC__City__c = 'Bangalore';
        technician.SVMXC__Country__c = 'India';
        technician.SVMXC__Zip__c = '560030';
        technician.SVMXC__Service_Territory__c = terId;
        technician.SVMXC__Service_Group__c= createServiceGroupId();
        insert technician;
        return technician;
        
    }
    
    private static String createServiceGroupId(){
     SVMXC__Service_Group__c segroup = new SVMXC__Service_Group__c();
     segroup.Name = 'TestGroup-UT';
     insert segroup;
     return segroup.id;
    }
    
    private static SVMXC__Territory__c createECOTerritory(){
        SVMXC__Territory__c ecoTeritory = new SVMXC__Territory__c();
         ecoTeritory.Name = 'Ter-UT';
         insert ecoTeritory;
         return ecoTeritory;
    }
    
    private static SVMXC__ServiceMax_Processes__c createECODispatchProcess(String terId){
        SVMXC__ServiceMax_Processes__c dprocess = new SVMXC__ServiceMax_Processes__c();
        dprocess.SVMXC__Dispatch_Method__c = 'Real Time Optimization';
        dprocess.SVMXC__Dispatch_Process_Status__c ='Complete';
        dprocess.SVMXC__Dispatch_Timezone__c= 'Asia/Colombo';
        dprocess.SVMXC__Name__c = 'Process-UT';
        dprocess.RecordTypeId = getDispatchProcessRecordId();
        dprocess.SVMXC__Territory__c = terId;
        
        insert dprocess;
        return dprocess;
    }
    
    
    private static String getDispatchProcessRecordId(){
        String dispatchProcessRecordType;
        RecordType[] rts = [SELECT Id, Name, SobjectType FROM RecordType WHERE SobjectType = 'SVMXC__ServiceMax_Processes__c' ];
        for(RecordType rt : rts)
        {
            if(rt.Name == 'Dispatch Process' && rt.SobjectType == 'SVMXC__ServiceMax_Processes__c')
               dispatchProcessRecordType = rt.ID;
        }
        return dispatchProcessRecordType;
        
    }
}