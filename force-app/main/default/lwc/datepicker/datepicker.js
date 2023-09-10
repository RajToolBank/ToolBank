import { LightningElement, api, track  } from 'lwc';

export default class Datepicker extends LightningElement {
    @track currentMonth;
    @track calendarDays;
    @track showCalendar;
    @track selectedDate='';
    @api businessHours;
    monthNumbs = {
                    "January":"1", 
                    "February":"2", 
                    "March":"3", 
                    "April":"4", 
                    "May":"5", 
                    "June":"6", 
                    "July":"7", 
                    "August":"8", 
                    "September":"9", 
                    "October":"10", 
                    "November":"11", 
                    "December":"12"
                };

    connectedCallback() {
        this.initializeDatepicker(this.businessHours);
        this.showCalendar = false;
    }

    initializeDatepicker(businessDays) {
        const currentDate = new Date();
        this.currentMonth = this.formatMonth(currentDate);
        if(businessDays)
            this.calendarDays = this.generateCalendarDays(currentDate,businessDays);
    }

    formatMonth(date) {
        const monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        const monthIndex = date.getMonth();
        const year = date.getFullYear();
        return `${monthNames[monthIndex]} ${year}`;
    }

    formatDate(date) {
        const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        const monthIndex = date.getMonth();
        const year = date.getFullYear();
        let day= date.getDate();
        return `${monthNames[monthIndex]} ${day}, ${year}`;
    }

    convertTimezone(dateTimeValue, targetTimezone) {
        const options = { timeZone: targetTimezone };
        const formattedDateTime = new Date(dateTimeValue).toLocaleString(DateTimeFormat, options);
        return formattedDateTime;
    }

    generateCalendarDays(date,businessDays) {
        const year = date.getFullYear();
        const month = date.getMonth();
        const firstDay = new Date(year, month, 1);
        const lastDay = new Date(year, month + 1, 0);
        const daysInMonth = lastDay.getDate();
        const firstDayOfWeek = firstDay.getDay(); // Calculate first day of the week
        businessDays = JSON.parse(JSON.stringify(businessDays));
        const saturdayStartTime = businessDays.Saturday_Start_Time__c;
        const sundayStartTime = businessDays.Sunday_Start_Time__c;
        const mondayStartTime = businessDays.Monday_Start_Time__c;
        const tuesdayStartTime = businessDays.Tuesday_Start_Time__c;
        const wednesdayStartTime = businessDays.Wednesday_End_Time__c;
        const thursdayStartTime = businessDays.Thursday_Start_Time__c;
        const fridayStartTime = businessDays.Friday_End_Time__c;
        let nonWorkingDays = [];
        if(!sundayStartTime)
            nonWorkingDays.push(0);
        if(!mondayStartTime)
            nonWorkingDays.push(1);
        if(!tuesdayStartTime)
            nonWorkingDays.push(2);
        if(!wednesdayStartTime)
            nonWorkingDays.push(3);
        if(!thursdayStartTime)
            nonWorkingDays.push(4);
        if(!fridayStartTime)
            nonWorkingDays.push(5);
        if(!saturdayStartTime)
            nonWorkingDays.push(6);
        const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        const calendarDays = [];

        // Add weekday row
        for (let i = 0; i < weekDays.length; i++) {
            calendarDays.push({
            number: weekDays[i],
            className: 'weekday',
            date: null
            });
        }

        // Calculate the number of cells needed to display weekdays and days
        const totalCells = Math.ceil((daysInMonth + firstDayOfWeek + 1) / 7) * 7;

        // Add days from previous month to fill the grid
        const prevMonthLastDay = new Date(year, month, 0).getDate();
        for (let i = firstDayOfWeek - 1; i >= 0; i--) {
            const prevMonthDate = new Date(year, month - 1, prevMonthLastDay - i);
            calendarDays.push({
            number: prevMonthDate.getDate(),
            className: 'disabled',
            date: prevMonthDate
            });
        }

        // Add days of the current month
        for (let i = 1; i <= daysInMonth; i++) {
            const currentDate = new Date(year, month, i);
            const dayOfWeek = currentDate.getDay();
            const isWeekend = (nonWorkingDays.indexOf(dayOfWeek)>=0) || (currentDate < new Date(new Date().getFullYear(),new Date().getMonth(),new Date().getDate()));

            calendarDays.push({
            number: i,
            className: isWeekend ? 'disabled' : '',
            date: currentDate
            });
        }

        // Add days from next month to fill the grid
        for (let i = 1; calendarDays.length < totalCells; i++) {
            const nextMonthDate = new Date(year, month + 1, i);
            calendarDays.push({
            number: nextMonthDate.getDate(),
            className: 'disabled',
            date: nextMonthDate
            });
        }

        return calendarDays;
    }

    goToPrevMonth() {
        console.log("month numb", this.monthNumbs[this.currentMonth.split(" ")[0]]);
        const currentMonthDate = new Date(this.currentMonth.split(" ")[1]+"/"+this.monthNumbs[this.currentMonth.split(" ")[0]]+"/01");
        const prevMonthDate = new Date(currentMonthDate.getFullYear(), currentMonthDate.getMonth() - 1, 1);
        this.currentMonth = this.formatMonth(prevMonthDate);
        this.calendarDays = []; // Clear the existing calendar days
        setTimeout(() => {
            this.calendarDays = this.generateCalendarDays(prevMonthDate,this.businessHours);
        }, 0);
    }

    goToNextMonth() {
        const currentMonthDate = new Date(this.currentMonth.split(" ")[1]+"/"+this.monthNumbs[this.currentMonth.split(" ")[0]]+"/01");
        const nextMonthDate = new Date(currentMonthDate.getFullYear(), currentMonthDate.getMonth() + 1, 1);
        this.currentMonth = this.formatMonth(nextMonthDate);
        this.calendarDays = []; // Clear the existing calendar days
        setTimeout(() => {
            this.calendarDays = this.generateCalendarDays(nextMonthDate,this.businessHours);
        }, 0);
    }

    handleDateClick(event) {
    
        const target = event.target;
        const isDisabled = target.classList.contains('disabled');

        if (!isDisabled) {
            this.selectedDate = this.formatDate(new Date(target.dataset.date));
            this.showCalendar = false;
            const selectEvent = new CustomEvent('dateselect', {
                detail: { 
                    selectedDate:new Date(target.dataset.date)
                }
            });
            this.dispatchEvent(selectEvent);
            this.removeEventListener('click', this.handleDateClick);
        }
    }

    handleInputClick() {
        this.showCalendar = !this.showCalendar;
    }

    @api
    handleFromParent(date){
        this.selectedDate = this.formatDate(date);
    }
}