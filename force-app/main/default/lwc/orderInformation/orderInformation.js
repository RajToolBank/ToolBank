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
export default class OrderInformation extends LightningElement {

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
    zipCodeList;


    desiredPickupTime;
    borrowingPeriod;
    projectType
    areasImpacted;
    projectVenue;
    serving;
    volunteerSource;
    fieldsInfo;
    orderMetadata;

    @wire(accid) getaccid({data,error}){
        if(data){
            
            this.affiliateId = data;
        }
    };

    @wire(getAgencyContact) getAgencyContact({data,error}){
        if(data){
            console.log(data);
            if(data.Contact){
                this.accountId = data.Contact.AccountId;
                this.contactId = data.ContactId;
                if(data.Contact.Account){
                    this.accountName = data.Contact.Account.Name;
                }
                this.contactName = data.Contact.Name;
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

    @wire(getPicklistValues, { recordTypeId: '$orderMetadata.data.defaultRecordTypeId',  fieldApiName: PROJECT_TYPE }) 
    wiredprojectType({data, error}){
        if(data){
            
            this.projectType = data.values;
            //console.log(this.projectType);
        }
        if(error){

        }
    };


    @wire(getPicklistValues, { recordTypeId: '$orderMetadata.data.defaultRecordTypeId',  fieldApiName: AREAS_IMPACT }) 
    wiredareasImpacted({data, error}){
        if(data){
            this.areasImpacted  = data.values;
        }
        if(error){

        }
    };

    @wire(getPicklistValues, { recordTypeId: '$orderMetadata.data.defaultRecordTypeId',  fieldApiName: PROJECT_VENUE }) 
    wiredprojectVenue({data, error}){
        if(data){
            this.projectVenue  = data.values;
        }
        if(error){

        }
    };

    @wire(getPicklistValues, { recordTypeId: '$orderMetadata.data.defaultRecordTypeId',  fieldApiName: SERVING }) 
    wiredserving({data, error}){
        if(data){
            this.serving  = data.values;
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
        const offset =  new Date().getTimezoneOffset()
        pickupdate = new Date(pickupdate.getTime()+offset*60000);
        pickupdate = new Date(pickupdate.setHours(0, 0, 0, 0));
        todayDate = new Date(todayDate.getTime());
        console.log(offset);
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
            week = (week*7)+1;
            pickupdate.setDate(pickupdate.getDate() + week);
            let ye = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(pickupdate);
            let mo = new Intl.DateTimeFormat('en', { month: 'numeric' }).format(pickupdate);
            let da = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(pickupdate);
            returnDate.value = `${ye}-${mo}-${da}`;
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
            
            
                orderinfo.value=data.record.Email;
                this.contactId = data.record.Id;
            
            
        }else{
            orderinfo.value="";
            this.contactId = null;
        }
    }

    handleLookupAcc = (event) => {
        let data = event.detail.data;
        if(data && data.record){
          
                this.accountId = data.record.Id;
            
        }else this.accountId = null;
    }

    handleProjectType(event){
        let state = event.target.checked;
        if(state){
            this.proType.push(event.target.value);
        }else{
            this.proType.pop(event.target.value);
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
        let projectVolunteerHr = this.template.querySelector(`[data-id="projectVolunteerHr"]`);corpname
        let corpname = this.template.querySelector(`[data-id="corpname"]`);

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
        let errormsg = "This Field is Required"
        let errormsgList = "Please Select at least One Option"


        if(!this.accountId)
            accerror.innerHTML =errormsg;
        else accerror.innerHTML ="";

        if(!this.contactId)
        conerror.innerHTML =errormsg;
        else conerror.innerHTML ="";

        if(!pickupDate.value)
        pickDateerror.innerHTML =errormsg;
        else pickDateerror.innerHTML ="";

        if(!pickupTime.value)
        pickTimeerror.innerHTML =errormsg;
        else pickTimeerror.innerHTML ="";
        
        if(!returnDate.value)
        returnerror.innerHTML =errormsg;
        else returnerror.innerHTML ="";
        
        if(!this.borrowing)
        weekerror.innerHTML =errormsg;
        else weekerror.innerHTML ="";
        
        if(!ordName.value)
        nameerror.innerHTML =errormsg;
        else nameerror.innerHTML ="";
        
        if(!peopledirectlyserved.value)
        servederror.innerHTML =errormsg;
        else servederror.innerHTML ="";
        
        if(!numberProject.value)
        projecterror.innerHTML =errormsg;
        else projecterror.innerHTML ="";
        
        if(!this.volSrc)
        sourceerror.innerHTML =errormsg;
        else sourceerror.innerHTML ="";
        
        let corporationName;
        if(this.corp && !corpname.value)
        corperror.innerHTML =errormsg;
        else if(this.corp) {
            corperror.innerHTML ="";
            corporationName = corpname.value;
        }
        
        if(!onsitehours.value)
        onSiteerror.innerHTML =errormsg;
        else onSiteerror.innerHTML ="";
        
        if(!volunteersnumber.value) 
        volerror.innerHTML =errormsg;
        else volerror.innerHTML ="";
        
        if(!peopleImImpacted.value)
        impacterror.innerHTML =errormsg;
        else impacterror.innerHTML ="";
        
        if(!staff.value)
        stafferror.innerHTML =errormsg;
        else stafferror.innerHTML ="";
        
        let notvalidcode = false;
        if(!zip.value){
        ziperror.innerHTML =errormsg;
        notvalidcode = true;
        }
        else{ 
            const myArray = zip.value.split(",");
            for(const i in myArray){
                if(this.zipCodeList.indexOf(myArray[i]) < 0){
                    notvalidcode = true;
                    break;
                }
            }
            if(notvalidcode)
            ziperror.innerHTML ="Please enter a valid zip code";
            else ziperror.innerHTML ="";
        }
        
        if(!projectVolunteerHr.value)
        hourerror.innerHTML =errormsg;
        else hourerror.innerHTML ="";
       
        if(this.proType.length <=0)
        projectTyeperror.innerHTML =errormsgList;
        else projectTyeperror.innerHTML ="";
        
        if(this.impactArea.length <=0)
        areaserror.innerHTML =errormsgList;
        else areaserror.innerHTML ="";
        
        if(this.proVenue.length <=0)
        venueerror.innerHTML =errormsgList;
        else {
            venueerror.innerHTML ="";
        }

        let homeValue;
        if(this.home && !home.value){
                homeerror.innerHTML = errormsg;           
        }else if(this.home) { 
            homeerror.innerHTML = "";
            homeValue = home.value;
        }
        
        if(!this.serv)
        radioerror.innerHTML =errormsg;
        else radioerror.innerHTML ="";
        
        

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