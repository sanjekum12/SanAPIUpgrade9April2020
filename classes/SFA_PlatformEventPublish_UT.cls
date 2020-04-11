/*****************************************************************************
*                       Copyright (C) 2019 ServiceMax, Inc
*                               All rights reserved
*****************************************************************************/

/**
* The UT class for SFA_Platform_Event_publish, SFA_PlatformTriggerHandler
*
* @author Jaysukh Patel
* @version 19.2
* @since 2019
*/
/*****************************************************************************************************
*   Name                   Date              Comment
*****************************************************************************************************
*   Jaysukh Patel        20 March 2019       Created.
*   Soumyaranjan Pati    1st June 2019       Added for SFA_PlatformTriggerHandler
*****************************************************************************************************/

@isTest(seeAlldata=false)
public class SFA_PlatformEventPublish_UT
{
    @testsetup static void setup() {
        SVMXC__ServiceMax_Processes__c objSFMScheduledProcess = new SVMXC__ServiceMax_Processes__c();
        objSFMScheduledProcess.SVMXC__Name__c = 'SVMXSTD Closed Work Orders';
        objSFMScheduledProcess.SVMXC__ProcessID__c = 'SVMXSTD__Closed_Work_Orders';
        objSFMScheduledProcess.SVMXC__Description__c = 'SFM_Scheduled';
        objSFMScheduledProcess.SVMXC__Capture_Log__c = true;
        objSFMScheduledProcess.SVMXC__Dispatch_Timezone__c = 'Asia/Kolkata';
        objSFMScheduledProcess.SVMXC__Assign_To_Dispatcher__c =  UserInfo.getUserId();
        objSFMScheduledProcess.RecordTypeId = [select Id from RecordType where Name='SVMX Rule'and SobjectType='SVMXC__ServiceMax_Processes__c' Limit 1].Id;
        objSFMScheduledProcess.SVMXC__IsStandard__c = false;
        objSFMScheduledProcess.SVMXC__Active__c = true;
        objSFMScheduledProcess.SVMXC__Parent_Object_Criteria__c = 'SVMXC__Order_Status__c=\'Open\'';
        insert objSFMScheduledProcess;

        SVMXC__ServiceMax_Config_Data__c exprDtl = new SVMXC__ServiceMax_Config_Data__c();
        exprDtl.RecordTypeId = [select Id from RecordType where Name='Expressions'and SobjectType='SVMXC__ServiceMax_Config_Data__c' Limit 1].Id;
        exprDtl.SVMXC__Expression_Type__c = 'EXP_Named';
        exprDtl.SVMXC__Expression_Rule__c = objSFMScheduledProcess.Id;
        exprDtl.SVMXC__Field_Name__c = 'SVMXC__Order_Status__c';
        exprDtl.SVMXC__Display_Type__c = 'String';
        insert exprDtl;

        List<SVMXC__SM_SFA_Process__c> lstSFA = new List<SVMXC__SM_SFA_Process__c>();
        SVMXC__SM_SFA_Process__c sfaWO = new SVMXC__SM_SFA_Process__c();
        sfaWO.SVMXC__SM_Expression__c = objSFMScheduledProcess.id;
        sfaWO.SVMXC__SM_Action_Type__c = 'Push Notification';
        sfaWO.SVMXC__SM_Description__c ='Test description';
        sfaWO.SVMXC__SM_Enabled__c = true;
        sfaWO.SVMXC__SM_Event_Type__c = 'Salesforce Event';
        sfaWO.SVMXC__SM_Object_API_Name__c = 'SVMXC__Service_Order__c';
        sfaWO.SVMXC__SM_SFA_Action_JSON__c = '{"Service_Provider":"PUBNUB","Screen_To_Load":"SFM_VIEW","Recipient_Field_API_Names":["OwnerId","SVMXC__Preferred_Technician__c"],"Message_Title":"Test title","Message_Body":"this is for testing Soumyaranjan [$Name] for [$SVMXC__Company__c]","Display_Object_Record":"SVMXC__Service_Order__c","Client_App_Name":"SVMXGO"}';
        sfaWO.SVMXC__SM_SFA_Event_JSON__c = '{"SFDC_Data_Event_Type":"Record_Created","Preview_Field_List":["Name","SVMXC__Order_Status__c","SVMXC__Company__r.Name","SVMXC__Contact__r.Name","SVMXC__Street__c ","SVMXC__City__c","SVMXC__State__c","SVMXC__Zip__c","SVMXC__Country__c","SVMXC__Priority__c"],"Object_API_Name":"SVMXC__Service_Order__c","Event_Trigger_Fields":null}';
        sfaWO.SVMXC__SM_SFA_Process_Id__c ='Test_WO_Process';
        sfaWO.SVMXC__SM_SFA_Process_Name__c = 'Test Wo Process';
        lstSFA.add(sfaWO);
        SVMXC__SM_SFA_Process__c  sfaWO1 = new SVMXC__SM_SFA_Process__c();
        sfaWO1.SVMXC__SM_Action_Type__c = 'Push Notification';
        sfaWO1.SVMXC__SM_Description__c ='Test description';
        sfaWO1.SVMXC__SM_Enabled__c = true;
        sfaWO1.SVMXC__SM_Event_Type__c = 'Salesforce Event';
        sfaWO1.SVMXC__SM_Object_API_Name__c = 'SVMXC__Service_Order__c';
        sfaWO1.SVMXC__SM_SFA_Action_JSON__c = '{"Service_Provider":"PUBNUB","Screen_To_Load":"SFM_VIEW","Recipient_Field_API_Names":["OwnerId","SVMXC__Preferred_Technician__c"],"Message_Title":"Test title","Message_Body":"this is for testing Anil [$Name]","Display_Object_Record":"SVMXC__Service_Order__c","Client_App_Name":"SVMXGO"}';
        sfaWO1.SVMXC__SM_SFA_Event_JSON__c = '{"SFDC_Data_Event_Type":"Record_Field_Updated","Preview_Field_List":["Name","SVMXC__Order_Status__c","SVMXC__Company__r.Name","SVMXC__Contact__r.Name","SVMXC__Street__c ","SVMXC__City__c","SVMXC__State__c","SVMXC__Zip__c","SVMXC__Country__c","SVMXC__Priority__c"],"Object_API_Name":"SVMXC__Service_Order__c","Event_Trigger_Fields":["SVMXC__Street__c"]}';
        sfaWO1.SVMXC__SM_SFA_Process_Id__c ='Test_WO_Process';
        sfaWO1.SVMXC__SM_SFA_Process_Name__c = 'Test Wo Process';
        lstSFA.add(sfaWO1);
        SVMXC__SM_SFA_Process__c sfaSMSWO = new SVMXC__SM_SFA_Process__c();
        sfaSMSWO.SVMXC__SM_Expression__c = objSFMScheduledProcess.id;
        sfaSMSWO.SVMXC__SM_Action_Type__c = 'SMS';
        sfaSMSWO.SVMXC__SM_Description__c ='Test description';
        sfaSMSWO.SVMXC__SM_Enabled__c = true;
        sfaSMSWO.SVMXC__SM_Event_Type__c = 'Salesforce Event';
        sfaSMSWO.SVMXC__SM_Object_API_Name__c = 'SVMXC__Service_Order__c';
        sfaSMSWO.SVMXC__SM_SFA_Action_JSON__c = '{"Service_Provider":"SMS","Recipients":[{"relatedRefNameField":"SVMXC__Company__r","relatedObject":"Account","relatedField":["Phone","Fax"],"relatedCountryField":"BillingCountry","field":"SVMXC__Company__c","country":null,"contactnumber":null},{"relatedRefNameField":"SVMXC__Contact__r","relatedObject":"Contact","relatedField":["Fax","MobilePhone"],"relatedCountryField":"MailingCountry","field":"SVMXC__Contact__c","country":null,"contactnumber":null},{"relatedRefNameField":"SVMXC__Group_Member__r","relatedObject":"SVMXC__Service_Group_Members__c","relatedField":["SVMXC__Phone__c"],"relatedCountryField":"SVMXC__Country__c","field":"SVMXC__Group_Member__c","country":null,"contactnumber":null},{"relatedRefNameField":null,"relatedObject":null,"relatedField":null,"relatedCountryField":null,"field":"addition_number","country":"US","contactnumber":"9258767676"}],"Message_Body":"some text  [$SVMXC__Company__c] [$SVMXC__Age__c] [$SVMXC__Age_Bucket__c]","Display_Object_Record":"SVMXC__Service_Order__c"}';
        sfaSMSWO.SVMXC__SM_SFA_Event_JSON__c = '{"SFDC_Data_Event_Type": "Record_Created_or_Updated","Preview_Field_List": ["Name","SVMXC__Order_Status__c","SVMXC__Company__r.Name","SVMXC__Contact__r.Name","SVMXC__Street__c ","SVMXC__City__c","SVMXC__State__c","SVMXC__Zip__c","SVMXC__Country__c","SVMXC__Priority__c"],"Object_API_Name": "SVMXC__Service_Order__c","Event_Trigger_Fields": null}';
        sfaSMSWO.SVMXC__SM_SFA_Process_Id__c ='SMS_CONFIG_TEST';
        sfaSMSWO.SVMXC__SM_SFA_Process_Name__c = 'sms config test';
        lstSFA.add(sfaSMSWO);

        SVMXC__SM_SFA_Process__c sfaInterativeActionWO = new SVMXC__SM_SFA_Process__c();
        sfaInterativeActionWO.SVMXC__SM_Expression__c = objSFMScheduledProcess.id;
        sfaInterativeActionWO.SVMXC__SM_Action_Type__c = 'Push Notification';
        sfaInterativeActionWO.SVMXC__SM_Description__c ='Test description';
        sfaInterativeActionWO.SVMXC__SM_Enabled__c = true;
        sfaInterativeActionWO.SVMXC__SM_Event_Type__c = 'Salesforce Event';
        sfaInterativeActionWO.SVMXC__SM_Object_API_Name__c = 'SVMXC__Service_Order__c';
        sfaInterativeActionWO.SVMXC__SM_SFA_Action_JSON__c = '{"Service_Provider":"PUBNUB","Screen_To_Load":"SFM_VIEW","Recipient_Related_Field_API_Names":null,"Recipient_Field_API_Names":["OwnerId"],"Message_Title":"Test Interactive Action Vasu","Message_Body":"Test Interactive Action Vasu ","IsInteractiveAction":true,"InteractiveActions":[{"Target_Process_Id":"a122I00000Dq70BQAR","Process_Type":"SFM","Is_Background":false,"Button_Title":"Test Button 1","Button_Id":"SFA_Action_bf21cce0-1b92-11ea-b4c1-f9d16387e8f7"},{"Target_Process_Id":"a122I00000E1UoZQAV","Process_Type":"SFM","Is_Background":false,"Button_Title":"Test Button 2","Button_Id":"SFA_Action_c50b9ff0-1b92-11ea-b4c1-f9d16387e8f7"},{"Target_Process_Id":"a122I00000E3Q44QAF","Process_Type":"SFM","Is_Background":false,"Button_Title":"Test Button 3","Button_Id":"SFA_Action_cb942400-1b92-11ea-b4c1-f9d16387e8f7"}],"Display_Object_Record":"SVMXC__Service_Order__c","Client_App_Name":"SVMXGO"}';
        sfaInterativeActionWO.SVMXC__SM_SFA_Event_JSON__c = '{"SFDC_Data_Event_Type":"Record_Created_or_Updated","Preview_Field_List":["Name","SVMXC__Order_Status__c","SVMXC__Company__r.Name","SVMXC__Contact__r.Name","SVMXC__Street__c ","SVMXC__City__c","SVMXC__State__c","SVMXC__Zip__c","SVMXC__Country__c","SVMXC__Priority__c"],"Object_API_Name":"SVMXC__Service_Order__c","Event_Trigger_Fields":null}';
        sfaInterativeActionWO.SVMXC__SM_SFA_Process_Id__c ='SFA_INTERACTIVE_ACTION_CONFIG_TEST';
        sfaInterativeActionWO.SVMXC__SM_SFA_Process_Name__c = 'SFA_INTERACTIVE_ACTION_CONFIG_TEST';
        lstSFA.add(sfaInterativeActionWO);

        insert lstSFA;

        SVMXC__ServiceMax_Properties__c smsProperty = new SVMXC__ServiceMax_Properties__c();
        smsProperty.SVMXC__Value__c = 'SMS_Client_Token_001';
        smsProperty.Name = 'SMS_CLIENT_TOKEN';
        smsProperty.SVMXC__Key__c = 'SMS_CLIENT_TOKEN';
        insert smsProperty;

        SVMXC__SM_SFA_Process__c sfaWOFieldUpdate = new SVMXC__SM_SFA_Process__c();
        sfaWOFieldUpdate.SVMXC__SM_Action_Type__c = 'Push Notification';
        sfaWOFieldUpdate.SVMXC__SM_Description__c ='Field Update SFA Test for unit testing';
        sfaWOFieldUpdate.SVMXC__SM_Enabled__c = true;
        sfaWOFieldUpdate.SVMXC__SM_Event_Type__c = 'Salesforce Event';
        sfaWOFieldUpdate.SVMXC__SM_Object_API_Name__c = 'SVMXC__Service_Order__c';
        sfaWOFieldUpdate.SVMXC__SM_SFA_Action_JSON__c = '{"Service_Provider":"PUBNUB","Screen_To_Load":"SFM_VIEW","Recipient_Related_Field_API_Names":null,"Recipient_Field_API_Names":["OwnerId"],"Message_Title":"Field Update SFA Test","Message_Body":"Field Update SFA Test date field value [$SVMXC__Scheduled_Date__c] \ndate time field value [$SVMXC__Canceled_Date_Time__c]","IsInteractiveAction":true,"InteractiveActions":[{"Target_Process_Id":"046339_Check_fields_not_inPL","Process_Type":"SFM","Is_Background":false,"Button_Title":"Button-1","Button_Id":"SFA_Action_1bcf5d90-5f18-11ea-9d9d-ab2990bd3338"}],"Display_Object_Record":"SVMXC__Service_Order__c","Client_App_Name":"SVMXGO"}';
        sfaWOFieldUpdate.SVMXC__SM_SFA_Event_JSON__c = '{"SFDC_Data_Event_Type":"Record_Field_Updated","Preview_Field_List":["Name","SVMXC__Order_Status__c","SVMXC__Company__r.Name","SVMXC__Contact__r.Name","SVMXC__Street__c ","SVMXC__City__c","SVMXC__State__c","SVMXC__Zip__c","SVMXC__Country__c","SVMXC__Priority__c"],"Object_API_Name":"SVMXC__Service_Order__c","Event_Trigger_Fields":["SVMXC__Age__c","SVMXC__Billing_Type__c","SVMXC__City__c"]}';
        sfaWOFieldUpdate.SVMXC__SM_SFA_Process_Id__c ='FIELD_UPDATE_SFA_TEST';
        sfaWOFieldUpdate.SVMXC__SM_SFA_Process_Name__c = 'Field Update SFA Test';
        lstSFA.add(sfaWOFieldUpdate);
    }

