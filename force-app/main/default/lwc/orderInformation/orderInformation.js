import { api, LightningElement, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import ORDER_OBJECT from '@salesforce/schema/Order';
import PICKUP_TIME from '@salesforce/schema/Order.Desired_Pickup_Time__c';
import BORROWING_PERIOD from '@salesforce/schema/Order.Requested_Borrowing_Period__c';
import VOLUNTEER_SRC from '@salesforce/schema/Order.Volunteer_Source__c';
import zipCodeList from '@salesforce/apex/PlaceOrderController.zipCodes';
import accid from '@salesforce/apex/PlaceOrderController.accid';
import getAgencyContact from '@salesforce/apex/PlaceOrderController.getAgencyContact';
import getPicklistValuesApex from '@salesforce/apex/PlaceOrderController.getPicklistValuesApex';
import getBusinessHours from '@salesforce/apex/PlaceOrderController.getBusinessHours';
import TIME_ZONE from '@salesforce/i18n/timeZone';
export default class OrderInformation extends LightningElement {

    @api recordId;
    timeZone = TIME_ZONE;
    fieldsToCreate = ['Name','Rating','Phone','Industry'];
    fields        = ['Name'];
    PickupTime;
    borrowing;
    proType=[];
    impactArea = [];
    proVenue = [];
    @api accountId;
    @api contactId;
    @api accountName;
    @api contactName;
    @api
    affiliateId;
    serv;
    volSrc;
    returneddate;
    desiredpickupdate;
    corp = false;
    home = false;
    specialEvents = false;
    zipCodeList;
    @api
    email ="";
    loaded = true;
    businessHours;


    @track desiredPickupTime;
    borrowingPeriod;
    projectType
    areasImpacted;
    projectVenue;
    serving;
    volunteerSource;
    fieldsInfo;
    orderMetadata;
    workingHours;
    
    
    /*
*/

    connectedCallback(){
        const acctId = (this.recordId !== null && this.recordId !==""? this.recordId:this.affiliateId);
        console.log("connected callback:: "+acctId);
        getAgencyContact({
            recordId:this.recordId,
            affiliateId:this.affiliateId
        }).then(res=>{
            this.loaded = false;
            console.log(res);
            this.contactId = res.contactId;
            this.contactName = res.contactName;
            this.email = res.contactEmail;
            this.accountId = res.contactAccountId;
            this.accountName = res.contactAccountName;
            return getBusinessHours({affiliateId:this.affiliateId});
        }).then(res=>{
            this.businessHours = res;
        }).catch(err =>{
            console.log(err);
        })
    }
    @wire(accid) getaccid({data,error}){
        if(data){
            
            this.affiliateId = data;
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
            this.workingHours  =data.values;
            this.desiredPickupTime = data.values;
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


    onPickDateSelect(event){
        let selectedDate = event.detail.selectedDate;
        const day = selectedDate.getDay();
        let businessDays = JSON.parse(JSON.stringify(this.businessHours));
        const saturdayStartTime = businessDays.Saturday_Start_Time__c;
        const saturdayEndTime = businessDays.Saturday_End_Time__c;
        const sundayStartTime = businessDays.Sunday_Start_Time__c;
        const sundayEndTime = businessDays.Sunday_End_Time__c;
        const mondayStartTime = businessDays.Monday_Start_Time__c;
        const mondayEndTime = businessDays.Monday_End_Time__c;
        const tuesdayStartTime = businessDays.Tuesday_Start_Time__c;
        const tuesdayEndTime = businessDays.Tuesday_End_Time__c;
        const wednesdayStartTime = businessDays.Wednesday_Start_Time__c;
        const wednesdayEndTime = businessDays.Wednesday_End_Time__c;
        const thursdayStartTime = businessDays.Thursday_Start_Time__c;
        const thursdayEndTime = businessDays.Thursday_End_Time__c;
        const fridayStartTime = businessDays.Friday_Start_Time__c;
        const fridayEndTime = businessDays.Friday_End_Time__c;
        let pickupOptions= [];
        for(let i in this.workingHours){
            const [hourString, minuteString] = this.workingHours[i].value.split(':');
            const hour = minuteString.includes('AM')? hourString.split(' ')[0]: (parseInt(hourString.split(' ')[0]) === 12?12:(parseInt(hourString.split(' ')[0]) + 12)); // Convert to 24-hour format by adding 12
            const minute = minuteString.includes('AM')?minuteString.split(' ')[0]:minuteString.split(' ')[0];
            
            const milliseconds = (hour * 60 * 60 + minute * 60) * 1000;
           
            if(day === 0 && milliseconds >= sundayStartTime && milliseconds <= sundayEndTime)
                pickupOptions.push(this.workingHours[i]);
            else if(day === 1 && milliseconds >= mondayStartTime && milliseconds <= mondayEndTime)
                pickupOptions.push(this.workingHours[i]);
            else if(day === 2 && milliseconds >= tuesdayStartTime && milliseconds <= tuesdayEndTime)
                pickupOptions.push(this.workingHours[i]);
            else if(day === 3 && milliseconds >= wednesdayStartTime && milliseconds <= wednesdayEndTime)
                pickupOptions.push(this.workingHours[i]);
            else if(day === 4 && milliseconds >= thursdayStartTime && milliseconds <= thursdayEndTime)
                pickupOptions.push(this.workingHours[i]);
            else if(day === 5 && milliseconds >= fridayStartTime && milliseconds <= fridayEndTime)
                pickupOptions.push(this.workingHours[i]);
            else if(day === 6 && milliseconds >= saturdayStartTime && milliseconds <= saturdayEndTime)
                pickupOptions.push(this.workingHours[i]);

        }

        this.desiredPickupTime = pickupOptions;
        this.desiredpickupdate = selectedDate;

        if(this.desiredpickupdate){
            this.handleWeekChange(event)
        }

    }

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
        console.log('desired pickup date-->',this.desiredpickupdate);
        if(this.desiredpickupdate){
            let pickupdate = new Date(this.desiredpickupdate.setHours(23,59,50,0));//+" 23:59:50");
            console.log('pickup date-->',this.pickupdate);
            let todayDate = new Date(new Date().setHours(0, 0, 0, 0));
            if(pickupdate < todayDate){
                pickDateerror.innerHTML ="Pickup Date can not be in the past";
                //returnDate.value ="";
                this.returneddate = "";
                return;
            }else{
                pickDateerror.innerHTML ="";
            }

            this.borrowing = data.value;
            if(this.borrowing){
                let borrow = this.borrowing.replace("weeks", "");
                borrow = this.borrowing.replace("week", "");
                let week = parseInt(borrow);
                week = (week*7);
                pickupdate.setDate(pickupdate.getDate() + week);
                pickupdate = pickupdate.toLocaleString("en-US", {timeZone: this.timeZone});
                pickupdate = new Date(pickupdate);
                let ye = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(pickupdate);
                let mo = new Intl.DateTimeFormat('en', { month: '2-digit' }).format(pickupdate);
                let da = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(pickupdate);
                const tagId = event.target.dataset.id;
                if(tagId !== "returnDate"){
                    this.returneddate = `${ye}-${mo}-${da}`;
                    returnerror.innerHTML = "";
                    const childComponent = this.template.querySelector('c-datepicker[data-id="returnDate"]');
                    if (childComponent) {
                        childComponent.handleFromParent(pickupdate);
                    }
                }else {
                    let retvalue = new Date(`${ye}-${mo}-${da}`);
                    if(retvalue){
                        retvalue = new Date(retvalue.setHours(0,0,0,0));
                        let selectedValue = event.detail.selectedDate;
                        this.returneddate = selectedValue;
                        const diff = (new Date(retvalue)- new Date(selectedValue))/(1000*60*60*24)
                        if((retvalue < selectedValue) || diff >= 7){
                            returnerror.innerHTML = "Return date is not aligned with Pickup date and borrowing week, please fix the dates";
                        }else{
                            returnerror.innerHTML = "";
                        }
                    }
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
        
        
        if(!this.returneddate){
            returnerror.innerHTML =errormsg;
            //returnDate.focus();
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

        if(!this.desiredpickupdate){
            pickDateerror.innerHTML =errormsg;
            //pickupDate.focus()
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
            && this.desiredpickupdate
            && pickupTime.value 
            && this.returneddate
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
              
            let ye = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(this.desiredpickupdate);
            let mo = new Intl.DateTimeFormat('en', { month: '2-digit' }).format(this.desiredpickupdate);
            let da = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(this.desiredpickupdate);
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
                        pickdate:`${ye}-${mo}-${da}`,
                        pickTime:pickupTime.value,
                        retDate:this.returneddate,
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