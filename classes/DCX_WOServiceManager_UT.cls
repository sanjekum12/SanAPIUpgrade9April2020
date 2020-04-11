/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest (SeeAllData=false)

private class DCX_WOServiceManager_UT {
@testSetup static void setup() {
        SVMXC__ServiceMax_Config_Data__c globalProfile = new SVMXC__ServiceMax_Config_Data__c();
        List<SVMXC__ServiceMax_Config_Data__c> configDataList = 
            new List<SVMXC__ServiceMax_Config_Data__c>();
        List<SVMXC__ServiceMax_Processes__c> settingValues = new List<SVMXC__ServiceMax_Processes__c>();

        globalProfile.recordTypeId = COMM_RecordTypeUtilities.getObjectRecordTypeId('SVMXC__ServiceMax_Config_Data__c', 'Configuration_Profile');
        globalProfile.SVMXC__Configuration_Type__c = 'Global'; 
        globalProfile.SVMXC__Active__c = true;
        insert globalProfile;

        SVMXC__ServiceMax_Processes__c dcon001Process = new SVMXC__ServiceMax_Processes__c();
        dcon001Process.SVMXC__SubmoduleID__c = 'DCON001';
        dcon001Process.SVMXC__MapID__c = 'dcon001Process';
        insert dcon001Process;

        SVMXC__ServiceMax_Processes__c set001Process = new SVMXC__ServiceMax_Processes__c();
        set001Process.SVMXC__SettingID__c = 'SET001';
        set001Process.SVMXC__MapID__c = 'set001Process';
        set001Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set001Process);