    static testMethod void PublishEventUpdateInsertWORD_UT()
    {
        String objectName = 'SVMXC__Service_Order__c';
        String query=getFieldSetFields(objectName,'SVMXC__SM_SFA_Fields_WORD');
        System.debug(query);
        SFA_PlatformEventPublish sfAplaformevent= new SFA_PlatformEventPublish();
        List<SVMXC__Service_Order__c> woLst = new List<SVMXC__Service_Order__c>();
        SVMXC__Service_Order__c objtoinsert = new SVMXC__Service_Order__c();
        objtoinsert.SVMXC__City__c = 'Ahmedabad';
        woLst.add(objtoinsert);
        insert woLst;
        String ids = woLst[0].id;
        query = query +' from '+objectName + ' where ' +'id =\''+ ids +'\'';
        System.debug(query);
        List<SVMXC__Service_Order__c> lstWo = Database.query(query);
        SFA_PlatformEventpublish sfplatevent = new SFA_PlatformEventpublish();
        sfplatevent.publishEventAfterInsert(lstWo,objectName);
        List<SVMXC__Service_Order__c> woLst1 = woLst;
        woLst1[0].SVMXC__City__c ='Bangalore';
        update woLst1[0];
        sfplatevent.publishEventAfterUpdate(woLst1,woLst1,objectName);
    }

