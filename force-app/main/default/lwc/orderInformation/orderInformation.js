import { api, LightningElement, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import ORDER_OBJECT from '@salesforce/schema/Order';
import PICKUP_TIME from '@salesforce/schema/Order.Desired_Pickup_Time__c';
import BORROWING_PERIOD from '@salesforce/schema/Order.Requested_Borrowing_Period__c';
import PROJECT_TYPE from '@salesforce/schema/Order.Project_Type__c';
import AREAS_IMPACT from '@salesforce/schema/Order.Areas_Of_Impact__c';
import PROJECT_VENUE from '@salesforce/schema/Order.Project_Venue__c';
import SERVING from '@salesforce/schema/Order.Serving_50_of_Low_Income_People__c';
import VOLUNTEER_SRC from '@salesforce/schema/Order.Volunteer_Source__c';
import zipCodeList from '@salesforce/apex/PlaceOrderController.zipCodes';
import accid from '@salesforce/apex/PlaceOrderController.accid';
import getAgencyContact from '@salesforce/apex/PlaceOrderController.getAgencyContact';
import getPicklistValuesApex from '@salesforce/apex/PlaceOrderController.getPicklistValuesApex';
import TIME_ZONE from '@salesforce/i18n/timeZone';
export default class OrderInformation extends LightningElement {

    timeZone = TIME_ZONE;
    fieldsToCreate = ['Name','Rating','Phone','Industry'];
    fields        = ['Name'];
    PickupTime;
    borrowing;
    proType=[];
    impactArea = [];
    proVenue = [];
    accountId;
    contactId;
    accountName;
    contactName;
    @api
    affiliateId;
    serv;
    volSrc;
    returndate;
    corp = false;
    home = false;
    specialEvents = false;
    zipCodeList;
    @api
    email ="";


    desiredPickupTime;
    borrowingPeriod;
    projectType
    areasImpacted;
    projectVenue;
    serving;
    volunteerSource;
    fieldsInfo;
    orderMetadata;

    
    /*
*/
    @wire(accid) getaccid({data,error}){
        if(data){
            
            this.affiliateId = data;
        }
    };
   @wire(getAgencyContact) getAgencyContact({data,error}){
        if(data){
            console.log("data.Contact");
            console.log(data);
            if(data.Contact){
                if(data.Contact.npsp__Primary_Affiliation__c){
                this.accountId = data.Contact.npsp__Primary_Affiliation__c;
                this.accountName = data.Contact.npsp__Primary_Affiliation__r.Name;
                this.contactId = data.ContactId;
                
                this.contactName = data.Contact.Name;
                this.email = data.Contact.Email;
                }else if(data.UserType && data.UserType !== "PowerPartner"){ 
                    this.accountId = data.Contact.AccountId;
                    this.accountName = data.Contact.Account.Name;
                    this.contactId = data.ContactId;
                
                    this.contactName = data.Contact.Name;
                    this.email = data.Contact.Email;
                }
                
                
            }
        }
    };

    @wire(zipCodeList) zipCodesList({data,error}){
        if(data){
            
            this.zipCodeList = data;
        }
    };

    @wire(getObjectInfo, { objectApiName: ORDER_OBJECT })
    getorderMetadata(result){
        if(result.data){
            this.fieldsInfo = result.data.fields;
            this.orderMetadata = result;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$orderMetadata.data.defaultRecordTypeId',  fieldApiName: PICKUP_TIME }) 
    wireddesiredPickupTime({data, error}){
        if(data){
            this.desiredPickupTime  = data.values;
        }
        if(error){

        }
    };

    @wire(getPicklistValues, { recordTypeId: '$orderMetadata.data.defaultRecordTypeId',  fieldApiName: BORROWING_PERIOD }) 
    wiredborrowingPeriod({data, error}){
        if(data){
            this.borrowingPeriod  = data.values;
        }
        if(error){

        }
    };

    @wire(getPicklistValuesApex, { field_name: "Project_Type__c" }) 
    wiredprojectType({data, error}){
        if(data){
            
            this.projectType = data;
            //console.log(this.projectType);
        }
        if(error){

        }
    };


    @wire(getPicklistValuesApex, {  field_name: "Areas_Of_Impact__c" }) 
    wiredareasImpacted({data, error}){
        if(data){
            this.areasImpacted  = data;
        }
        if(error){

        }
    };

    @wire(getPicklistValuesApex, { field_name: "Project_Venue__c" }) 
    wiredprojectVenue({data, error}){
        if(data){
            this.projectVenue  = data;
            console.log("Project_Venue__c data");
            console.log(data);
        }
        if(error){
            console.log("Project_Venue__c error");
            console.log(error);
        }
    };

    @wire(getPicklistValuesApex, { field_name: "Serving_50_of_Low_Income_People__c" }) 
    wiredServing({data, error}){
        if(data){
            this.serving  = data;
        }
        if(error){

        }
    };

   

    @wire(getPicklistValues, { recordTypeId: '$orderMetadata.data.defaultRecordTypeId',  fieldApiName: VOLUNTEER_SRC }) 
    wiredVolSrc({data, error}){
        if(data){
            this.volunteerSource  = data.values;
        }
        if(error){

        }
    };
    handleMultiPickChange(event){
        let data = event.detail;
        this.proType = data;
    }


    handleWeekChange(event){ 
        let data = this.template.querySelector(`[data-id="Week"]`);
        let pickDateerror = this.template.querySelector(`[data-id="pickDateerror"]`);
        let returnerror = this.template.querySelector(`[data-id="returnerror"]`);
        let pickDate =this.template.querySelector(`[data-id="pickupDate"]`);
        let returnDate =this.template.querySelector(`[data-id="returnDate"]`);
        console.log(pickDate.value);
        let pickupdate = new Date(pickDate.value);
        let todayDate = new Date(new Date().setHours(0, 0, 0, 0));
        //const offset =  new Date().getTimezoneOffset()
       // pickupdate = new Date(pickupdate.getTime()+offset*60000);
       console.log(todayDate); 
       console.log(pickupdate);
        pickupdate = new Date(pickupdate.setHours(23,59,59,59)).toLocaleString("en-US", {timeZone: this.timeZone});
        todayDate = new Date(todayDate.getTime()).toLocaleString("en-US", {timeZone: this.timeZone});
        //console.log(offset);
        pickupdate = new Date(pickupdate);
        todayDate = new Date(new Date(todayDate).setHours(23,59,59,59)).toLocaleString("en-US", {timeZone: this.timeZone});
        todayDate = new Date(todayDate);
        console.log(todayDate); 
        console.log(pickupdate);
        if(pickupdate < todayDate){
            pickDateerror.innerHTML ="Pickup Date can not be in the past";
            returnDate.value ="";
            return;
        }else{
            pickDateerror.innerHTML ="";
        }

        this.borrowing = data.value;
        if(this.borrowing){
            
            console.log(this.borrowing);
            let borrow = this.borrowing.replace("weeks", "");
            borrow = this.borrowing.replace("week", "");
            let week = parseInt(borrow)
            week = (week*7);
            pickupdate.setDate(pickupdate.getDate() + week+1);
            pickupdate = pickupdate.toLocaleString("en-US", {timeZone: this.timeZone});
            pickupdate = new Date(pickupdate);
            let ye = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(pickupdate);
            let mo = new Intl.DateTimeFormat('en', { month: '2-digit' }).format(pickupdate);
            let da = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(pickupdate);
            const tagId = event.target.dataset.id;
            if(tagId !== "returnDate"){
                returnDate.value = `${ye}-${mo}-${da}`;
                returnerror.innerHTML = "";
            }else {
                let retvalue = `${ye}-${mo}-${da}`;
                let selectedValue = event.target.value;
               
                console.log(retvalue);
                console.log(selectedValue);
                const diff = (new Date(retvalue)- new Date(selectedValue))/(1000*60*60*24)
                console.log(diff);
                if((retvalue < selectedValue) || diff >= 7){
                    returnerror.innerHTML = "Return date is not aligned with Pickup date and borrowing week, please fix the dates";
                }else{
                    returnerror.innerHTML = "";
                }
            }
        }
        
    }

    handleVolSrcChange(event){
        let data = event.detail.value;
        this.volSrc = data;
        if(data == 'Corporate Volunteers')
            this.corp = true
        else this.corp = false;
    }

    handleLookup = (event) => {
        let data = event.detail.data;
        let orderinfo = this.template.querySelector(`[data-id="email"]`);
        
       
        if(data && data.record){
            console.log(JSON.parse(JSON.stringify(data)));
                orderinfo.value=data.record.Email;
                this.email  =data.record.Email;
                this.contactId = data.record.Id;
            
            
        }else{
            orderinfo.value="";
            this.contactId = null;
        }
    }

    handleLookupAcc = (event) => {
        let data = event.detail.data;
        let orderinfo = this.template.querySelector(`[data-id="email"]`);
        
        this.contactId = null;
        orderinfo.value="";
        this.email  =undefined;
        this.contactName = null;
        this.template.querySelector(`[data-id="ContactSearch"]`).handleRecordClear(event);
        if(data && data.record){
            this.accountId = data.record.Id;
        }else {
            this.accountId = null;
        }
    }

    handleProjectType(event){
        let state = event.target.checked;
        if(state){
            this.proType.push(event.target.value);
            if(event.target.value === "Special Events/Fundraisers")
                this.specialEvents = true;
        }else{
            this.proType.pop(event.target.value);
            if(event.target.value === "Special Events/Fundraisers")
                this.specialEvents = false;
        }
    }

    handleAreaImpact(event){
        let state = event.target.checked;
        if(state){
            this.impactArea.push(event.target.value);
        }else{
            this.impactArea.pop(event.target.value);
        }

    }

    handleProjectVanue(event){
        let state = event.target.checked;
        if(state){
            this.proVenue.push(event.target.value);
            if(event.target.value === "Residence or Home")
                this.home = true;
        }else{
            if(event.target.value === "Residence or Home")
                this.home = false;
            this.proVenue.pop(event.target.value);
        }
    }

    handleserv(event){
        let state = event.target.checked;
        if(state){
            this.serv = event.target.value;
        }
    }

    handleContinue(event){
        event.preventDefault();

        //const name = event.target.value;
        let pickupDate = this.template.querySelector(`[data-id="pickupDate"]`);
        let pickupTime = this.template.querySelector(`[data-id="pickupTime"]`);
        let returnDate = this.template.querySelector(`[data-id="returnDate"]`);
        let ordName = this.template.querySelector(`[data-id="orderName"]`);
        let zip = this.template.querySelector(`[data-id="zipcode"]`);
        let peopledirectlyserved = this.template.querySelector(`[data-id="peopledirectlyserved"]`);
        let numberProject = this.template.querySelector(`[data-id="numberProject"]`);
        let onsitehours = this.template.querySelector(`[data-id="onsitehours"]`);
        let volunteersnumber = this.template.querySelector(`[data-id="volunteersnumber"]`);
        let peopleImImpacted = this.template.querySelector(`[data-id="peopleImImpacted"]`);
        let staff = this.template.querySelector(`[data-id="staff"]`);
        let projectVolunteerHr = this.template.querySelector(`[data-id="projectVolunteerHr"]`);
        let corpname = this.template.querySelector(`[data-id="corpname"]`);
        let borrowingPeriod = this.template.querySelector(`[data-id="Week"]`);
        let volunteersource = this.template.querySelector(`[data-id="volunteersource"]`);

        let accerror = this.template.querySelector(`[data-id="accerror"]`);
        let conerror = this.template.querySelector(`[data-id="conerror"]`);
        let pickDateerror = this.template.querySelector(`[data-id="pickDateerror"]`);
        let pickTimeerror = this.template.querySelector(`[data-id="pickTimeerror"]`);
        let weekerror = this.template.querySelector(`[data-id="weekerror"]`);
        let returnerror = this.template.querySelector(`[data-id="returnerror"]`);
        let nameerror = this.template.querySelector(`[data-id="nameerror"]`);
        let servederror = this.template.querySelector(`[data-id="servederror"]`);
        let projecterror = this.template.querySelector(`[data-id="projecterror"]`);
        let sourceerror = this.template.querySelector(`[data-id="sourceerror"]`);
        let corperror = this.template.querySelector(`[data-id="corperror"]`);
        let onSiteerror = this.template.querySelector(`[data-id="onSiteerror"]`);
        let volerror = this.template.querySelector(`[data-id="volerror"]`);
        let impacterror = this.template.querySelector(`[data-id="impacterror"]`);
        let stafferror = this.template.querySelector(`[data-id="stafferror"]`);
        let ziperror = this.template.querySelector(`[data-id="ziperror"]`);
        let hourerror = this.template.querySelector(`[data-id="hourerror"]`);
        let projectTyeperror = this.template.querySelector(`[data-id="projectTyeperror"]`);
        let areaserror = this.template.querySelector(`[data-id="areaserror"]`);
        let venueerror = this.template.querySelector(`[data-id="venueerror"]`);
        let radioerror = this.template.querySelector(`[data-id="radioerror"]`);
        let home = this.template.querySelector(`[data-id="home"]`);
        let homeerror = this.template.querySelector(`[data-id="homeerror"]`);
        let specialEvents = this.template.querySelector(`[data-id="specialEvents"]`);
        let specialEventserror = this.template.querySelector(`[data-id="specialEventserror"]`);
        let errormsg = "This Field is Required"
        let errormsgList = "Please Select at least One Option"

        if(!this.serv){
            radioerror.innerHTML =errormsg;
            this.template.querySelector(`[data-id="`+this.serving[0].label+`"]`).focus();
        }
        else radioerror.innerHTML ="";

        let numAttend;
        if(this.specialEvents && !specialEvents.value){
            specialEventserror.innerHTML = errormsg;  
            specialEvents.focus();         
        }else if(this.specialEvents) { 
            specialEventserror.innerHTML = "";
            numAttend = specialEvents.value;
        }

        let homeValue;
        if(this.home && !home.value){
                homeerror.innerHTML = errormsg;  
                home.focus();         
        }else if(this.home) { 
            homeerror.innerHTML = "";
            homeValue = home.value;
        }

        if(this.proVenue.length <=0){
            venueerror.innerHTML =errormsgList;
            this.template.querySelector(`[data-id="`+this.projectVenue[0].label+`"]`).focus();
        }
        else {
            venueerror.innerHTML ="";
        }

        if(this.impactArea.length <=0){
            areaserror.innerHTML =errormsgList;
            this.template.querySelector(`[data-id="`+this.areasImpacted[0].label+`"]`).focus();
        }
        else areaserror.innerHTML ="";
    
        if(this.proType.length <=0){
            projectTyeperror.innerHTML =errormsgList;
            this.template.querySelector(`[data-id="`+this.projectType[0].label+`"]`).focus();
        }
        else projectTyeperror.innerHTML ="";

        if(!projectVolunteerHr.value){
            hourerror.innerHTML =errormsg;
            projectVolunteerHr.focus();
        }
        else hourerror.innerHTML ="";

        let notvalidcode = false;
        if(!zip.value){
        ziperror.innerHTML =errormsg;
        notvalidcode = true;
        zip.focus();
        }
        else{ 
            const myArray = zip.value.split(",");
            for(const i in myArray){
                if(this.zipCodeList.indexOf((myArray[i]).trim()) < 0){
                    notvalidcode = true;
                    break;
                }
            }
            if(notvalidcode){
                ziperror.innerHTML ="Please enter a valid zip code,enter with the comma delimeted and remove any extra spaces.";
                zip.focus();
            }
            else ziperror.innerHTML ="";
        }
        
        if(!staff.value){
            stafferror.innerHTML =errormsg;
            staff.focus();
        }
        else stafferror.innerHTML ="";
        
        if(!peopleImImpacted.value){
            impacterror.innerHTML =errormsg;
            peopleImImpacted.focus();
        }
        else impacterror.innerHTML ="";
        
        if(!volunteersnumber.value){
            volerror.innerHTML =errormsg;
            volunteersnumber.focus();
        }
        else volerror.innerHTML ="";
        
        if(!onsitehours.value){
            onSiteerror.innerHTML =errormsg;
            onsitehours.focus();
        }
        else onSiteerror.innerHTML ="";
        
        let corporationName;
        if(this.corp && !corpname.value){
        corperror.innerHTML =errormsg;
        corpname.focus();
        }
        else if(this.corp) {
            corperror.innerHTML ="";
            corporationName = corpname.value;
        }
        
        if(!this.volSrc){
            sourceerror.innerHTML =errormsg;
            volunteersource.focus();
        }
        else sourceerror.innerHTML ="";
        
        
        if(!numberProject.value){
            projecterror.innerHTML =errormsg;
            numberProject.focus();
        }
        else projecterror.innerHTML ="";
        
        if(!peopledirectlyserved.value){
            servederror.innerHTML =errormsg;
            peopledirectlyserved.focus();
        }
        else servederror.innerHTML ="";
       
        
        if(!ordName.value){
            nameerror.innerHTML =errormsg;
            ordName.focus();
        }
        else nameerror.innerHTML ="";
        
        
        if(!returnDate.value){
            returnerror.innerHTML =errormsg;
            returnDate.focus();
        }
        else returnerror.innerHTML ="";

        if(!this.borrowing){
            weekerror.innerHTML =errormsg;
            borrowingPeriod.focus();
        }
        else weekerror.innerHTML ="";

        if(!pickupTime.value){
            pickTimeerror.innerHTML =errormsg;
            pickupTime.focus();
        }
        else pickTimeerror.innerHTML ="";

        if(!pickupDate.value){
            pickDateerror.innerHTML =errormsg;
            pickupDate.focus()
        }
        else pickDateerror.innerHTML ="";
        
        if(!this.contactId)
            conerror.innerHTML =errormsg;
        else conerror.innerHTML ="";
        
        if(!this.accountId){
            accerror.innerHTML =errormsg;
        }
        else accerror.innerHTML ="";

        if(this.accountId 
            && this.contactId 
            && pickupDate.value 
            && pickupTime.value 
            && returnDate.value
            && this.borrowing
            && ordName.value
            && peopledirectlyserved.value
            && numberProject.value
            && this.volSrc
            && (!this.corp || (this.corp && corporationName))
            && (!this.home || (this.home && home.value))
            && (!this.specialEvents || (this.specialEvents && specialEvents.value))
            && onsitehours.value
            && volunteersnumber.value
            && peopleImImpacted.value
            && staff.value
            && !notvalidcode
            && projectVolunteerHr.value
            && this.proType.length >0
            && this.impactArea.length >0
            && this.proVenue.length >0
            && this.serv){
            const selectEvent = new CustomEvent('orderinformation', {
            detail: { 
                        name:ordName.value,
                        zip:zip.value,
                        serv:this.serv,
                        proVenue :this.proVenue,
                        proType:this.proType,
                        impactArea:this.impactArea,
                        accountId:this.accountId,
                        contactId:this.contactId,
                        pickdate:pickupDate.value,
                        pickTime:pickupTime.value,
                        retDate:returnDate.value,
                        numAttend:numAttend,
                        home:homeValue,
                        duration:this.borrowing,
                        affiliateid:this.affiliateId,
                        peopledirectlyserved:peopledirectlyserved.value,
                        numberProject:numberProject.value,
                        onsitehours:onsitehours.value,
                        volunteersnumber:volunteersnumber.value,
                        peopleImImpacted:peopleImImpacted.value,
                        staff:staff.value,
                        projectVolunteerHr:projectVolunteerHr.value,
                        volunteersource:this.volSrc,
                        corpname:corporationName

                    }
            });
            this.dispatchEvent(selectEvent);
        }
    }

    handleQuantity(event){
        event.target.value=event.target.value.replace(/[^0-9]/g,'');
        
    }
}