        SVMXC__ServiceMax_Processes__c set004Process = new SVMXC__ServiceMax_Processes__c();
        set004Process.SVMXC__SettingID__c = 'SET004';
        set004Process.SVMXC__MapID__c = 'set004Process';
        set004Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set004Process);

        SVMXC__ServiceMax_Processes__c set024Process = new SVMXC__ServiceMax_Processes__c();
        set024Process.SVMXC__SettingID__c = 'SET024';
        set024Process.SVMXC__MapID__c = 'set024Process';
        set024Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set024Process);

        SVMXC__ServiceMax_Processes__c set025Process = new SVMXC__ServiceMax_Processes__c();
        set025Process.SVMXC__SettingID__c = 'SET025';
        set025Process.SVMXC__MapID__c = 'set025Process';
        set025Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set025Process);

        SVMXC__ServiceMax_Processes__c set026Process = new SVMXC__ServiceMax_Processes__c();
        set026Process.SVMXC__SettingID__c = 'SET026';
        set026Process.SVMXC__MapID__c = 'set026Process';
        set026Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set026Process);

        SVMXC__ServiceMax_Processes__c set028Process = new SVMXC__ServiceMax_Processes__c();
        set028Process.SVMXC__SettingID__c = 'SET028';
        set028Process.SVMXC__MapID__c = 'set028Process';
        set028Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set028Process);

        SVMXC__ServiceMax_Processes__c set033Process = new SVMXC__ServiceMax_Processes__c();
        set033Process.SVMXC__SettingID__c = 'SET033';
        set033Process.SVMXC__MapID__c = 'set033Process';
        set033Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set033Process);

        SVMXC__ServiceMax_Processes__c set034Process = new SVMXC__ServiceMax_Processes__c();
        set034Process.SVMXC__SettingID__c = 'SET034';
        set034Process.SVMXC__MapID__c = 'set034Process';
        set034Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set034Process);

        SVMXC__ServiceMax_Processes__c set038Process = new SVMXC__ServiceMax_Processes__c();
        set038Process.SVMXC__SettingID__c = 'SET038';
        set038Process.SVMXC__MapID__c = 'set038Process';
        set038Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set038Process);

        SVMXC__ServiceMax_Processes__c set039Process = new SVMXC__ServiceMax_Processes__c();
        set039Process.SVMXC__SettingID__c = 'SET039';
        set039Process.SVMXC__MapID__c = 'set039Process';
        set039Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set039Process);

        SVMXC__ServiceMax_Processes__c set040Process = new SVMXC__ServiceMax_Processes__c();
        set040Process.SVMXC__SettingID__c = 'SET040';
        set040Process.SVMXC__MapID__c = 'set040Process';
        set040Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set040Process);

        SVMXC__ServiceMax_Processes__c set041Process = new SVMXC__ServiceMax_Processes__c();
        set041Process.SVMXC__SettingID__c = 'SET041';
        set041Process.SVMXC__MapID__c = 'set041Process';
        set041Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set041Process);

        SVMXC__ServiceMax_Processes__c set042Process = new SVMXC__ServiceMax_Processes__c();
        set042Process.SVMXC__SettingID__c = 'SET042';
        set042Process.SVMXC__MapID__c = 'set042Process';
        set042Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set042Process);

        SVMXC__ServiceMax_Processes__c set043Process = new SVMXC__ServiceMax_Processes__c();
        set043Process.SVMXC__SettingID__c = 'SET043';
        set043Process.SVMXC__MapID__c = 'set043Process';
        set043Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set043Process);

        SVMXC__ServiceMax_Processes__c set044Process = new SVMXC__ServiceMax_Processes__c();
        set044Process.SVMXC__SettingID__c = 'SET044';
        set044Process.SVMXC__MapID__c = 'set044Process';
        set044Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set044Process);

        SVMXC__ServiceMax_Processes__c set045Process = new SVMXC__ServiceMax_Processes__c();
        set045Process.SVMXC__SettingID__c = 'SET045';
        set045Process.SVMXC__MapID__c = 'set045Process';
        set045Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set045Process);

        SVMXC__ServiceMax_Processes__c set046Process = new SVMXC__ServiceMax_Processes__c();
        set046Process.SVMXC__SettingID__c = 'SET046';
        set046Process.SVMXC__MapID__c = 'set046Process';
        set046Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set046Process);

        SVMXC__ServiceMax_Processes__c set047Process = new SVMXC__ServiceMax_Processes__c();
        set047Process.SVMXC__SettingID__c = 'SET047';
        set047Process.SVMXC__MapID__c = 'set047Process';
        set047Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set047Process);

        SVMXC__ServiceMax_Processes__c set062Process = new SVMXC__ServiceMax_Processes__c();
        set062Process.SVMXC__SettingID__c = 'SET062';
        set062Process.SVMXC__MapID__c = 'set062Process';
        set062Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set062Process);

        SVMXC__ServiceMax_Processes__c set073Process = new SVMXC__ServiceMax_Processes__c();
        set073Process.SVMXC__SettingID__c = 'SET073';
        set073Process.SVMXC__MapID__c = 'set073Process';
        set073Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set073Process);

        SVMXC__ServiceMax_Processes__c set007Process = new SVMXC__ServiceMax_Processes__c();
        set007Process.SVMXC__SettingID__c = 'SET007';
        set007Process.SVMXC__MapID__c = 'set007Process';
        set007Process.SVMXC__Submodule__c = dcon001Process.Id;
        settingValues.add(set007Process);
        
        insert settingValues;

        String settingValueRecordTypeId = 
            COMM_RecordTypeUtilities.getObjectRecordTypeId('SVMXC__ServiceMax_Config_Data__c', 'Setting_Value');

        SVMXC__ServiceMax_Config_Data__c set001Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set001Setting.SVMXC__Internal_Value__c = '5';
        set001Setting.SVMXC__Display_Value__c = '5';
        set001Setting.recordtypeid = settingValueRecordTypeId;
        set001Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set001Setting.SVMXC__Setting_ID__c = set001Process.Id;
        configDataList.add(set001Setting);

        SVMXC__ServiceMax_Config_Data__c set004Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set004Setting.SVMXC__Internal_Value__c = 'TEAM';
        set004Setting.SVMXC__Display_Value__c = 'TEAM';
        set004Setting.recordtypeid = settingValueRecordTypeId;
        set004Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set004Setting.SVMXC__Setting_ID__c = set004Process.Id;
        configDataList.add(set004Setting);

        SVMXC__ServiceMax_Config_Data__c set024Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set024Setting.SVMXC__Internal_Value__c = 'False';
        set024Setting.SVMXC__Display_Value__c = 'False';
        set024Setting.recordtypeid = settingValueRecordTypeId;
        set024Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set024Setting.SVMXC__Setting_ID__c = set024Process.Id;
        configDataList.add(set024Setting);

        SVMXC__ServiceMax_Config_Data__c set025Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set025Setting.SVMXC__Internal_Value__c = 'DISALLOW';
        set025Setting.SVMXC__Display_Value__c = 'DISALLOW';
        set025Setting.recordtypeid = settingValueRecordTypeId;
        set025Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set025Setting.SVMXC__Setting_ID__c = set025Process.Id;
        configDataList.add(set025Setting);

        SVMXC__ServiceMax_Config_Data__c set026Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set026Setting.SVMXC__Internal_Value__c = 'TRUE';
        set026Setting.SVMXC__Display_Value__c = 'TRUE';
        set026Setting.recordtypeid = settingValueRecordTypeId;
        set026Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set026Setting.SVMXC__Setting_ID__c = set026Process.Id;
        configDataList.add(set026Setting);

        SVMXC__ServiceMax_Config_Data__c set028Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set028Setting.SVMXC__Internal_Value__c = 'TRUE';
        set028Setting.SVMXC__Display_Value__c = 'TRUE';
        set028Setting.recordtypeid = settingValueRecordTypeId;
        set028Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set028Setting.SVMXC__Setting_ID__c = set028Process.Id;
        configDataList.add(set028Setting);

        SVMXC__ServiceMax_Config_Data__c set033Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set033Setting.SVMXC__Internal_Value__c = '10';
        set033Setting.SVMXC__Display_Value__c = '10';
        set033Setting.recordtypeid = settingValueRecordTypeId;
        set033Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set033Setting.SVMXC__Setting_ID__c = set033Process.Id;
        configDataList.add(set033Setting);

        SVMXC__ServiceMax_Config_Data__c set034Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set034Setting.SVMXC__Internal_Value__c = '10';
        set034Setting.SVMXC__Display_Value__c = '10';
        set034Setting.recordtypeid = settingValueRecordTypeId;
        set034Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set034Setting.SVMXC__Setting_ID__c = set034Process.Id;
        configDataList.add(set034Setting);

        SVMXC__ServiceMax_Config_Data__c set038Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set038Setting.SVMXC__Internal_Value__c = 'Event.SVMXC__SM_Latitude__c';
        set038Setting.SVMXC__Display_Value__c = 'Event.SVMXC__SM_Latitude__c';
        set038Setting.recordtypeid = settingValueRecordTypeId;
        set038Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set038Setting.SVMXC__Setting_ID__c = set038Process.Id;
        configDataList.add(set038Setting);

        SVMXC__ServiceMax_Config_Data__c set039Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set039Setting.SVMXC__Internal_Value__c = 'Event.SVMXC__SM_Longitude__c';
        set039Setting.SVMXC__Display_Value__c = 'Event.SVMXC__SM_Longitude__c';
        set039Setting.recordtypeid = settingValueRecordTypeId;
        set039Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set039Setting.SVMXC__Setting_ID__c = set039Process.Id;
        configDataList.add(set039Setting);

        SVMXC__ServiceMax_Config_Data__c set040Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set040Setting.SVMXC__Internal_Value__c = 'SVMXC__Order_Status__c';
        set040Setting.SVMXC__Display_Value__c = 'SVMXC__Order_Status__c';
        set040Setting.recordtypeid = settingValueRecordTypeId;
        set040Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set040Setting.SVMXC__Setting_ID__c = set040Process.Id;
        configDataList.add(set040Setting);

        SVMXC__ServiceMax_Config_Data__c set041Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set041Setting.SVMXC__Internal_Value__c = 'SVMXC__Order_Status__c';
        set041Setting.SVMXC__Display_Value__c = 'SVMXC__Order_Status__c';
        set041Setting.recordtypeid = settingValueRecordTypeId;
        set041Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set041Setting.SVMXC__Setting_ID__c = set041Process.Id;
        configDataList.add(set041Setting);

        SVMXC__ServiceMax_Config_Data__c set042Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set042Setting.SVMXC__Internal_Value__c = 'SVMXC__Order_Status__c';
        set042Setting.SVMXC__Display_Value__c = 'SVMXC__Order_Status__c';
        set042Setting.recordtypeid = settingValueRecordTypeId;
        set042Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set042Setting.SVMXC__Setting_ID__c = set042Process.Id;
        configDataList.add(set042Setting);

        SVMXC__ServiceMax_Config_Data__c set043Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set043Setting.SVMXC__Internal_Value__c = 'SVMXC__Order_Status__c';
        set043Setting.SVMXC__Display_Value__c = 'SVMXC__Order_Status__c';
        set043Setting.recordtypeid = settingValueRecordTypeId;
        set043Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set043Setting.SVMXC__Setting_ID__c = set043Process.Id;
        configDataList.add(set043Setting);

        SVMXC__ServiceMax_Config_Data__c set044Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set044Setting.SVMXC__Internal_Value__c = 'SVMXC__Order_Status__c';
        set044Setting.SVMXC__Display_Value__c = 'SVMXC__Order_Status__c';
        set044Setting.recordtypeid = settingValueRecordTypeId;
        set044Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set044Setting.SVMXC__Setting_ID__c = set044Process.Id;
        configDataList.add(set044Setting);

        SVMXC__ServiceMax_Config_Data__c set045Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set045Setting.SVMXC__Internal_Value__c = 'SVMXC__Order_Status__c';
        set045Setting.SVMXC__Display_Value__c = 'SVMXC__Order_Status__c';
        set045Setting.recordtypeid = settingValueRecordTypeId;
        set045Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set045Setting.SVMXC__Setting_ID__c = set045Process.Id;
        configDataList.add(set045Setting);

        SVMXC__ServiceMax_Config_Data__c set046Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set046Setting.SVMXC__Internal_Value__c = 'SVMXC__Order_Status__c';
        set046Setting.SVMXC__Display_Value__c = 'SVMXC__Order_Status__c';
        set046Setting.recordtypeid = settingValueRecordTypeId;
        set046Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set046Setting.SVMXC__Setting_ID__c = set046Process.Id;
        configDataList.add(set046Setting);

         SVMXC__ServiceMax_Config_Data__c set047Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set047Setting.SVMXC__Internal_Value__c = 'SVMXC__Order_Status__c';
        set047Setting.SVMXC__Display_Value__c = 'SVMXC__Order_Status__c';
        set047Setting.recordtypeid = settingValueRecordTypeId;
        set047Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set047Setting.SVMXC__Setting_ID__c = set047Process.Id;
        configDataList.add(set047Setting);

        SVMXC__ServiceMax_Config_Data__c set062Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set062Setting.SVMXC__Internal_Value__c = 'True';
        set062Setting.SVMXC__Display_Value__c = 'True';
        set062Setting.recordtypeid = settingValueRecordTypeId;
        set062Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set062Setting.SVMXC__Setting_ID__c = set062Process.Id;
        configDataList.add(set062Setting);

        SVMXC__ServiceMax_Config_Data__c set073Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set073Setting.SVMXC__Internal_Value__c = '100';
        set073Setting.SVMXC__Display_Value__c = '100';
        set073Setting.recordtypeid = settingValueRecordTypeId;
        set073Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set073Setting.SVMXC__Setting_ID__c = set073Process.Id;
        configDataList.add(set073Setting);

        SVMXC__ServiceMax_Config_Data__c set007Setting =  new SVMXC__ServiceMax_Config_Data__c();
        set007Setting.SVMXC__Internal_Value__c = 'Assigned,Queued';
        set007Setting.SVMXC__Display_Value__c = 'Assigned,Queued';
        set007Setting.recordtypeid = settingValueRecordTypeId;
        set007Setting.SVMXC__Setting_Configuration_Profile__c = globalProfile.Id;
        set007Setting.SVMXC__Setting_ID__c = set007Process.Id;
        configDataList.add(set007Setting);

        insert configDataList;

        User objUser = [SELECT Id,TimeZoneSidKey from User where id = :UserInfo.getUserId()];
        SVMXC__Service_Group__c objTeam = new SVMXC__Service_Group__c (Name = 'TEAM1A');
        insert objTeam;
                
        SVMXC__Territory__c objTerritory = new SVMXC__Territory__c (Name = 'TERRITORY1B');
        insert objTerritory;
        
        SVMXC__Service_Group_Members__c objTechnician = new SVMXC__Service_Group_Members__c (
                                            Name = 'TECH1A' ,
                                            SVMXC__Latitude__c = 40.739582 , 
                                            SVMXC__Longitude__c = -73.980772, 
                                            SVMXC__Service_Group__c = objTeam.Id ,
                                            SVMXC__Service_Territory__c = objTerritory.Id,
                                            SVMXC__Enable_Scheduling__c = true,
                                            SVMXC__Salesforce_User__c = UserInfo.getUserId()
                                            );
        insert objTechnician;

        List<String> techs = new List<String>();
        techs.add(objTechnician.Id);
        Account objAccount = new Account(Name ='AccountAA'  ); 
        insert objAccount;
        

        Contact objContact = new Contact(LastName='Last',AccountId =objAccount.Id);
        insert objContact;
        
        
        Case objCase = new Case(Status ='New', Priority = 'Medium', 
                                        Origin = 'Email',                                        
                                        ContactId = objContact.Id,
                                        AccountId = objAccount.Id                                         
                                        ); 
        Datetime t = system.now();
        SVMXC__Service_Order__c objWorkOrder = new SVMXC__Service_Order__c (
                                            SVMXC__Case__c = objCase.Id , 
                                            SVMXC__Contact__c =objContact.Id, 
                                            SVMXC__Latitude__c = 40.739582 , 
                                            SVMXC__Longitude__c = -73.980772, 
                                            SVMXC__Order_Status__c = 'Open',
                                            SVMXC__Priority__c = 'Medium',
                                            SVMXC__Order_Type__c= 'Field Service',
                                            SVMXC__Group_Member__c = objTechnician.Id,
                                            SVMXC__Preferred_Start_Time__c = t.addHours(4)
                                            );
        insert objWorkOrder;

        

    }
    static testMethod void testFetchEvent() {
        
        list<Event> lstObjSFEvents = new list<Event>();
        Datetime t = system.now();
        List<String> techIds = new List<String>();
        User objUser = [SELECT Id,TimeZoneSidKey from User where id = :UserInfo.getUserId()];
        SVMXC__Service_Group__c objTeam = [Select Id from SVMXC__Service_Group__c where
                                           Name = 'TEAM1A'];
        SVMXC__Service_Group_Members__c objTechnician = [Select Id,SVMXC__Salesforce_User__c from 
                                                         SVMXC__Service_Group_Members__c
                                                         where Name = 'TECH1A'];
        SVMXC__Service_Order__c objWorkOrder = [Select Id from SVMXC__Service_Order__c where 
                                                SVMXC__Group_Member__c = :objTechnician.Id];
        Event e1 = new Event(ActivityDate = Date.Today(),
                             StartDateTime = t,
                             ActivityDateTime = t, 
                             EndDateTime = system.now().addHours(1),
                             DurationInMinutes = 60, Subject = 'test', OwnerId = objTechnician.Id, 
                             WhatId=objWorkOrder.Id, Description='Test Desc',
                             SVMXC__Service_Duration__c = 60);
        lstObjSFEvents.add(e1);
        Event e2 = new Event(ActivityDate = Date.Today(),
                             StartDateTime = t,
                             ActivityDateTime = t, 
                             EndDateTime = system.now().addHours(1),
                             DurationInMinutes = 60, Subject = 'test svmx', 
                             OwnerId = objTechnician.SVMXC__Salesforce_User__c, 
                             WhatId=objWorkOrder.Id, Description='Test Desc',
                             SVMXC__Service_Duration__c = 60);
        lstObjSFEvents.add(e2);

        RecordType RTProcess = [select Id from RecordType where Name = 'View Definition' AND SobjectType= 'SVMXC__ServiceMax_Processes__c' Limit 1];
        RecordType RTCfgDta = [select Id from RecordType where Name = 'View Access' AND SobjectType= 'SVMXC__ServiceMax_Config_Data__c' Limit 1];
            
                RecordType RTNameSearch = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'SVMXC__ServiceMax_Processes__c' and Name = 'View Definition' Limit 1];
        
         SVMXC__ServiceMax_Processes__c objSVMXPrcss = new SVMXC__ServiceMax_Processes__c();
        objSVMXPrcss.RecordTypeId = RTNameSearch.id;
        objSVMXPrcss.SVMXC__Select__c = true;
        objSVMXPrcss.SVMXC__Rule_Type__c = 'Custom View';
        objSVMXPrcss.SVMXC__Source_Object_Name__c = 'SVMXC__Service_Order__c';
        objSVMXPrcss.SVMXC__View_For__c = 'Grid';
        objSVMXPrcss.SVMXC__Values__c = 'Id,Name,SVMXC__Company__r.Name,SVMXC__Contact__r.Name';
        objSVMXPrcss.SVMXC__Parent_Object_Criteria__c = 'Name != \'ABC\'';
       objSVMXPrcss.SVMXC__Ownership_Type__c ='User\'s Records';
        insert objSVMXPrcss;


        String json = '{\"wo_woSelectionColor\":\"16711731\",\"wo_woRules\":[{\"status\":\"TAG168\",\"operand\":[{\"value\":\"Critical\",\"type\":null,\"property\":\"SVMXC__Priority__c\",\"fieldType\":\"picklist\",\"compare\":\"matches\"}],\"name\":\"Critical Work Orders\",\"expression\":\"\",\"color\":\"16750848\"},{\"status\":\"TAG168\",\"operand\":[{\"value\":\"High\",\"type\":null,\"property\":\"SVMXC__Priority__c\",\"fieldType\":\"picklist\",\"compare\":\"matches\"}],\"name\":\"High Priority Work Orders\",\"expression\":\"\",\"color\":\"16737996\"},{\"status\":\"TAG168\",\"operand\":[{\"value\":\"Medium\",\"type\":null,\"property\":\"SVMXC__Priority__c\",\"fieldType\":\"picklist\",\"compare\":\"matches\"}],\"name\":\"Medium Priority Work Orders\",\"expression\":\"\",\"color\":\"16776960\"}],\"wo_woHoverColor\":\"0\",\"wo_woCol\":[{\"width\":\"145\",\"name\":\"Name\"},{\"width\":null,\"name\":\"SVMXC__Actual_Resolution__c\"},{\"width\":null,\"name\":\"SVMXC__City__c\"},{\"width\":null,\"name\":\"SVMXC__Actual_Restoration__c\"},{\"width\":null,\"name\":\"SVMXC__Dispatch_Status__c\"}],\"wo_views\":null,\"wo_viewCounter\":[{\"sortOrder\":\"desc\",\"name\":\"None\",\"id\":null,\"columnIndex\":null,\"column\":\"Name\",\"color\":\"#FF3300\"},{\"sortOrder\":\"desc\",\"name\":\"None\",\"id\":null,\"columnIndex\":null,\"column\":\"Name\",\"color\":\"#FF9501\"},{\"sortOrder\":null,\"name\":\"None\",\"id\":null,\"columnIndex\":null,\"column\":null,\"color\":\"#0070D2\"}],\"wo_unassignWO\":\"false\",\"wo_sortOrder\":\"asc\",\"wo_sortColumn\":\"SVMXC__City__c\",\"wo_schedulingAsLongJob\":\"true\",\"wo_sch_col_fields\":[],\"wo_respectTechnincianWorkHours\":\"true\",\"wo_respectMachineAccessHours\":\"true\",\"wo_resetTime\":\"false\",\"wo_refreshtime\":\"4\",\"wo_isAlldayEvent\":\"false\",\"wo_isAdvMode\":\"false\",\"wo_grid_conf_fields\":[\"Name\",\"SVMXC__Company__c\",\"SVMXC__Contact__c\",\"SVMXC__Case__c\",\"SVMXC__Priority__c\",\"SVMXC__Order_Status__c\",\"SVMXC__Order_Type__c\",\"SVMXC__Dispatch_Status__c\",\"SVMXC__Group_Member__c\",\"SVMXC__City__c\",\"SVMXC__Component__c\",\"SVMXC__State__c\",\"SVMXC__Zip__c\",\"SVMXC__Service_Group__c\",\"SVMXC__Driving_Time__c\",\"SVMXC__Preferred_Start_Time__c\",\"SVMXC__Product__c\",\"SVMXC__Actual_Resolution__c\",\"SVMXC__Actual_Restoration__c\"],\"wo_grid_col_fields\":[],\"wo_filterColumn\":\"Name\",\"wo_doNotOverlapExistingEvents\":\"true\",\"wo_deleteEventWo\":\"false\",\"wo_defaultView\":\"a2421000002OUmZAAW\",\"wo_columnIndex\":\"0\",\"wo_autorefresh\":\"false\",\"tech_workingHoursColor\":\"15197666\",\"tech_viewAllEventsForToday\":\"false\",\"tech_view\":\"territory\",\"tech_toolTipShowDelay\":\"0\",\"tech_toolTipHideDelay\":\"3000\",\"tech_timeIndicatorColor\":\"#b3e5fc\",\"tech_territorySequence\":[],\"tech_techRules\":[{\"status\":\"TAG168\",\"operand\":[{\"value\":\"Call\",\"type\":\"EVENT\",\"property\":\"subject\",\"fieldType\":\"combobox\",\"compare\":\"matches\"}],\"name\":\"Call\",\"expression\":\"\",\"color\":\"16750848\",\"ruleType\":\"EventRule\"},{\"status\":\"TAG168\",\"operand\":[{\"value\":\"Email\",\"type\":\"EVENT\",\"property\":\"subject\",\"fieldType\":\"combobox\",\"compare\":\"matches\"}],\"name\":\"Email\",\"expression\":\"\",\"color\":\"65280\",\"ruleType\":\"EventRule\"},{\"status\":\"TAG168\",\"operand\":[{\"value\":\"Meeting\",\"type\":\"EVENT\",\"property\":\"subject\",\"fieldType\":\"combobox\",\"compare\":\"matches\"}],\"name\":\"Meeting\",\"expression\":\"\",\"color\":\"255\",\"ruleType\":\"EventRule\"},{\"status\":\"TAG168\",\"operand\":[{\"value\":\"Send Letter/Quote\",\"type\":\"EVENT\",\"property\":\"subject\",\"fieldType\":\"COMBOBOX\",\"compare\":\"matches\"}],\"name\":\"Send Letter/Quote\",\"expression\":\"\",\"color\":\"65535\",\"ruleType\":\"EventRule\"},{\"status\":\"TAG168\",\"operand\":[{\"value\":\"Other\",\"type\":\"EVENT\",\"property\":\"subject\",\"fieldType\":\"combobox\",\"compare\":\"matches\"}],\"name\":\"Other\",\"expression\":\"\",\"color\":\"16711935\",\"ruleType\":\"EventRule\"}],\"tech_techCol\":[{\"width\":\"160\",\"name\":\"Name\"}],\"tech_teamSequence\":[],\"tech_showTimeIndicator\":\"true\",\"tech_showSkills\":\"true\",\"tech_showProductExpertise\":\"true\",\"tech_showPrefTech\":\"true\",\"tech_showOptionMenu\":\"true\",\"tech_showFieldUpdates\":\"false\",\"tech_showEligibility\":\"true\",\"tech_searchSkills\":\"true\",\"tech_searchProductExpertise\":\"true\",\"tech_searchPrefTech\":\"true\",\"tech_searchEligibility\":\"true\",\"tech_retainDateOnShowRoute\":\"true\",\"tech_relatedEventColor\":\"10066329\",\"tech_refreshEventsOnChange\":\"false\",\"tech_pinMapActionBar\":\"true\",\"tech_overNightStayColor\":\"0\",\"tech_overheadColor\":\"#f44336\",\"tech_noOfDays\":\"0\",\"tech_mapDefaultZoomLevel\":\"6\",\"tech_mapDefaultLng\":\"78.35261934062497\",\"tech_mapDefaultLat\":\"17.213437680178284\",\"tech_loglevel\":\"WARN\",\"tech_locationBase\":\"home\",\"tech_holidayHoursColor\":\"10592673\",\"tech_favouriteTerritory\":\"\",\"tech_favouriteTeam\":\"\",\"tech_expandedTerritory\":[],\"tech_ExpandedTeam\":[\"'+objTeam.Id+'\"],\"tech_eventRowColor\":\"11723263\",\"tech_enableGoogleMapApi\":\"true\",\"tech_driveColor\":\"#4caf50\",\"tech_defaultWOEventColor\":\"#9c27b0\",\"tech_defaultEventColor\":\"13421568\",\"tech_dcmap\":\"false\",\"tech_dataTipOnClick\":\"false\",\"tech_condition\":\"before\",\"tech_autoSyncServiceDuration\":\"false\",\"tech_autoCalculateEndDate\":\"false\",\"search_techKeyword\":{\"matchcriteria\":\"any\",\"col\":[{\"width\":\"0\",\"name\":\"SVMXC__City__c\"},{\"width\":\"0\",\"name\":\"EXPERTISE\"},{\"width\":\"0\",\"name\":\"Name\"},{\"width\":\"0\",\"name\":\"PRODUCT\"}]},\"search_teamKeyword\":{\"matchcriteria\":\"any\",\"col\":[{\"width\":\"0\",\"name\":\"SVMXC__City__c\"},{\"width\":\"0\",\"name\":\"SVMXC__Country__c\"}]},\"search_keyword\":{\"matchcriteria\":\"\",\"col\":[{\"width\":\"0\",\"name\":\"SVMXC__Zip__c\"},{\"width\":\"0\",\"name\":\"SVMXC__Company__c\"}]},\"map_mapViewportWidth\":\"269\",\"adv_atsSkills\":{\"show\":\"true\",\"search\":\"true\"},\"adv_atsPrefTech\":{\"show\":\"true\",\"search\":\"true\"},\"adv_atsExpertise\":{\"show\":\"true\",\"search\":\"true\"},\"adv_atsEligibility\":{\"show\":\"true\",\"search\":\"true\"}}';

        DCX_SettingServiceManager.saveUserSettings(json);
        
        list<DCON_Configuration_WS.SVMX_StringMap> lstKeyValue = new list<DCON_Configuration_WS.SVMX_StringMap>();
        lstKeyValue.add(new DCON_Configuration_WS.SVMX_StringMap('IDLE_' + objWorkOrder.Id, '10'));
        lstKeyValue.add(new DCON_Configuration_WS.SVMX_StringMap('DRIVE_' + objWorkOrder.Id, '10'));
        lstKeyValue.add(new DCON_Configuration_WS.SVMX_StringMap('SERVICE_' + objWorkOrder.Id, '10'));
        List<String> dispStatus = new List<String>();
        List<String> Woids = new List<String>();
        List<Event> SFEvent = new List<Event>();
        List<String> EventIds = new List<String>();
         List<DCON_Configuration_WS.SVMX_StringMap> lstKeyValue1 = new List<DCON_Configuration_WS.SVMX_StringMap>();


        Woids.add(objWorkOrder.Id);
        dispStatus.add('NEW');
        dispStatus.add('ASSIGNED');
        SFEvent.add(e1);
        String str = e1.Id;
        EventIds.add(str);
        lstKeyValue1.add(new DCON_Configuration_WS.SVMX_StringMap('IDLE_' + objWorkOrder.Id, '10'));
        lstKeyValue1.add(new DCON_Configuration_WS.SVMX_StringMap('DRIVE_' + objWorkOrder.Id, '10'));
        lstKeyValue1.add(new DCON_Configuration_WS.SVMX_StringMap('SERVICE_' + objWorkOrder.Id, '60'));

        DCX_WOServiceManager.DCON_WO_MultiAssign_Request req = new DCX_WOServiceManager.DCON_WO_MultiAssign_Request();
        req.workOrderIds = Woids;
        req.technicianIds = TechIds;
        req.operationType = 'WO_UNASSIGN_12';
        req.timezone = 'America/Indiana/Indianapolis';
        req.Eventlist = SFEvent;
        req.EventIds = EventIds;
        req.lstKeyValue = lstKeyValue1;
        req.getworkOrderIds();
        req.setworkOrderIds(Woids);
        req.getEventlist();
        req.setEventlist(SFEvent);


        Test.startTest();
        DCX_WOServiceManager.retrieveWorkOrders( objSVMXPrcss.id,true,  dispStatus, NULL,NULL,'Name',true,'Name','0');
        DCX_WOServiceManager.retrieveWorkOrders ('', true, dispStatus, Woids, '100', 'Name', true, 'Name', '0');

        DCX_WOServiceManager.singleWO(objWorkOrder.Id,true);
         //DCX_WOServiceManager.retrieveWorkOrdersForIds(Woids);

