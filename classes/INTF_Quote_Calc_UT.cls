@isTest
private with sharing class INTF_Quote_Calc_UT
{
    static testMethod void INTF_Quote_Calc_UTUnitTest()
    {
                /*-----------------------------------------DATA CREATION-------------------------------------------------*/
        //---------------------------------Creating RecordTypeList-----------------------------------------
        list<RecordType> RecordTypeList = new list<RecordType>();
        RecordTypeList = [Select SystemModstamp, SobjectType, NamespacePrefix, Name, LastModifiedDate, LastModifiedById, IsActive, Id, DeveloperName, Description, CreatedDate, CreatedById, BusinessProcessId From RecordType where SobjectType = 'SVMXC__ServiceMax_Processes__c'or SobjectType = 'SVMXC__ServiceMax_Config_Data__c'];
        String FldmappingId = '';
        String ProcessNodeobj = '';
        String TargetManager = '';
        if(RecordTypeList.size() > 0)
        {
            for(RecordType R : RecordTypeList)
            {
                if(R.Name == 'Field Mapping')
                    FldmappingId = R.id;
                if(R.Name == 'Process Node Objects')
                    ProcessNodeobj = R.id;
                if(R.Name == 'Target Manager')
                    TargetManager = R.id;       
            }
        }
        //---------------------------------Creating the process object-------------------------------------
        SVMXC__ServiceMax_Processes__c processNodes = new SVMXC__ServiceMax_Processes__c();
        processNodes.RecordTypeId = TargetManager;
        processNodes.SVMXC__Name__c = 'process1';
        processNodes.SVMXC__Description__c = 'newprocess1';
        processNodes.SVMXC__ProcessID__c = 'process1';
        processNodes.SVMXC__IsStandard__c = true;
        insert processNodes;
        
        system.assert(processNodes != null, true);
        
        SVMXC__ServiceMax_Processes__c NodeObj1 = new SVMXC__ServiceMax_Processes__c(); 
        NodeObj1.RecordTypeId = ProcessNodeobj;
        NodeObj1.SVMXC__Process__c = processNodes.id;
        NodeObj1.SVMXC__Source_Object_Name__c = 'Case';
        NodeObj1.SVMXC__Type__c = 'SOURCE';
        insert NodeObj1;
        
        SVMXC__ServiceMax_Processes__c NodeObj2 = new SVMXC__ServiceMax_Processes__c(); 
        NodeObj2.RecordTypeId = ProcessNodeobj;
        NodeObj2.SVMXC__Process__c = processNodes.id;
        NodeObj2.SVMXC__Source_Object_Name__c = 'Case';
        NodeObj2.SVMXC__Type__c = 'SOURCECHILD';
        NodeObj2.SVMXC__Node_Parent_API__c = 'Case';
        NodeObj2.SVMXC__Node_Parent__c = NodeObj1.id;
        insert NodeObj2;
        
        SVMXC__ServiceMax_Processes__c NodeObj3 = new SVMXC__ServiceMax_Processes__c();
        NodeObj3.RecordTypeId = ProcessNodeobj;
        NodeObj3.SVMXC__Process__c = processNodes.id;
        NodeObj3.SVMXC__Source_Object_Name__c = 'SVMXC__Quote__c';
        NodeObj3.SVMXC__Type__c = 'TARGET';
        NodeObj3.SVMXC__Parent_Object__c = NodeObj1.id;
        insert NodeObj3;
        
        
        SVMXC__ServiceMax_Processes__c NodeObj4 = new SVMXC__ServiceMax_Processes__c();
        NodeObj4.RecordTypeId = ProcessNodeobj;
        NodeObj4.SVMXC__Process__c = processNodes.id;
        NodeObj4.SVMXC__Source_Object_Name__c = 'SVMXC__Quote_Line__c';
        NodeObj4.SVMXC__Type__c = 'TARGETCHILD';
        NodeObj4.SVMXC__Node_Parent_API__c = 'SVMXC__Quote__c';
        NodeObj4.SVMXC__Parent_Object__c = NodeObj2.id;
        NodeObj4.SVMXC__Parent_Column_Name__c = 'SVMXC__Service_Quote__c';
        insert NodeObj4;
        
        system.assertEquals(NodeObj4.SVMXC__Process__c,processNodes.id);
        
        //Create Source update Records....
        list<SVMXC__ServiceMax_Config_Data__c> SourceUpdatesRec = new list<SVMXC__ServiceMax_Config_Data__c>();
        SVMXC__ServiceMax_Config_Data__c config1 = new SVMXC__ServiceMax_Config_Data__c(); 
        config1.RecordTypeId = FldmappingId;
        config1.SVMXC__Dispatch_Process__c = processNodes.id;
        config1.SVMXC__Source_Field_Name__c = 'SVMXC__Billing_Type__c';
        config1.SVMXC__Target_Field_Name__c = 'SVMXC__Billing_Type__c';
        config1.SVMXC__Action__c = 'Set';
        config1.SVMXC__Configuration_Type__c = 'Source Update';
        SourceUpdatesRec.add(config1);
        
        SVMXC__ServiceMax_Config_Data__c config2 = new SVMXC__ServiceMax_Config_Data__c(); 
        config2.RecordTypeId = FldmappingId;
        config2.SVMXC__Dispatch_Process__c = processNodes.id;
        config2.SVMXC__Source_Field_Name__c = 'SVMXC__Billing_Type__c';
        config2.SVMXC__Display_Value__c = 'Contract';
        config2.SVMXC__Action__c = 'Set';
        config2.SVMXC__Configuration_Type__c = 'Source Update';
        SourceUpdatesRec.add(config2);
        
        SVMXC__ServiceMax_Config_Data__c config3 = new SVMXC__ServiceMax_Config_Data__c(); 
        config3.RecordTypeId = FldmappingId;
        config3.SVMXC__Dispatch_Process__c = processNodes.id;
        config3.SVMXC__Source_Field_Name__c = 'SVMXC__SLA_Clock_Pause_Days__c';
        config3.SVMXC__Display_Value__c = '1';
        config3.SVMXC__Action__c = 'INCREASE';
        config3.SVMXC__Configuration_Type__c = 'Source Update';
        SourceUpdatesRec.add(config3);
        insert SourceUpdatesRec;
        
        system.assert(SourceUpdatesRec!=null,true);
        
        Product2 pro = new Product2();
        pro.Name = 'Servicemax';
        insert pro; 
        
        //Create case for source record update
        Case c = new Case();
        c.Origin = 'Email';
        c.Priority = 'High';
        c.SVMXC__SLA_Clock_Pause_Days__c = 1;
        insert c;
       
       
        //-------------------------------Creating List of Work Order Object---------------------------------
        List<SVMXC__Quote__c> WOList = new List<SVMXC__Quote__c>();
        SVMXC__Quote__c WO1 = new SVMXC__Quote__c();
        SVMXC__Quote__c WO2 = new SVMXC__Quote__c();
        WOList.add(WO1);
        WOList.add(WO2);
        insert WOList;
        
        system.assert(WOList!=null,true);
        
        //----------------Creating String List to pass to the method of Header TargetRecObj-------------------
        List<String> strLst1 = new List<String>();
        String str1 = WO1.Id;
        String str2 = WO2.Id;
        strLst1.add(str1);
        strLst1.add(str2);
        
        system.assert(strLst1!=null,true);
        
        SVMXC__Quote__c WOrder = new SVMXC__Quote__c();
        //WOrder.SVMXC__City__c = 'Bangalore';
        //WOrder.SVMXC__Country__c = 'India';
        //WOrder.SVMXC__Street__c = 'Cunninghum';
        insert WOrder;
         
        //--------------Creating Work Detail Object to pass to the method of DtlTargetRecordObject-----------
        SVMXC__Quote_Line__c WOLine = new SVMXC__Quote_Line__c();
        WOLine.SVMXC__Quote__c = WOrder.Id;
        WOLine.SVMXC__Select__c = true;
        insert WOLine;
        
        system.assert(WOLine!=null,true);
        
        //-----------------------Creating Work Detail Object to pass to the method of Record------------------
        SVMXC__Quote_Line__c WOLine1 = new SVMXC__Quote_Line__c();
        WOLine1.SVMXC__Quote__c = WOrder.Id;
        WOLine1.SVMXC__Select__c = true;
        insert WOLine1;
        
        //---------------------Creating String List to pass to the method of DtlTargetRecordObject------------
        List<String> strLst2 = new List<String>();
        String str3 = WOLine.Id;
        strLst2.add(str3);
        
        system.assert(strLst2!=null,true);
        
        //----------------------Creating List of StringMap for Header Target Record---------------------------
        List<INTF_WebServicesDef.INTF_StringMap> ListOfStringMap = new List<INTF_WebServicesDef.INTF_StringMap>();
        INTF_WebServicesDef.INTF_StringMap Stringmapcls1 = new INTF_WebServicesDef.INTF_StringMap('SVMXC__Discount__c','20');
        INTF_WebServicesDef.INTF_StringMap Stringmapcls2 = new INTF_WebServicesDef.INTF_StringMap('SVMXC__Discount_Type__c','Amount');
        INTF_WebServicesDef.INTF_StringMap Stringmapcls3 = new INTF_WebServicesDef.INTF_StringMap('SVMXC__Total_Line_Price2__c','1000');
        INTF_WebServicesDef.INTF_StringMap Stringmapcls4 = new INTF_WebServicesDef.INTF_StringMap('SVMXC__Quote_Amount2__c','1000');
        ListOfStringMap.add(Stringmapcls1);
        ListOfStringMap.add(Stringmapcls2);
        ListOfStringMap.add(Stringmapcls3);
        ListOfStringMap.add(Stringmapcls4);
        
        //----------------------Creating List of StringMap for Detail Target Record(For Update)----------------------------
        List<INTF_WebServicesDef.INTF_StringMap> ListOfStringMap1 = new List<INTF_WebServicesDef.INTF_StringMap>();
        INTF_WebServicesDef.INTF_StringMap Stringmapcls5 = new INTF_WebServicesDef.INTF_StringMap('SVMXC__Discount_Type__c','Amount');
        INTF_WebServicesDef.INTF_StringMap Stringmapcls6 = new INTF_WebServicesDef.INTF_StringMap('SVMXC__Discount__c','10');
        INTF_WebServicesDef.INTF_StringMap Stringmapcls7 = new INTF_WebServicesDef.INTF_StringMap('SVMXC__Quantity2__c','10');
        INTF_WebServicesDef.INTF_StringMap Stringmapcls8 = new INTF_WebServicesDef.INTF_StringMap('SVMXC__Unit_Price2__c','101');
        INTF_WebServicesDef.INTF_StringMap Stringmapcls9 = new INTF_WebServicesDef.INTF_StringMap('SVMXC__Product__c',String.valueof(pro.id));
        ListOfStringMap1.add(Stringmapcls5);
        ListOfStringMap1.add(Stringmapcls6);
        ListOfStringMap1.add(Stringmapcls7);
        ListOfStringMap1.add(Stringmapcls8);
        ListOfStringMap1.add(Stringmapcls9);
        
        /*List<INTF_WebServicesDef.INTF_StringMap> ListOfStringMap2 = new List<INTF_WebServicesDef.INTF_StringMap>();
        INTF_WebServicesDef.INTF_StringMap Stringmapcls8 = new INTF_WebServicesDef.INTF_StringMap('SVMXC__Quote__c',String.valueof(WOrder.Id));
        INTF_WebServicesDef.INTF_StringMap Stringmapcls9 = new INTF_WebServicesDef.INTF_StringMap('SVMXC__Activity_Type__c','Installation');
        INTF_WebServicesDef.INTF_StringMap Stringmapcls10 = new INTF_WebServicesDef.INTF_StringMap('SVMXC__Cost_Category__c','Straight');
        ListOfStringMap2.add(Stringmapcls8);
        ListOfStringMap2.add(Stringmapcls9);
        ListOfStringMap2.add(Stringmapcls10);*/
        
        
        
        //-----------------------------Creating List of SFM_Record for Header TargetRecObj----------------------------
        List<INTF_WebServicesDef.INTF_Record> SfmRecList1 = new List<INTF_WebServicesDef.INTF_Record>();
        INTF_WebServicesDef.INTF_Record SfmRec1 = new INTF_WebServicesDef.INTF_Record();
        SfmRec1.sourceRecordId = c.id;
        SfmRec1.targetRecordAsKeyValue = ListOfStringMap;
        SfmRecList1.add(SfmRec1);
        
        system.assert(SfmRecList1!=null,true);
        
        //-------------------------Creating List of SFM_Record for DtlTargetRecordObject(for update)-------------------------
        List<INTF_WebServicesDef.INTF_Record> SfmRecList2 = new List<INTF_WebServicesDef.INTF_Record>();
        INTF_WebServicesDef.INTF_Record SfmRec2 = new INTF_WebServicesDef.INTF_Record();
        SfmRec2.sourceRecordId = '';
        SfmRec2.targetRecordAsKeyValue = ListOfStringMap1;
        SfmRecList2.add(SfmRec2);
        
        system.assert(SfmRecList2!=null,true);
        
        /*//-------------------------Creating List of SFM_Record for DtlTargetRecordObject(for insert)-------------------------
        INTF_WebServicesDef.INTF_Record SfmRec3 = new INTF_WebServicesDef.INTF_Record();
        SfmRec3.sourceRecordId = '';
        SfmRec3.targetRecordAsKeyValue = ListOfStringMap2;
        SfmRecList2.add(SfmRec3);*/
        
        //-------------------------------Creating Header Target Record Object-------------------------------------
        SVMXC.INTF_WebServicesDef.INTF_TargetRecordObject TargetRecObj = new SVMXC.INTF_WebServicesDef.INTF_TargetRecordObject();
        TargetRecObj.objName = 'SVMXC__Quote__c';
        TargetRecObj.deleteRecID = strLst1;
        TargetRecObj.records =  SfmRecList1;
        
        //---------------------------Creating List of Detail Target Record-------------------------------------
        List<SVMXC.INTF_WebServicesDef.INTF_TargetRecordObject> DtlTargetRecordObject = new List<SVMXC.INTF_WebServicesDef.INTF_TargetRecordObject>();
        SVMXC.INTF_WebServicesDef.INTF_TargetRecordObject TargetRecObj1 = new SVMXC.INTF_WebServicesDef.INTF_TargetRecordObject();
        TargetRecObj1.objName = 'SVMXC__Quote_Line__c';
        TargetRecObj1.aliasName = 'WorkDetailLine';
        TargetRecObj1.deleteRecID = strLst2;
        TargetRecObj1.parentColumnName = 'SVMXC__Quote__c';
        TargetRecObj1.records =  SfmRecList2;
        DtlTargetRecordObject.add(TargetRecObj1);
        
        system.assert(DtlTargetRecordObject!=null,true);
        
        //---------------------------------Creating Target Record Object---------------------------------------
        SVMXC.INTF_WebServicesDef.INTF_TargetRecord sfmtargetrec = new SVMXC.INTF_WebServicesDef.INTF_TargetRecord();
        sfmtargetrec.sfmProcessId = processNodes.Id;
        sfmtargetrec.headerRecord = TargetRecObj;
        sfmtargetrec.detailRecords = DtlTargetRecordObject;
        
        INTF_Quote_Calc quoteCalc = new INTF_Quote_Calc();
        quoteCalc.QuoteCalculation(sfmtargetrec);
        
    }
}