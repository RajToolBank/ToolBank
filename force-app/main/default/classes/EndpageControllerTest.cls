@isTest
public class EndpageControllerTest {
    
    @isTest
    static void unitTest_1(){
        PageReference pageRef = Page.toolbankorg;
        Test.setCurrentPage(pageRef);
        // put the lead id as a parameter
        ApexPages.currentPage().getParameters().put('toolbank','Toolbank_USA');
        EndpageController obj = new EndpageController();
        ApexPages.currentPage().getParameters().put('toolbank','');
        EndpageController obj2 = new EndpageController();
    }
}