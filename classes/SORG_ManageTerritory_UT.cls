@isTest
Private class SORG_ManageTerritory_UT {
 
static testMethod void SORG_ManageTerritory_Test()
{
    try
    {
        //Datas
        List<SVMXC__Territory__c> tt = [SELECT Id from SVMXC__Territory__c];
        delete tt;
        SVMXC__Territory__c T1 = new SVMXC__Territory__c(Name='T1',SVMXC__Active__c=true,SVMXC__Territory_Code__c='T1',SVMXC__Parent_Territory__c=NULL);
        insert T1;
        System.assertEquals(true, T1 != null);
    
        SVMXC__Territory_Coverage__c TTA1 = new SVMXC__Territory_Coverage__c(SVMXC__Active__c=true,SVMXC__Type__c='Zip',SVMXC__value__c='ZIP001',SVMXC__Territory__c=T1.Id);
        insert TTA1;
        System.assertEquals(true, TTA1 != null);
        
            test.starttest();
        
            SORG_ManageTerritory myPageCon = new SORG_ManageTerritory();
            //Getters and Setters
            myPageCon.getTAG001();
            myPageCon.getTAG002();
            myPageCon.getTAG003();
            myPageCon.getTAG004();
            myPageCon.getTAG005();
            myPageCon.getTAG006();
            myPageCon.getTAG007();
            myPageCon.getTAG008();
            myPageCon.getTAG009();
            myPageCon.getTAG010();
            myPageCon.getTAG011();
            myPageCon.getTAG012();
            myPageCon.getTAG013();
            myPageCon.getTAG014();
            myPageCon.getTAG015();
            myPageCon.getTAG016();
            myPageCon.getTAG017();
            myPageCon.getTAG018();
            myPageCon.getTAG019();
            myPageCon.getTAG020();
            myPageCon.getTAG021();
            myPageCon.getTAG022();
            myPageCon.getTAG023();
            myPageCon.getTAG024();
            myPageCon.getTAG025();
            myPageCon.getTAG026();
            myPageCon.getTAG027();
            myPageCon.getTAG028();
            myPageCon.getTAG029();
            myPageCon.getTAG030();
            myPageCon.getTAG031();
            myPageCon.getTAG032();
            myPageCon.getTAG033();
            myPageCon.getTAG034();
            myPageCon.getTAG035();
            myPageCon.getTAG036();
            myPageCon.getTAG037();
            myPageCon.getTAG038();
            myPageCon.getTAG039();
            myPageCon.getTAG040();
            myPageCon.getTAG041();
            myPageCon.getTAG042();
            myPageCon.getTAG043();
            myPageCon.getTAG044();
            myPageCon.getTAG045();
            myPageCon.getTAG046();
            myPageCon.getTAG047();
            myPageCon.getTAG048();
            myPageCon.getTAG049();
            myPageCon.getTAG050();
            myPageCon.getTAG051();
            myPageCon.getTAG052();
            myPageCon.getTAG053();
            myPageCon.getTAG054();
            myPageCon.getTAG055();
            myPageCon.getTAG056();
            myPageCon.getTAG057();
            myPageCon.getTAG058();
            myPageCon.getTAG059();
            myPageCon.getTAG060();
            myPageCon.getTAG061();
            myPageCon.getTAG062();
            myPageCon.getTAG063();
            myPageCon.getTAG064();
            myPageCon.getTAG065();
            myPageCon.getTAG066();
            myPageCon.getTAG067();
            myPageCon.getTAG068();
            myPageCon.getTAG069();
            myPageCon.getTAG070();
            myPageCon.getTAG071();
            myPageCon.getTAG072();
            myPageCon.getTAG073();
            myPageCon.getTAG074();
            myPageCon.getTAG075();
            myPageCon.getTAG076();
            myPageCon.getTAG077();
            myPageCon.getTAG078();
            myPageCon.getTAG079();
            myPageCon.getTAG080();
            myPageCon.getTAG099();
            myPageCon.getTAG100();
            myPageCon.getTAG101();
            myPageCon.getTAG102();
            myPageCon.getTAG103();
            myPageCon.getTAG104();
            myPageCon.getTAG105();
            myPageCon.getTAG106();
            myPageCon.getTAG107();
            myPageCon.getTAG108(); 
            myPageCon.getTAG109(); 
            myPageCon.getTAG110(); 
            myPageCon.getTAG111(); 
            myPageCon.getTAG112(); 
            myPageCon.getTAG113(); 
            myPageCon.getTAG114(); 
            myPageCon.getTAG115();         
            myPageCon.getTAG116(); 
            myPageCon.getHLPURL();
            myPageCon.getGBL006();
            
            //myPageCon.svmxTagList.clear();
            
            myPageCon.getTAG001();
            myPageCon.getTAG002();
            myPageCon.getTAG003();
            myPageCon.getTAG004();
            myPageCon.getTAG005();
            myPageCon.getTAG006();
            myPageCon.getTAG007();
            myPageCon.getTAG008();
            myPageCon.getTAG009();
            myPageCon.getTAG010();
            myPageCon.getTAG011();
            myPageCon.getTAG012();
            myPageCon.getTAG013();
            myPageCon.getTAG014();
            myPageCon.getTAG015();
            myPageCon.getTAG016();
            myPageCon.getTAG017();
            myPageCon.getTAG018();
            myPageCon.getTAG019();
            myPageCon.getTAG020();
            myPageCon.getTAG021();
            myPageCon.getTAG022();
            myPageCon.getTAG023();
            myPageCon.getTAG024();
            myPageCon.getTAG025();
            myPageCon.getTAG026();
            myPageCon.getTAG027();
            myPageCon.getTAG028();
            myPageCon.getTAG029();
            myPageCon.getTAG030();
            myPageCon.getTAG031();
            myPageCon.getTAG032();
            myPageCon.getTAG033();
            myPageCon.getTAG034();
            myPageCon.getTAG035();
            myPageCon.getTAG036();
            myPageCon.getTAG037();
            myPageCon.getTAG038();
            myPageCon.getTAG039();
            myPageCon.getTAG040();
            myPageCon.getTAG041();
            myPageCon.getTAG042();
            myPageCon.getTAG043();
            myPageCon.getTAG044();
            myPageCon.getTAG045();
            myPageCon.getTAG046();
            myPageCon.getTAG047();
            myPageCon.getTAG048();
            myPageCon.getTAG049();
            myPageCon.getTAG050();
            myPageCon.getTAG051();
            myPageCon.getTAG052();
            myPageCon.getTAG053();
            myPageCon.getTAG054();
            myPageCon.getTAG055();
            myPageCon.getTAG056();
            myPageCon.getTAG057();
            myPageCon.getTAG058();
            myPageCon.getTAG059();
            myPageCon.getTAG060();
            myPageCon.getTAG061();
            myPageCon.getTAG062();
            myPageCon.getTAG063();
            myPageCon.getTAG064();
            myPageCon.getTAG065();
            myPageCon.getTAG066();
            myPageCon.getTAG067();
            myPageCon.getTAG068();
            myPageCon.getTAG069();
            myPageCon.getTAG070();
            myPageCon.getTAG071();
            myPageCon.getTAG072();
            myPageCon.getTAG073();
            myPageCon.getTAG074();
            myPageCon.getTAG075();
            myPageCon.getTAG076();
            myPageCon.getTAG077();
            myPageCon.getTAG078();
            myPageCon.getTAG079();
            myPageCon.getTAG080();
            myPageCon.getTAG099();
            myPageCon.getTAG100();
            myPageCon.getTAG101();
            myPageCon.getTAG102();
            myPageCon.getTAG103();
            myPageCon.getTAG104();
            myPageCon.getTAG105();
            myPageCon.getTAG106();
            myPageCon.getTAG107();
            myPageCon.getTAG108();
            myPageCon.getTAG109(); 
            myPageCon.getTAG110(); 
            myPageCon.getTAG111(); 
            myPageCon.getTAG112(); 
            myPageCon.getTAG113(); 
            myPageCon.getTAG114(); 
            myPageCon.getTAG115();   
            myPageCon.getTAG116();           
            myPageCon.getHLPURL();
            myPageCon.getGBL006();
            
            myPageCon.getDeleteAlertMessage();
            myPageCon.getShowAlert();
            myPageCon.getTTListStyle();
            myPageCon.ClosePopUp2();
            myPageCon.getCheckAllAdjLines();
            myPageCon.getShowAlert();
            myPageCon.getTTListStyle();
            myPageCon.setCheckAllAdjLines(true);        
            myPageCon.doZeroPadding('STRING',9);
            
           // myPageCon.getXMLResult();
            myPageCon.getTTId();
            myPageCon.setTTId('test');
            myPageCon.getRO_Parent();
            myPageCon.setRO_Parent('test');
            myPageCon.getRO_Child();
            myPageCon.setRO_Child('test');
            myPageCon.getZipStart();
            myPageCon.setZipStart('test');
            myPageCon.getZipEnd();
            myPageCon.setZipEnd('test');
            myPageCon.getCountry();
            String[] s;
            myPageCon.setCountry(s);
            myPageCon.getSCountry();
            myPageCon.setSCountry(s);
            myPageCon.getAddTrtry();
            myPageCon.getCheckAllLines();
            myPageCon.setCheckAllLines(true);
            myPageCon.getIsListAvail();
            myPageCon.getDisplayPPLevelMessage();
            myPageCon.getisConfigureMode();
            myPageCon.getdisplayZipPopup();
            myPageCon.getdisplayCountryPopup();
            myPageCon.getdisplayTTPopup();
            myPageCon.getdisplayTTAttribute();
            
            
            myPageCon.getDisplayTopBlockLevelMessage();
            myPageCon.getDisplayBotBlockLevelMessage();
            myPageCon.getDisplayADJTTLevelMessage();
            myPageCon.getDisplaySEARCHTTLevelMessage();
            System.assertEquals(true,myPageCon.getDisplayTopBlockLevelMessage() != null);
            System.assertEquals(true, myPageCon.getDisplayBotBlockLevelMessage() != null);
            System.assertEquals(true, myPageCon.getDisplayADJTTLevelMessage() != null);
            System.assertEquals(true, myPageCon.getDisplaySEARCHTTLevelMessage() != null);
            
            myPageCon.getbidir();
            myPageCon.setbidir(true);
            myPageCon.getShowAddEdit();
            myPageCon.getTeritoryKeyword();
            myPageCon.setTeritoryKeyword('Set');
            myPageCon.getIsADJAvail();
            myPageCon.getIsSRAvail();
            myPageCon.GoSetupHome();
            myPageCon.AddAdjTrtry();
            myPageCon.DelAdjTrtry();
            
            myPageCon.getSpeed();
            myPageCon.setSpeed('');
            myPageCon.getDistance();
            myPageCon.setDistance('');
            myPageCon.getCost();
            myPageCon.setCost('');
            //myPageCon.TerritorySearch();
            myPageCon.AddSelectedTrtry();
            myPageCon.getwrapSetADJ();
            myPageCon.TTId=T1.Id;
            
            SVMXC__Territory_Coverage__c NewTTaA = new SVMXC__Territory_Coverage__c();
            SORG_ManageTerritory.wrapperTTA Twrapa = new SORG_ManageTerritory.wrapperTTA(NewTTaA,true);
            myPageCon.wrapSetADJ.add(Twrapa);
            SVMXC__Territory_Coverage__c NewTTAa2 = new SVMXC__Territory_Coverage__c();
            SORG_ManageTerritory.wrapperTTA Twrapa2 = new SORG_ManageTerritory.wrapperTTA(NewTTAa2,false);
            myPageCon.wrapSetADJ.add(Twrapa2);
            
            myPageCon.checkAdjcency(String.valueof(T1.Id), String.valueof(T1.Id));
            myPageCon.SaveAdjTrtry();
            
            myPageCon.getwrapSetCOV();
            myPageCon.getwrapSearchRes();
            SVMXC__Territory__c t=new SVMXC__Territory__c();
            SORG_ManageTerritory.wrapperTT Twraps = new SORG_ManageTerritory.wrapperTT(t,true);
            
            
            //Methods
            //Changes done for defect 007042.
            //myPageCon.getTerritoryJSONString();
            myPageCon.loadTerritory();
            myPageCon.hideTerritoryAtt();
            myPageCon.TTId=T1.Id;
            myPageCon.showTerritory();
            myPageCon.loadTTattribute();
            myPageCon.getIsListAvail();
            //OnSave_validation method
            List<SVMXC__Territory_Coverage__c> TTattribute_Temp= new List<SVMXC__Territory_Coverage__c>();
            SVMXC__Territory_Coverage__c TTA1_temp= new SVMXC__Territory_Coverage__c(SVMXC__Active__c=true,SVMXC__Type__c='',SVMXC__value__c='',SVMXC__Territory__c=T1.Id);
            TTattribute_Temp.add(TTA1_temp);
            myPageCon.OnSave_validation(TTattribute_Temp);
            //
            SVMXC__Territory_Coverage__c NewTTA = new SVMXC__Territory_Coverage__c(SVMXC__Active__c=true,SVMXC__Type__c='Zip',SVMXC__value__c='ZIP001');
            SORG_ManageTerritory.wrapperTTA Twrap = new SORG_ManageTerritory.wrapperTTA(NewTTA,true);
            myPageCon.wrapSetCOV .add(Twrap);
            SVMXC__Territory_Coverage__c NewTTA2 = new SVMXC__Territory_Coverage__c(SVMXC__Active__c=true,SVMXC__Type__c='Zip',SVMXC__value__c='ZIP001');
            SORG_ManageTerritory.wrapperTTA Twrap2 = new SORG_ManageTerritory.wrapperTTA(NewTTA2,false);
            myPageCon.wrapSetCOV .add(Twrap2);
                    
            myPageCon.SaveTrtryAtrbute();
            myPageCon.DelTrtryAtrbute();
            myPageCon.AddTrtry_Atrbute();
            myPageCon.editTerritory();
            myPageCon.SaveTrtryPopUp(); 
            myPageCon.showTerritory();
            myPageCon.SaveTrtryPopUp();
            myPageCon.AddTrtry= new SVMXC__Territory__c(Name='T2',SVMXC__Active__c=true,SVMXC__Territory_Code__c='T2',SVMXC__Parent_Territory__c=T1.Id);
            myPageCon.SaveTrtryPopUp();
            myPageCon.ClosePopUp();
            myPageCon.showZipPopup();
            myPageCon.setZipStart('1');
            myPageCon.setZipEnd('3');
            myPageCon.SaveZipPopUp();
            myPageCon.setZipStart('4');
            myPageCon.setZipEnd('1');
            myPageCon.SaveZipPopUp();
            myPageCon.IsNumber('11');
            //myPageCon.ReorderTrtry();
            myPageCon.getAvailCountry();
            myPageCon.getSelectedCountry();
            myPageCon.showCountryPopup();
            myPageCon.onAddCountry();
            myPageCon.onRemCountry();    
            myPageCon.SaveCountryPopUp();  
            myPageCon.DelTerritory();
            
            myPageCon.getDelDispCountRec();
            myPageCon.setDelDispCountRec(true);
            myPageCon.getDsptchrList();
            myPageCon.getCheckAllDisp();
            myPageCon.setCheckAllDisp(true);
            myPageCon.getChildTabs();
            myPageCon.setChildTabs(true);
            myPageCon.getUserList();
            myPageCon.getTAG081();
            myPageCon.getTAG082();
            myPageCon.getTAG083();
            myPageCon.getTAG084();
            myPageCon.getTAG085();
            myPageCon.getTAG086();
            myPageCon.getTAG087();        
            myPageCon.getTAG088();
            myPageCon.getTAG089();
            myPageCon.getTAG090();
            myPageCon.getTAG091();
            myPageCon.getTAG092();
            myPageCon.getTAG093();
            myPageCon.getTAG094();
            myPageCon.getTAG095();
            myPageCon.getTAG096();
            myPageCon.getTAG097();
            myPageCon.getTAG098();
            myPageCon.getTAG117();
            ////myPageCon.getTAG154();
            ////myPageCon.getTAG105();                        
            myPageCon.getDispKywrd();
            myPageCon.setDispKywrd(Userinfo.getName());
            myPageCon.SVMX_DispatchSearch();
            myPageCon.UserSearchCancel();
            myPageCon.getSaveDispCountRec();
            myPageCon.setSaveDispCountRec(true);
            myPageCon.getSaveUsrListSize();
            myPageCon.setSaveUsrListSize(true);
            myPageCon.getAddUserCountRec();
            myPageCon.setAddUserCountRec(true);
            myPageCon.getUserExist();
            myPageCon.setUserExist(true);
            myPageCon.SVMX_AddDisptacher();
            myPageCon.SVMX_AddUsertoDispatch();
            myPageCon.SVMX_SaveDispToTeam();
            myPageCon.SVMX_DelDisptch();
            //myPageCon.TerritorySearch();
            List<SelectOption> so = new List<SelectOption>();
            myPageCon.sortingSelectSelectedCOption(so);
            myPageCon.getOnLoad();
            myPageCon.SpecialCharParser('SpecialCharParser');
            myPageCon.getUserID();
            myPageCon.getUserOrgID();
            myPageCon.getZoneDefinitionPage();
            myPageCon.setZoneDefinitionPage('setZoneDefinitionPage');
            myPageCon.getUserLocaleKey();
            myPageCon.getUserLocaleKey();
            test.stoptest(); 
        }
        catch(Exception ex){}
    }
}