    static testMethod void PublishEventUpdateInsertEvent_UT()
    {
        String objectName = 'Event';
        String query=getFieldSetFields(objectName,'SVMXC__SM_SFA_Fields_EVENT');
        System.debug(query);
        SFA_PlatformEventPublish sfAplaformevent= new SFA_PlatformEventPublish();
        List<Event> evLst = new List<Event>();
        Event objtoinsert = new Event();
        objtoinsert.StartDateTime = System.today();
        objtoinsert.EndDateTime = System.today()+2;
        evLst.add(objtoinsert);
        insert evLst;
        String ids = evLst[0].id;
        query = query +' from '+objectName + ' where ' +'id =\''+ ids +'\'';
        System.debug(query);
        List<Event> lsteve = Database.query(query);
        SFA_PlatformEventpublish sfplatevent = new SFA_PlatformEventpublish();
        sfplatevent.publishEventAfterInsert(lsteve,objectName);
        List<Event> evLst1 = evLst;
        evLst1[0].StartDateTime = System.today()+1;
        update evLst1[0];
        sfplatevent.publishEventAfterUpdate(evLst1,evLst1,objectName);
    }

    static testMethod void PublishEventUpdateInsertSVMXEvent_UT()
    {
        String objectName = 'SVMXC__SVMX_Event__c';
        String query=getFieldSetFields(objectName,'SVMXC__SM_SFA_Fields_SVMXEVENT');
        System.debug(query);
        SFA_PlatformEventPublish sfAplaformevent= new SFA_PlatformEventPublish();
        List<SVMXC__SVMX_Event__c> evLst = new List<SVMXC__SVMX_Event__c>();
        SVMXC__SVMX_Event__c objtoinsert = new SVMXC__SVMX_Event__c();
        objtoinsert.SVMXC__StartDateTime__c = System.today();
        objtoinsert.SVMXC__EndDateTime__c = System.today()+2;
        evLst.add(objtoinsert);
        insert evLst;
        String ids = evLst[0].id;
        query = query +' from '+objectName + ' where ' +'id =\''+ ids +'\'';
        System.debug(query);
        List<SVMXC__SVMX_Event__c> lstWo = Database.query(query);
        SFA_PlatformEventpublish sfplatevent = new SFA_PlatformEventpublish();
        sfplatevent.publishEventAfterInsert(lstWo,objectName);
        List<SVMXC__SVMX_Event__c> evLst1 = evLst;
        evLst1[0].SVMXC__StartDateTime__c = System.today()+1;
        update evLst1[0];
        sfplatevent.publishEventAfterUpdate(evLst1,evLst1,objectName);
    }

