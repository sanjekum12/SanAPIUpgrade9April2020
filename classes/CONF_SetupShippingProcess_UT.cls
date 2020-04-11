@isTest
private with sharing class CONF_SetupShippingProcess_UT
{
    static testMethod void CONF_SetupShippingProcess_UnitTest() 
    {
        System.currentPageReference().getParameters().put('SVMX_Mode', 'New');
        CONF_SetupShippingProcess shipngProcess = new CONF_SetupShippingProcess();
        
        RecordType ShippingProcess_Rtype = [select Id from RecordType where Name='Shipping Process'and SobjectType='SVMXC__ServiceMax_Processes__c' Limit 1];
        RecordType ExpressionsSrcUpdate_Rtype = [select Id from RecordType where Name='Field Mapping'and SobjectType='SVMXC__ServiceMax_Config_Data__c' Limit 1];
        
        SVMXC__ServiceMax_Processes__c process = new SVMXC__ServiceMax_Processes__c();
        process.RecordTypeId = ShippingProcess_Rtype.Id;
        process.SVMXC__Name__c = 'Process00001';
        //process.SVMXC__Process__c
        process.SVMXC__APL_Print_Label_Template__c = 'Process00001';
        process.SVMXC__APL_Shipment_Note_Template__c = 'Process00001';
        //process.SVMXC__Parent_Object__c
        process.SVMXC__ProcessID__c = 'Process00001';
        process.SVMXC__Description__c = 'Process00001';
        //process.SVMXC__Process1__c
        //process.SVMXC__Process2__c
        process.SVMXC__APL_Serial_Number_Source__c = 'STOCK';
        process.SVMXC__APL_Scan_First__c = 'Product';
        process.SVMXC__Source_Object_Name__c = 'SVMXC__RMA_Shipment_Order__c';
        process.SVMXC__Active__c = true;
        //process.SVMXC__Node_Parent__c
        //process.SVMXC__Submodule__c
        //process.SVMXC__Module__c
        //process.SVMXC__Final_Exception_Process__c
        process.SVMXC__Parent_Error_Msg__c = 'Process00001';
        process.SVMXC__Child_Error_Msg__c = 'Process00001';
        process.SVMXC__Parent_Error_Msg2__c = 'Process00001';
        process.SVMXC__Child_Error_Msg2__c = 'Process00001';
        process.SVMXC__APL_Allow_Partial_Shipment__c = false;
        process.SVMXC__APL_Create_Internal_RMA__c = true;
        process.SVMXC__APL_Create_Supplier_RMA__c = false;
        process.SVMXC__IsStandard__c = true;
        insert process;
        
        SVMXC__SFM_Event__c event1 = new SVMXC__SFM_Event__c();
        event1.SVMXC__Event_Type__c = 'After Picking';
        event1.SVMXC__ServiceMax_Process__c = process.Id;
        insert event1;
        SVMXC__SFM_Event__c event2 = new SVMXC__SFM_Event__c();
        event2.SVMXC__Event_Type__c = 'After Shipment';
        event2.SVMXC__ServiceMax_Process__c = process.Id;
        insert event2;
        SVMXC__SFM_Event__c event3 = new SVMXC__SFM_Event__c();
        event3.SVMXC__Event_Type__c = 'After Closure';
        event3.SVMXC__ServiceMax_Process__c = process.Id;
        insert event3;
        SVMXC__SFM_Event__c event4 = new SVMXC__SFM_Event__c();
        event4.SVMXC__Event_Type__c = 'SFM Custom Action';
        event4.SVMXC__Sequence__c = 1;
        event4.SVMXC__ServiceMax_Process__c = process.Id;
        insert event4;
        SVMXC__SFM_Event__c event5 = new SVMXC__SFM_Event__c();
        event5.SVMXC__Event_Type__c = 'SFM Custom Action';
        event5.SVMXC__Sequence__c = 2;
        event5.SVMXC__ServiceMax_Process__c = process.Id;
        insert event5;
        SVMXC__SFM_Event__c event6 = new SVMXC__SFM_Event__c();
        event6.SVMXC__Event_Type__c = 'SFM Custom Action';
        event6.SVMXC__Sequence__c = 3;
        event6.SVMXC__ServiceMax_Process__c = process.Id;
        insert event6;
        
        SVMXC__ServiceMax_Config_Data__c configData = new SVMXC__ServiceMax_Config_Data__c();
        configData.SVMXC__Configuration_Type__c = 'HEADER_UPD_ON_PICKING';
        configData.SVMXC__Dispatch_Process__c = process.Id;
        configData.RecordTypeId = ExpressionsSrcUpdate_Rtype.Id;
        insert configData;
        SVMXC__ServiceMax_Config_Data__c configData1 = new SVMXC__ServiceMax_Config_Data__c();
        configData1.SVMXC__Configuration_Type__c = 'LINE_UPD_ON_PICKING';
        configData1.SVMXC__Dispatch_Process__c = process.Id;
        configData1.RecordTypeId = ExpressionsSrcUpdate_Rtype.Id;
        insert configData1;
        SVMXC__ServiceMax_Config_Data__c configData2 = new SVMXC__ServiceMax_Config_Data__c();
        configData2.SVMXC__Configuration_Type__c = 'HEADER_UPD_ON_SHIP';
        configData2.SVMXC__Dispatch_Process__c = process.Id;
        configData2.RecordTypeId = ExpressionsSrcUpdate_Rtype.Id;
        insert configData2;
        SVMXC__ServiceMax_Config_Data__c configData3 = new SVMXC__ServiceMax_Config_Data__c();
        configData3.SVMXC__Configuration_Type__c = 'LINE_UPD_ON_SHIP';
        configData3.SVMXC__Dispatch_Process__c = process.Id;
        configData3.RecordTypeId = ExpressionsSrcUpdate_Rtype.Id;
        insert configData3;
        SVMXC__ServiceMax_Config_Data__c configData4 = new SVMXC__ServiceMax_Config_Data__c();
        configData4.SVMXC__Configuration_Type__c = 'PRODUCT_ATTRIBUTE';
        configData4.SVMXC__Sequence__c = 1;
        configData4.SVMXC__Dispatch_Process__c = process.Id;
        configData4.RecordTypeId = ExpressionsSrcUpdate_Rtype.Id;
        insert configData4;
        SVMXC__ServiceMax_Config_Data__c configData5 = new SVMXC__ServiceMax_Config_Data__c();
        configData5.SVMXC__Configuration_Type__c = 'PRODUCT_ATTRIBUTE';
        configData5.SVMXC__Sequence__c = 2;
        configData5.SVMXC__Dispatch_Process__c = process.Id;
        configData5.RecordTypeId = ExpressionsSrcUpdate_Rtype.Id;
        insert configData5;
        SVMXC__ServiceMax_Config_Data__c configData6 = new SVMXC__ServiceMax_Config_Data__c();
        configData6.SVMXC__Configuration_Type__c = 'DOCUMENT_ATTRIBUTE';
        configData6.SVMXC__Sequence__c = 1;
        configData6.SVMXC__Dispatch_Process__c = process.Id;
        configData6.RecordTypeId = ExpressionsSrcUpdate_Rtype.Id;
        insert configData6;
        SVMXC__ServiceMax_Config_Data__c configData7 = new SVMXC__ServiceMax_Config_Data__c();
        configData7.SVMXC__Configuration_Type__c = 'DOCUMENT_ATTRIBUTE';
        configData7.SVMXC__Sequence__c = 2;
        configData7.SVMXC__Dispatch_Process__c = process.Id;
        configData7.RecordTypeId = ExpressionsSrcUpdate_Rtype.Id;
        insert configData7;
        SVMXC__ServiceMax_Config_Data__c configData8 = new SVMXC__ServiceMax_Config_Data__c();
        configData8.SVMXC__Configuration_Type__c = 'DOCUMENT_ATTRIBUTE';
        configData8.SVMXC__Sequence__c = 3;
        configData8.SVMXC__Dispatch_Process__c = process.Id;
        configData8.RecordTypeId = ExpressionsSrcUpdate_Rtype.Id;
        insert configData8;
        SVMXC__ServiceMax_Config_Data__c configData9 = new SVMXC__ServiceMax_Config_Data__c();
        configData9.SVMXC__Configuration_Type__c = 'DOCUMENT_LINE_ATTRIBUTE';
        configData9.SVMXC__Sequence__c = 1;
        configData9.SVMXC__Dispatch_Process__c = process.Id;
        configData9.RecordTypeId = ExpressionsSrcUpdate_Rtype.Id;
        insert configData9;
        SVMXC__ServiceMax_Config_Data__c configData10 = new SVMXC__ServiceMax_Config_Data__c();
        configData10.SVMXC__Configuration_Type__c = 'DOCUMENT_LINE_ATTRIBUTE';
        configData10.SVMXC__Sequence__c = 2;
        configData10.SVMXC__Dispatch_Process__c = process.Id;
        configData10.RecordTypeId = ExpressionsSrcUpdate_Rtype.Id;
        insert configData10;
        
        System.currentPageReference().getParameters().put('SVMX_Mode', 'Edit');
        System.currentPageReference().getParameters().put('SVMX_RecordId', process.Id);
        
        shipngProcess = new CONF_SetupShippingProcess();
        shipngProcess.quickSave();
        shipngProcess.onChngParentPickExp();
        shipngProcess.EditCriteriaParentPick();
        shipngProcess.onChngLinePickExp();
        shipngProcess.EditCriteriaLinePick();
        shipngProcess.onChngParentShipExp();
        shipngProcess.EditCriteriaParentShip();
        shipngProcess.onChngLineShipExp();
        shipngProcess.EditCriteriaLineShip();
        shipngProcess.NewCriteriaParentPick();
        shipngProcess.NewCriteriaLinePick();
        shipngProcess.NewCriteriaParentShip();
        shipngProcess.NewCriteriaLineShip();
        shipngProcess.HdrDeleteRowParentPick();
        shipngProcess.HdrADDRowParentPick();
        shipngProcess.HdrDeleteRowLinePick();
        shipngProcess.HdrADDRowLinePick();
        shipngProcess.HdrDeleteRowParentShip();
        shipngProcess.HdrADDRowParentShip();
        shipngProcess.HdrDeleteRowLineShip();
        shipngProcess.HdrADDRowLineShip();
        shipngProcess.srcUpdateDeleteRowParentPick();
        shipngProcess.srcUpdateADDRowParentPick();
        shipngProcess.srcUpdateDeleteRowLinePick();
        shipngProcess.srcUpdateADDRowLinePick();
        shipngProcess.srcUpdateDeleteRowParentShip();
        shipngProcess.srcUpdateADDRowParentShip();
        shipngProcess.srcUpdateDeleteRowLineShip();
        shipngProcess.srcUpdateADDRowLineShip();
        shipngProcess.GeneralInfo();
        shipngProcess.QualPick();
        shipngProcess.SrcUpdtPick();
        shipngProcess.QualPack();
        shipngProcess.SrcUpdtPack();
        shipngProcess.CustmEventLink();
        shipngProcess.cancel();
        shipngProcess.saveClose();
        
        SVMXC__ServiceMax_Processes__c proce = shipngProcess.getshpngProces();
        shipngProcess.setshpngProces(proce);
        List<SVMXC__ServiceMax_Processes__c> LstProce = shipngProcess.getactionsLst();
        shipngProcess.setactionsLst(LstProce);
        LstProce = shipngProcess.getObjMapRMALst();
        shipngProcess.setObjMapRMALst(LstProce);
        LstProce = shipngProcess.getObjMapRMALineLst();
        shipngProcess.setObjMapRMALineLst(LstProce);
        List<SVMXC__SFM_Event__c> LstSFM = shipngProcess.getlstSFMEvent();
        shipngProcess.setlstSFMEvent(LstSFM);
        List<SVMXC__ServiceMax_Config_Data__c> LstC = shipngProcess.getsrcUpdatePickHdr();
        shipngProcess.setsrcUpdatePickHdr(LstC);
        LstC = shipngProcess.getsrcUpdateShipHdr();
        shipngProcess.setsrcUpdateShipHdr(LstC);
        LstC = shipngProcess.getsrcUpdatePickLine();
        shipngProcess.setsrcUpdatePickLine(LstC);
        LstC = shipngProcess.getsrcUpdateShipLine();
        shipngProcess.setsrcUpdateShipLine(LstC);
        /* List<SelectOption> LstSO = shipngProcess.getlstProductAttributes();
        shipngProcess.setlstProductAttributes(LstSO); */
        List<SelectOption> LstSO = shipngProcess.getlstUpdateOperator();
        shipngProcess.setlstUpdateOperator(LstSO);
        /* LstSO = shipngProcess.getlstProdSrl();
        shipngProcess.setlstProdSrl(LstSO); */
        LstSO = shipngProcess.getlstFldShpmntDoc();
        shipngProcess.setlstFldShpmntDoc(LstSO);
        LstSO = shipngProcess.getlstFldShpmntDocLine();
        shipngProcess.setlstFldShpmntDocLine(LstSO);
        LstSO = shipngProcess.getlstCriteriaParentPick();
        shipngProcess.setlstCriteriaParentPick(LstSO);
        LstSO = shipngProcess.getlstCriterialinePick();
        shipngProcess.setlstCriterialinePick(LstSO);
        /* LstSO = shipngProcess.getlstCustmActn();
        shipngProcess.setlstCustmActn(LstSO); */
        LstSO = shipngProcess.getlstObjMapRMA();
        shipngProcess.setlstObjMapRMA(LstSO);
        LstSO = shipngProcess.getlstObjMapRMALine();
        shipngProcess.setlstObjMapRMALine(LstSO);
        LstSO = shipngProcess.getOperatorSelectLst();
        LstSO = shipngProcess.getHdrfldlist();
        LstSO = shipngProcess.getLinefldList();
        string str = shipngProcess.getdelIndex();
        shipngProcess.setdelIndex (str);
        SFM_WrapperDef.SFM_Expression sfmExp = shipngProcess.getExpParentPick();
        shipngProcess.setExpParentPick(sfmExp);
        sfmExp = shipngProcess.getExpLinePick();
        shipngProcess.setExpLinePick(sfmExp);
        sfmExp = shipngProcess.getExpParentShip();
        shipngProcess.setExpParentShip(sfmExp);
        sfmExp = shipngProcess.getExpLineShip();
        shipngProcess.setExpLineShip(sfmExp);
        sfmExp = shipngProcess.getExp();
        shipngProcess.setExp(sfmExp);
        Integer inte = shipngProcess.getParentPickExpDetailSize();
        inte = shipngProcess.getLinePickExpDetailSize();
        inte = shipngProcess.getParentShipExpDetailSize();
        inte = shipngProcess.getLineShipExpDetailSize();
        inte = shipngProcess.getSrcUpdateParentPickExpSize();
        inte = shipngProcess.getSrcUpdateLinePickExpSize();
        inte = shipngProcess.getSrcUpdateParentShipExpSize();
        inte = shipngProcess.getSrcUpdateLineShipExpSize();
        str = shipngProcess.getsavedExpressionResultId();
        shipngProcess.setsavedExpressionResultId(str);
        
        shipngProcess.getTAG001();
        shipngProcess.getTAG002();
        shipngProcess.getTAG003();
        shipngProcess.getTAG004();
        shipngProcess.getTAG005();
        shipngProcess.getTAG006();
        shipngProcess.getTAG007();
        shipngProcess.getTAG008();
        shipngProcess.getTAG009();
        shipngProcess.getTAG010();
        shipngProcess.getTAG011();
        shipngProcess.getTAG012();
        shipngProcess.getTAG013();
        shipngProcess.getTAG014();
        shipngProcess.getTAG015();
        shipngProcess.getTAG016();
        shipngProcess.getTAG017();
        shipngProcess.getTAG018();
        shipngProcess.getTAG019();
        shipngProcess.getTAG020();
        shipngProcess.getTAG021();
        //shipngProcess.getTAG022();
        shipngProcess.getTAG023();
        shipngProcess.getTAG024();
        shipngProcess.getTAG025();
        shipngProcess.getTAG027();
        shipngProcess.getTAG028();
        shipngProcess.getTAG029();
        shipngProcess.getTAG030();
        shipngProcess.getTAG031();
        shipngProcess.getTAG032();
        shipngProcess.getTAG033();
        shipngProcess.getTAG034();
        shipngProcess.getTAG035();
        shipngProcess.getTAG036();
        shipngProcess.getTAG037();
        shipngProcess.getTAG038();
        shipngProcess.getTAG039();
        shipngProcess.getTAG040();
        shipngProcess.getTAG041();
        shipngProcess.getTAG042();
        shipngProcess.getTAG043();
        shipngProcess.getTAG044();
        shipngProcess.getTAG045();
        shipngProcess.getTAG046();
        shipngProcess.getTAG047();
        shipngProcess.getTAG048();
        shipngProcess.getTAG049();
        shipngProcess.getTAG050();
        shipngProcess.getTAG051();
        shipngProcess.getTAG052();
        shipngProcess.getTAG053();
        shipngProcess.getTAG054();
        shipngProcess.getTAG055();
        shipngProcess.getTAG056();
        shipngProcess.getTAG057();
        shipngProcess.getTAG073();
        shipngProcess.getTAG077();
        shipngProcess.getTAG078();
        shipngProcess.getTAG079();
        shipngProcess.getTAG080();
        shipngProcess.getTAG083();
        shipngProcess.getTAG084();
        shipngProcess.getTAG085();
        shipngProcess.getTAG086();
        shipngProcess.getTAG087();
        shipngProcess.getTAG088();
        shipngProcess.getTAG089();
        shipngProcess.getTAG090();
        shipngProcess.getTAG091();
        shipngProcess.getTAG092();
        shipngProcess.getTAG093();
        shipngProcess.getTAG094();
        shipngProcess.getTAG095();
        shipngProcess.getTAG096();
        shipngProcess.getTAG097();
    }
}