DCX_WOServiceManager.DCX_Manage_Work_Order_MultiAssign_WS(req);
        Test.stopTest();
    }

    
     @isTest 
   public static void testUT()
    {
        SVMXC__Service_Order__c obj = new SVMXC__Service_Order__c();
        obj.SVMXC__Order_Type__c='Field Service';
        List<SVMXC__Service_Order__c> objLst =new List<SVMXC__Service_Order__c>();
        objLst.add(obj);
        Integer i =10;
        Long l =1005555555;
        List<String> str = new List<String>();
        List<DCX_WOServiceManager.DC_StringListMap> objMap = new List<DCX_WOServiceManager.DC_StringListMap>();
        DCX_WOServiceManager.workorderDCx objworkorderDCx= new DCX_WOServiceManager.workorderDCx(i,true,'/apex/conf_setupHome',l,objLst,null,'ServiceMAX',null,null);
        DCX_WOServiceManager.workorderDCx_INT objworkorderDCx1= new DCX_WOServiceManager.workorderDCx_INT(i,true,'/apex/conf_setupHome',objLst);
        DCX_WOServiceManager.LocalTimeZone objworkorderDCx2= new DCX_WOServiceManager.LocalTimeZone('','','','');

        DCX_WOServiceManager.DC_StringListMap StringListMap= new DCX_WOServiceManager.DC_StringListMap();
        StringListMap.key = '';
        StringListMap.valueList = null;
        StringListMap.fieldsToNull=null;
        StringListMap.getvalueList();
        StringListMap.setvalueList(str);
         DCX_WOServiceManager.DC_StringListMap StringListMap1= new DCX_WOServiceManager.DC_StringListMap('',str);
        //DCxWOServiceManager.retrieveWorkOrdersJsr('');


        DCX_WOServiceManager.DCON_WO_MultiAssign_Response resp= new DCX_WOServiceManager.DCON_WO_MultiAssign_Response();
        resp.getlstTechEventDetails();
        resp.setlstTechEventDetails(objMap);
    }

    @isTest 
  public static void testUT_12()
    {
        SVMXC__Service_Group__c objTeam = [Select Id from SVMXC__Service_Group__c where
                                           Name = 'TEAM1A'];
        SVMXC__Service_Group_Members__c Tech1 = [Select Id,SVMXC__Salesforce_User__c from 
                                                         SVMXC__Service_Group_Members__c
                                                         where Name = 'TECH1A'];
        SVMXC__Service_Order__c objWorkOrder = [Select Id from SVMXC__Service_Order__c where 
                                                SVMXC__Group_Member__c = :Tech1.Id];

        List<String> woids = new List<String> ();
        woids.add(objWorkOrder.Id);

        List<String> techIds = new List<String> ();
        techIds.add(Tech1.Id);
         List<SVMXC__SVMX_Event__c> SVMXEvent = new List<SVMXC__SVMX_Event__c>();
        SVMXC__SVMX_Event__c SMAX_Event1 = new SVMXC__SVMX_Event__c(
                                                    SVMXC__ActivityDate__c = Date.Today(), 
                                                    SVMXC__ActivityDateTime__c = Datetime.valueOf('2010-02-11 01:00:00'), 
                                                    SVMXC__StartDateTime__c = Datetime.valueOf('2010-02-11 01:00:00') ,
                                                    SVMXC__DurationInMinutes__c = 1440,
                                                    SVMXC__EndDateTime__c = Datetime.valueOf('2010-02-11 02:00:00') ,
                                                    SVMXC__Technician__c = Tech1.Id,
                                                    SVMXC__WhatId__c = objWorkOrder.Id,
                                                    SVMXC__SM_Latitude__c = 10,
                                                    SVMXC__IsAllDayEvent__c = true
                                                    );
        SVMXEvent.add(SMAX_Event1);
        SVMXC__SVMX_Event__c SMAX_Event2 = new SVMXC__SVMX_Event__c(
                                                    SVMXC__ActivityDate__c = Date.Today(), 
                                                    SVMXC__ActivityDateTime__c = Datetime.valueOf('2010-02-11 01:00:00'), 
                                                    SVMXC__StartDateTime__c = Datetime.valueOf('2010-02-11 01:00:00') ,
                                                    SVMXC__DurationInMinutes__c = 60,
                                                    SVMXC__EndDateTime__c = Datetime.valueOf('2010-02-11 02:00:00') ,
                                                    SVMXC__Technician__c = Tech1.Id,
                                                    SVMXC__WhatId__c = objWorkOrder.Id
                                                    );
        SVMXEvent.add(SMAX_Event2);
        SVMXC__SVMX_Event__c SMAX_Event3 = new SVMXC__SVMX_Event__c(
                                                    SVMXC__ActivityDate__c = Date.Today(), 
                                                    SVMXC__ActivityDateTime__c = Datetime.valueOf('2010-02-11 01:00:00'), 
                                                    SVMXC__StartDateTime__c = Datetime.valueOf('2010-02-11 01:00:00') ,
                                                    SVMXC__DurationInMinutes__c = 60,
                                                    SVMXC__EndDateTime__c = Datetime.valueOf('2010-02-11 02:00:00') ,
                                                    SVMXC__Technician__c = Tech1.Id,
                                                    SVMXC__WhatId__c = objWorkOrder.Id
                                                    );
        SVMXEvent.add(SMAX_Event3);
        insert SVMXEvent;
User objUser = [SELECT Id,TimeZoneSidKey from User where id = :UserInfo.getUserId()];
         List<Event> SFEvent = new List<Event>();
        Event e1 = new Event(ActivityDate = Date.valueOf('2010-02-11 00:00:00'),
                                StartDateTime = Datetime.valueOf('2010-02-11 01:00:00') ,
                                ActivityDateTime = Datetime.valueOf('2010-02-11 01:00:00'), 
                                DurationInMinutes = 60, Subject = 'test', OwnerId = objUser.Id, 
                                WhatId=objWorkOrder.Id, Description='Test Desc');
        Event e2 = new Event(ActivityDate = Date.valueOf('2010-02-12 00:00:00'), 
                                StartDateTime = Datetime.valueOf('2010-02-12 01:00:00') ,
                                ActivityDateTime = Datetime.valueOf('2010-02-12 01:00:00'), 
                                DurationInMinutes = 60, Subject = 'test', OwnerId = objUser.Id, 
                                WhatId=objWorkOrder.Id, Description='Test Desc');
        Event e3 = new Event(ActivityDate = Date.valueOf('2010-02-9 00:00:00'),
                                StartDateTime = Datetime.valueOf('2010-02-9 01:00:00') ,
                                ActivityDateTime = Datetime.valueOf('2010-02-9 01:00:00'), IsAllDayEvent =true,
                                DurationInMinutes = 1440, Subject = 'test', OwnerId = objUser.Id, 
                                WhatId=objWorkOrder.Id, Description='Test Desc');
SFEvent.add(e1);
SFEvent.add(e2);
SFEvent.add(e3);
     // insert SFEvent;
      List<String> SFIds = new List<String>();
      List<String> SVMXIds = new List<String>();

      SFIds.add(e1.Id);
      SVMXIds.add(SMAX_Event3.Id);

      DCX_WOServiceManager.deleteEvents(SFIds);
      DCX_WOServiceManager.deleteEvents(SVMXIds);

       List<DCON_Configuration_WS.SVMX_StringMap> lstKeyValue1 = new List<DCON_Configuration_WS.SVMX_StringMap>();


        Woids.add(objWorkOrder.Id);

        SFEvent.add(e1);
        String str = e1.Id;
        lstKeyValue1.add(new DCON_Configuration_WS.SVMX_StringMap('IDLE_' + objWorkOrder.Id, '10'));
        lstKeyValue1.add(new DCON_Configuration_WS.SVMX_StringMap('DRIVE_' + objWorkOrder.Id, '10'));
        lstKeyValue1.add(new DCON_Configuration_WS.SVMX_StringMap('SERVICE_' + objWorkOrder.Id, '60'));

        DCX_WOServiceManager.DCON_WO_MultiAssign_Request req = new DCX_WOServiceManager.DCON_WO_MultiAssign_Request();
        req.workOrderIds = woids;
        req.technicianIds = techIds;
        req.operationType = 'WO_UNASSIGN_NO';
        req.timezone = 'America/Indiana/Indianapolis';
        req.Eventlist = SFEvent;
        req.EventIds = SFIds;
        req.lstKeyValue = lstKeyValue1;
        req.getworkOrderIds();
        req.setworkOrderIds(woids);
        req.getEventlist();
        req.setEventlist(SFEvent);

        DCX_WOServiceManager.DCX_Manage_Work_Order_MultiAssign_WS(req);

    }

    static testMethod void assignWOTech() {

        SVMXC__Service_Group__c objTeam = [Select Id from SVMXC__Service_Group__c where
                                           Name = 'TEAM1A'];

        SVMXC__Service_Group_Members__c Tech1 = [Select Id,SVMXC__Salesforce_User__c from 
                                                         SVMXC__Service_Group_Members__c
                                                         where Name = 'TECH1A'];
        SVMXC__Service_Order__c objWorkOrder = [Select Id from SVMXC__Service_Order__c where 
                                                SVMXC__Group_Member__c = :Tech1.Id];
        
        DCX_WOServiceManager.assignWOTeam_Request req = new DCX_WOServiceManager.assignWOTeam_Request();
        List<String> woids = new List<String>();
        woids.add(objWorkOrder.Id);
        req.WorkOrderIds=woids;
        req.TeamId=objTeam.Id;
        req.SetOwner =false;
        req.dispatchStatus = 'New';
        req.unassignWorkorder=true;
        DCX_WOServiceManager.assignWOTeam_Request req1 = new DCX_WOServiceManager.assignWOTeam_Request( woids,'' , false,'',false);
        
        DCX_WOServiceManager.assignWOTeam_Request req2 = new DCX_WOServiceManager.assignWOTeam_Request();
        req2.WorkOrderIds=woids;
        req2.TeamId=Tech1.Id;
        req2.SetOwner =false;
        req2.dispatchStatus = 'New';
        req2.unassignWorkorder=true;

        DCX_WOServiceManager.assignWOTech(req);
        DCX_WOServiceManager.assignWOTech(req2);

    }

    
}