    public static String getFieldSetFields(String objectname,String fieldSetName)
    {
        String query = 'SELECT ID,';
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();

        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        List<Schema.FieldSetMember> fields = fieldSetObj.getFields();
        //List<String> lstOfField= new List<String>();
        if(fields!=null && fields.size() >0)
        {
            for(Schema.FieldSetMember member:fields )
            {
                if(member.getFieldPath().equalsIgnoreCase('ID'))
                {
                    continue;
                }
                //lstOfField.add(member.getFieldPath());
                query = query + member.getFieldPath()+',';
            }
        }
        String query1 = query.substring(0, query.length()-1);
        return query1;
    }

    static testMethod void trigger_SFA_Push_Notifiaction_UT(){
        SVMXC__SFA_Platform_Event__e plEvent = new SVMXC__SFA_Platform_Event__e();
        plEvent.SVMXC__New_Record_JSON__c = 'TestJSon';
        plEvent.SVMXC__Record_Id__c = '123456789710';
        plEvent.SVMXC__Event_Type__c = 'Inserted';
        plEvent.SVMXC__Object_Name__c = 'SVMXC__Service_order__c';
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(plEvent);
        Test.stopTest();
        System.assertEquals(true, sr.isSuccess());

    }

    static testMethod void trigger_SFA_Push_Notifiaction_TriggerHandler(){
        setup();

        SVMXC__Service_Group__c sgm = new SVMXC__Service_Group__c();
        sgm.Name = 'Bhubaneswar tech';
        sgm.SVMXC__Active__c = true;
        insert sgm;
        SVMXC__Service_Group_Members__c tech = new SVMXC__Service_Group_Members__c();
        tech.Name = 'Test Service members';
        tech.SVMXC__Service_Group__c = sgm.id;
        insert tech;
        SVMXC__Service_Order__c objtoinsert = new SVMXC__Service_Order__c();
        objtoinsert.SVMXC__City__c = 'Bhubaneswar';
        objtoinsert.SVMXC__Order_Status__c ='Open';
        objtoinsert.SVMXC__Preferred_Technician__c = tech.id;
        insert objtoinsert;
        SVMXC__SFA_Platform_Event__e plEvent = new SVMXC__SFA_Platform_Event__e();
        plEvent.SVMXC__New_Record_JSON__c = 'TestJSon';
        plEvent.SVMXC__Record_Id__c = String.valueOf(objtoinsert.id);
        plEvent.SVMXC__Event_Type__c = 'Inserted';
        plEvent.SVMXC__Object_Name__c = 'SVMXC__Service_Order__c';
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(plEvent);
        Test.stopTest();
        System.assertEquals(true, sr.isSuccess());
    }

