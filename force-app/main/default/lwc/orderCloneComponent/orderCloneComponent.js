import { LightningElement, wire, track, api } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ORDER_OBJECT from '@salesforce/schema/Order';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import cloneOrder from '@salesforce/apex/OrderCloneController.cloneOrder';
import getBusinessHours from '@salesforce/apex/OrderCloneController.getBusinessHours';
import PICKUP_TIME from '@salesforce/schema/Order.Desired_Pickup_Time__c';
import BORROWING_PERIOD from '@salesforce/schema/Order.Requested_Borrowing_Period__c';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

export default class OrderCloneComponent extends LightningElement {
    @api recordId;
    @api businessHours;
    orderMetadata;
    desiredpickupdate;
    desiredPickupTime;
    workingHours;
    borrowingPeriod;
    error;
    @track PickupTime;
    @track borrowing;
    @track loading = false;

   @wire(getRecord, { recordId: '$recordId', fields: ['Order.Id'] })
    wiredRecord({ error, data }) {
        if (data) {
            this.handleRecordData(data);
        } else if (error) {
            console.error('Error loading record:', error);
        }
    }

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

    handleRecordData(record) {
        console.log('Record data:', record);
        // Now you can use this.recordId and make the necessary callout or perform actions
        getBusinessHours({
            orderId: record.id
        })
        .then(res => {
            this.businessHours = res;
            console.log('businessHours-->', this.businessHours);
        })
        .catch(err => {
            console.log(err);
        });
    }

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
    }

    handlePickUpTimeChange(event) {
        this.PickupTime = event.target.value;
        console.log('pick-up Time',this.PickupTime);
    }

    handleBorrowingPeriodChange(event) {
        this.borrowing = event.target.value;
        console.log('borrowing-->',this.borrowing);
    }
    
    cloneHandler() {
        let errormsg = "This Field is Required";
        let pickDateerror = this.template.querySelector(`[data-id="pickDateerror"]`);
        let pickTimeerror = this.template.querySelector(`[data-id="pickTimeerror"]`);
        let weekerror = this.template.querySelector(`[data-id="weekerror"]`);
        
        if(!this.desiredpickupdate){
            pickDateerror.innerHTML = errormsg;
        }
        else pickDateerror.innerHTML = "";
        if(!this.borrowing){
            weekerror.innerHTML = errormsg;
        }
        else weekerror.innerHTML = "";
        if(!this.PickupTime){
            pickTimeerror.innerHTML = errormsg;
        }
        else pickTimeerror.innerHTML = "";

        let ye = new Intl.DateTimeFormat('en', { year: 'numeric' }).format(this.desiredpickupdate);
        let mo = new Intl.DateTimeFormat('en', { month: '2-digit' }).format(this.desiredpickupdate);
        let da = new Intl.DateTimeFormat('en', { day: '2-digit' }).format(this.desiredpickupdate);
        var url = location.href;  // entire url including querystring - also: window.location.href;
        var baseURL = '';
        if(url.includes('s/detail/')) {
            baseURL = url.split('s/detail/')[0]+'s/detail/';
        } else if(url.includes('force.com/')) {
            baseURL = url.split('force.com/')[0]+'force.com/';
        }
        if (this.recordId
            && this.desiredpickupdate
            && this.PickupTime 
            && this.borrowing) {
            // Show spinner before making the Apex call
            this.loading = true;
            cloneOrder({ originalOrderId: this.recordId, pickUpDate: `${ye}-${mo}-${da}`, pickUpTime: this.PickupTime, borrowingPeriod: this.borrowing})
            .then(result => {
                // Handle the result from the Apex method
                console.log('redirect uurl-->',baseURL+result);
                window.location.replace(baseURL+result);
                // Hide spinner after Apex call completes
                this.loading = false;
            })
            .catch(error => {
                // Hide spinner after Apex call completes
                this.loading = false;
                // Handle any errors
                console.error(error);
                this.error = error.body.message;
            });
        }
    }
}