    static testMethod void trigger_SFA_Push_Notifiaction_TriggerHandlerWoEdit(){
        setup();

        SVMXC__Service_Group__c sgm = new SVMXC__Service_Group__c();
        sgm.Name = 'Bhubaneswar tech';
        sgm.SVMXC__Active__c = true;
        insert sgm;
        SVMXC__Service_Group_Members__c tech = new SVMXC__Service_Group_Members__c();
        tech.Name = 'Test Service members';
        tech.SVMXC__Service_Group__c = sgm.id;
        insert tech;
        SVMXC__Service_Order__c objtoinsert = new SVMXC__Service_Order__c();
        objtoinsert.SVMXC__City__c = 'Bhubaneswar';
        objtoinsert.SVMXC__Order_Status__c ='Open';
        objtoinsert.SVMXC__Preferred_Technician__c = tech.id;
        insert objtoinsert;

        SFA_WrapperDef.SFA_RecordWrapper old_Record = new SFA_WrapperDef.SFA_RecordWrapper();
        SFA_WrapperDef.SFA_RecordWrapper new_Record = new SFA_WrapperDef.SFA_RecordWrapper();

        old_Record.mapfieldNameValues.put('SVMXC__Street__c','Bhubaneswar');
        new_Record.mapfieldNameValues.put('SVMXC__Street__c','Cuttack');

        String strOldObjJson = JSON.serialize(old_Record);
        String strNewObjJson = JSON.serialize(new_Record);
        SVMXC__SFA_Platform_Event__e plEvent = new SVMXC__SFA_Platform_Event__e();
        plEvent.SVMXC__New_Record_JSON__c = strOldObjJson;
        plEvent.SVMXC__Old_Record_JSON__c = strNewObjJson;
        plEvent.SVMXC__Record_Id__c = String.valueOf(objtoinsert.id);
        plEvent.SVMXC__Event_Type__c = 'Updated';
        plEvent.SVMXC__Object_Name__c = 'SVMXC__Service_Order__c';
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(plEvent);
        Test.stopTest();
        System.assertEquals(true, sr.isSuccess());
    }

    static testMethod void trigger_SFA_Push_Notifiaction_TriggerHandlerforEvents(){
        SVMXC__SM_SFA_Process__c  sfaWO = new SVMXC__SM_SFA_Process__c();
        sfaWO.SVMXC__SM_Action_Type__c = 'Push Notification';
        sfaWO.SVMXC__SM_Description__c ='Test description';
        sfaWO.SVMXC__SM_Enabled__c = true;
        sfaWO.SVMXC__SM_Event_Type__c = 'Salesforce Event';
        sfaWO.SVMXC__SM_Object_API_Name__c = 'Event';
        sfaWO.SVMXC__SM_SFA_Action_JSON__c = '{"Service_Provider":"PUBNUB","Screen_To_Load":"SFM_VIEW","Recipient_Field_API_Names":["OwnerId"],"Message_Title":"Test Salesforce events","Message_Body":"This is a test message for Salesforce events  [$Subject]","Display_Object_Record":"Event","Client_App_Name":"SVMXGO"}';
        sfaWO.SVMXC__SM_SFA_Event_JSON__c = '{"SFDC_Data_Event_Type":"Record_Created","Preview_Field_List":["StartDateTime","EndDateTime","Name","SVMXC__Order_Status__c","SVMXC__Company__r.Name","SVMXC__Contact__r.Name","SVMXC__Street__c","SVMXC__City__c","SVMXC__State__c","SVMXC__Zip__c","SVMXC__Country__c","SVMXC__Priority__c"],"Object_API_Name":"Event","Event_Trigger_Fields":["WhoId"]}';
        sfaWO.SVMXC__SM_SFA_Process_Id__c ='Test_WO_Process';
        sfaWO.SVMXC__SM_SFA_Process_Name__c = 'Test Wo Process';
        insert sfaWO;
        SVMXC__Service_Order__c objtoinsert = new SVMXC__Service_Order__c();
        objtoinsert.SVMXC__City__c = 'Bhubaneswar';
        objtoinsert.SVMXC__Order_Status__c ='Open';
        insert objtoinsert;
        Event noAppointmentKept = new Event(StartDateTime=system.today(),EndDateTime=system.today()+5,Subject = 'Call', WhatId = objtoinsert.id);

        insert noAppointmentkept;
        SVMXC__SFA_Platform_Event__e plEvent = new SVMXC__SFA_Platform_Event__e();
        plEvent.SVMXC__New_Record_JSON__c = 'TestJSon';
        plEvent.SVMXC__Record_Id__c = String.valueOf(noAppointmentkept.id);
        plEvent.SVMXC__Event_Type__c = 'Inserted';
        plEvent.SVMXC__Object_Name__c = 'Event';
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(plEvent);
        Test.stopTest();
        System.assertEquals(true, sr.isSuccess());
    }

    static testMethod void trigger_SFA_Push_Notifiaction_TriggerHandlerforSVMXEvents(){
        SVMXC__SM_SFA_Process__c  sfaWO = new SVMXC__SM_SFA_Process__c();
        sfaWO.SVMXC__SM_Action_Type__c = 'Push Notification';
        sfaWO.SVMXC__SM_Description__c ='Test description';
        sfaWO.SVMXC__SM_Enabled__c = true;
        sfaWO.SVMXC__SM_Event_Type__c = 'Salesforce Event';
        sfaWO.SVMXC__SM_Object_API_Name__c = 'SVMXC__SVMX_Event__c';
        sfaWO.SVMXC__SM_SFA_Action_JSON__c = '{"Service_Provider":"PUBNUB","Screen_To_Load":"SFM_VIEW","Recipient_Field_API_Names":["OwnerId"],"Message_Title":"Test Salesforce events","Message_Body":"This is a test message for Salesforce events  [$Name]","Display_Object_Record":"SVMXC__SVMX_Event__c","Client_App_Name":"SVMXGO"}';
        sfaWO.SVMXC__SM_SFA_Event_JSON__c = '{"SFDC_Data_Event_Type":"Record_Created","Preview_Field_List":["SVMXC__StartDateTime__c","SVMXC__EndDateTime__c","SVMXC__Service_Order__r.Name","SVMXC__Service_Order__r.SVMXC__Company__r.Name","SVMXC__Service_Order__r.SVMXC__Contact__r.Name","SVMXC__Service_Order__r.SVMXC__Order_Status__c","SVMXC__Service_Order__r.SVMXC__Street__c ","SVMXC__Service_Order__r.SVMXC__City__c","SVMXC__Service_Order__r.SVMXC__State__c","SVMXC__Service_Order__r.SVMXC__Zip__c","SVMXC__Service_Order__r.SVMXC__Country__c","SVMXC__Service_Order__r.SVMXC__Priority__c"],"Object_API_Name":"SVMXC__SVMX_Event__c","Event_Trigger_Fields":null}';
        sfaWO.SVMXC__SM_SFA_Process_Id__c ='Test_WO_Process';
        sfaWO.SVMXC__SM_SFA_Process_Name__c = 'Test Wo Process';
        insert sfaWO;
        SVMXC__Service_Order__c objtoinsert = new SVMXC__Service_Order__c();
        objtoinsert.SVMXC__City__c = 'Bhubaneswar';
        objtoinsert.SVMXC__Order_Status__c ='Open';
        insert objtoinsert;
        SVMXC__SVMX_Event__c noAppointmentKept = new SVMXC__SVMX_Event__c(SVMXC__StartDateTime__c=system.today(),SVMXC__EndDateTime__c=system.today()+5,Name = 'Call', SVMXC__Service_Order__c = objtoinsert.id);

        insert noAppointmentkept;
        SVMXC__SFA_Platform_Event__e plEvent = new SVMXC__SFA_Platform_Event__e();
        plEvent.SVMXC__New_Record_JSON__c = 'TestJSon';
        plEvent.SVMXC__Record_Id__c = String.valueOf(noAppointmentkept.id);
        plEvent.SVMXC__Event_Type__c = 'Inserted';
        plEvent.SVMXC__Object_Name__c = 'SVMXC__SVMX_Event__c';
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(plEvent);
        Test.stopTest();
        System.assertEquals(true, sr.isSuccess());
    }
}