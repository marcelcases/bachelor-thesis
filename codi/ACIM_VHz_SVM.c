 /**********************************************************************
 *                                                                     *
 *                        Software License Agreement                   *
 *                                                                     *
 *    The software supplied herewith by Microchip Technology           *
 *    Incorporated (the "Company") for its dsPIC controller            *
 *    is intended and supplied to you, the Company's customer,         *
 *    for use solely and exclusively on Microchip dsPIC                *
 *    products. The software is owned by the Company and/or its        *
 *    supplier, and is protected under applicable copyright laws. All  *
 *    rights are reserved. Any use in violation of the foregoing       *
 *    restrictions may subject the user to criminal sanctions under    *
 *    applicable laws, as well as to civil liability for the breach of *
 *    the terms and conditions of this license.                        *
 *                                                                     *
 *    THIS SOFTWARE IS PROVIDED IN AN "AS IS" CONDITION.  NO           *
 *    WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, INCLUDING,    *
 *    BUT NOT LIMITED TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND    *
 *    FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS SOFTWARE. THE     *
 *    COMPANY SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL,  *
 *    INCIDENTAL OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.  *
 *                                                                     *
  **********************************************************************/

 /**********************************************************************
 *                                                                     * 
 *    Author: Steve Bowling                                            * 
 *                                                                     *
 *    Filename:       acim_vhz_svm.c	                               *
 *    Date:           11/01/2006                                       *
 *    File Version:   2.00                                             *
 *                                                                     *
 *    Tools used: MPLAB GL  -> 7.43                                    *
 *                Compiler  -> 2.03                                    *
 *                                                                     *
 *    Linker File:    p30f6010a.gld                                     *
 *                                                                     *
 *                                                                     *
 ***********************************************************************
 *	Code Description
 *  
 *  This file demonstrates simple open loop control of an ACIM
 *  motor using the Microchip motor control demo hardware.  
 *
 *
 *  Revision History
 *  
 *  Ver 1.10
 *  Inline assembly modified to be compatible with version 1.20 of
 *  the C30 compiler.
 *
 **********************************************************************/

#include <p30F6010a.h>

/*********************** START OF DEFINITIONS *******************/


// These are the pushbutton pin connections for the motor control PCB.
#define	BUTTON1	!PORTGbits.RG6
#define	BUTTON2	!PORTGbits.RG7
#define	BUTTON3	!PORTGbits.RG8
#define	BUTTON4	!PORTGbits.RG9

// This is the control line for the driver IC on the
// motor control PCB.  It must be low to activate
// the PWM drive signals to the power module.
#define	PWM_OUTPUT_ENABLE	PORTDbits.RD11	

// PFC switch firing line
#define	PFC_FIRE	PORTDbits.RD5

// BRAKE circuit firing line
#define BRAKE_FIRE	PORTDbits.RD4

// This is the fault reset line for the motor power module.
// The dsPIC must generate an active high pulse to clear any
// of the red fault LEDs on the power module.
#define FAULT_RESET	PORTEbits.RE9

// This is the fault input line from the power module.  This
// line is connected to the PWM Fault A input pin (RE8).
#define	FAULT_INPUT	PORTEbits.RE8

// This is the interrupt flag for the PWM Fault A input.  It is
// renamed for convenience.
#define	FLTA_FLAG	IFS2bits.FLTAIF

// These are the LEDs
#define		LED4	PORTAbits.RA15
#define		LED3	PORTAbits.RA14
#define		LED2	PORTAbits.RA10
#define		LED1	PORTAbits.RA9

// These are the counting periods for the medium and slow speed events.
// Count variables are decremented at each PWM interrupt.

#define	SLOW_EVENT_PERIOD	1600		// 100msec period for 16KHz PWM
#define	MEDIUM_EVENT_PERIOD	72			// 5msec period for 16KHz PWM

//---------------------------------------------------------------------
// These are the definitions for various angles used in the SVM 
// routine.  A 16-bit unsigned value is used as the angle variable.
// The SVM algorithm determines the 60 degree sector
#define	VECTOR1	0				// 0 degrees
#define	VECTOR2	0x2aaa			// 60 degrees
#define	VECTOR3	0x5555			// 120 degrees
#define	VECTOR4	0x8000			// 180 degrees
#define	VECTOR5	0xaaaa			// 240 degrees
#define	VECTOR6	0xd555			// 300 degrees
#define	SIXTY_DEG	0x2aaa

//---------------------------------------------------------------------
// These are constant definitions used in the VHz routine.

#define FREQ_LIMIT		800

//  These constants define the slope of the Volts-Hertz profile
// and the lower and upper modulation index shelves.
#define V_HZ_SLOPE				100
#define	LOW_AMPLITUDE_LIMIT		5000
#define	HIGH_AMPLITUDE_LIMIT	30000
#define AMPLITUDE_POT_LIMIT		HIGH_AMPLITUDE_LIMIT/V_HZ_SLOPE

//---------------------------------------------------------------------

// This bit structure provides status flags for the software
struct {
		unsigned 	TestMode:1;
        unsigned   	Reverse:1;
        unsigned   	Button1:1;
        unsigned   	Button2:1;
        unsigned   	Button3:1;
        unsigned   	Button4:1;
        unsigned    DirChange:1;
        unsigned    Accelerate:1;
        unsigned  	PWMFault:1;
        unsigned  	Restart:1;
        unsigned  	:1;
        unsigned    :1;
        unsigned   	:1;
        unsigned   	PWMEvent:1;
        unsigned   	MediumEvent:1;
        unsigned    SlowEvent:1;

} Flags;

// This is a software counter used to time slower system events, such as
// button polling, etc.
unsigned int SlowEventCount, MediumEventCount;

// This variable is used as a software counter to turn the voltage boost
// circuit switch on and off.
unsigned int BoostCount;

// This variable holds the A/D 
unsigned int Speed, OldSpeed;

// Phase and Amplitude are the two input variables to the SVM
// function.  
unsigned int Amplitude, Phase;			
unsigned int t0,t1,t2,h_t0;				// Space vector time variables

// This sinewave lookup table has 171 entries.  (1024 points per
// electrical cycle -- 1024*(60/360) = 171)
// The table covers 60 degrees of the sine function and is stored
// in program memory space.  The values are accessed via PSV.

const unsigned int sinetable[] = {0,201,401,602,803,1003,1204,1404,1605,1805,
2005,2206,2406,2606,2806,3006,3205,3405,3605,3804,4003,4202,4401,4600,
4799,4997,5195,5393,5591,5789,5986,6183,6380,6577,6773,6970,7166,7361,
7557,7752,7947,8141,8335,8529,8723,8916,9109,9302,9494,9686,9877,10068,
10259,10449,10639,10829,11018,11207,11395,11583,11771,11958,12144,
12331,12516,12701,12886,13070,13254,13437,13620,13802,13984,14165,
14346,14526,14706,14885,15063,15241,15419,15595,15772,15947,16122,
16297,16470,16643,16816,16988,17159,17330,17500,17669,17838,18006,
18173,18340,18506,18671,18835,18999,19162,19325,19487,19647,19808,
19967,20126,20284,20441,20598,20753,20908,21062,21216,21368,21520,
21671,21821,21970,22119,22266,22413,22559,22704,22848,22992,23134,
23276,23417,23557,23696,23834,23971,24107,24243,24377,24511,24644,
24776,24906,25036,25165,25293,25420,25547,25672,25796,25919,26042,
26163,26283,26403,26521,26638,26755,26870,26984,27098,27210,27321,
27431,27541,27649,27756,27862,27967,28071,28174,28276,28377};

//----------------------------------------------------------------------

void Setup(void);		// Initializes dsPIC and peripherals
int ReadADC(unsigned int channel);
void __attribute__((__interrupt__)) _PWMInterrupt(void);
void Delay(unsigned int count);
// Space vector modulation routine
void SVM(void);
// Called by SVM() to calculate SVM times					
void CalcTimes(unsigned int vector);

//---------------------------------------------------------------------

main ( void )
{
Setup();

while(1)
	{
	ClrWdt();		// Clear the watchdog timer
	
	// This code is executed after each PWM interrupt occurs.
	// The PWM ISR sets PWMflag to signal the interrupt.
	if(Flags.PWMEvent)
		{
		// The Speed variable is added or subtracted from the Phase
		// variable to control the modulation frequency.
		if(Flags.Reverse) 	Phase -= Speed;
		else				Phase += Speed;
		
		// Write the duty cycles to the PWM module by calling the SVM
		// routine.
		SVM();
				
		Flags.PWMEvent = 0;		
		}		// end if(PWMEvent)
	
	//-----------------------------------------------------------------
	// Medium speed event handler executes every 5msec
	//-----------------------------------------------------------------
	
	if(Flags.MediumEvent)
		{
		// This is the main loop code that responds to a fault event
		// signalled by the fault ISR.  Here, we just turn on a status
		// LED to let the user know that the fault occurred.
		// The fault condition is reset when Button 1 is pressed.
		if(Flags.PWMFault)
			{
			LED1 = 1;
			
			}
		
		// If no direction change or restart is happening,
		// the motion profile is not executing, so just read the pot values
		// to get the speed setting.
		if(!Flags.DirChange && !Flags.Restart)
			{
			// Get the speed setting from the potentiometer
			Speed = ReadADC(7);
			// Limit the frequency range.
			if(Speed > FREQ_LIMIT) Speed = FREQ_LIMIT;
			
			// In test mode, the modulation amplitude is determined by the voltage
			// on AN12.
			if(Flags.TestMode)
				{ 
				Amplitude = ReadADC(12) << 5;
				if(Amplitude > HIGH_AMPLITUDE_LIMIT)
					Amplitude = HIGH_AMPLITUDE_LIMIT;
				}
			
			// Otherwise, calculate the amplitude setting based on the 
			// V/Hz Constant
			else
				{
				if(Speed > AMPLITUDE_POT_LIMIT) 
					Amplitude = HIGH_AMPLITUDE_LIMIT;
				else
					Amplitude = Speed*V_HZ_SLOPE;
				if(Amplitude < LOW_AMPLITUDE_LIMIT)
					Amplitude = LOW_AMPLITUDE_LIMIT;
				}
			}
					
		// This is the 'motion profile'.  If a direction change is
		// requested, this code will ramp down the speed setting, 
		// reverse the motor, then slowly ramp it back up.
		if(Flags.DirChange)
			{
			if(Flags.Accelerate)
				{
				// If we're back to our old speed, we're done!
				// Clear the DirChange flag
				if(Speed == OldSpeed)
					{ 
					Flags.DirChange = 0;
					LED4 = 0;
					}
				// Otherwise, speed up
				else Speed++;
				}
			// Otherwise, slow down
			else Speed--;
			
			// Has the speed ramped down to 0?
			// If so, set the acceleration flag and reverse the direction.
			if(Speed == 0)
				{
				Flags.Accelerate = 1;
				Flags.Reverse = ~Flags.Reverse;
				}
			}
		
		if(Flags.Restart)
			{
			if(Speed == OldSpeed) Flags.Restart = 0;
			
			else	Speed++;
			}	
		
		Flags.MediumEvent = 0;
		}		//end if(MediumEvent)
	
	//-----------------------------------------------------------------
	// Slow event handler executes every 100msec
	//-----------------------------------------------------------------
	if(Flags.SlowEvent)
		{
		// These statements check to see if any of the buttons are pressed.
		// If so, a software flag is set so the button press can be debounced.
		if(BUTTON1)	Flags.Button1 = 1;
		if(BUTTON2)	Flags.Button2 = 1;
		if(BUTTON3)	Flags.Button3 = 1;
		if(BUTTON4)	Flags.Button4 = 1;
	
		// If button #1 is pressed, a reset signal will be sent to the
		// power module to clear any fault LEDs that are lit.
		// The fault A interrupt flag is also cleared to reactivate
		// the dsPIC MCPWM.	
	
		if(Flags.Button1)
			{
			// Wait until the button is released before doing anything.
			if(!BUTTON1)
				{
				if(Flags.PWMFault)
					{
					// Reset the speed variable.  Save the old speed for use
					// in the restart profile.
					OldSpeed = Speed;
					Speed = 0;
					// Set the duty cycles back to 50% and set a restart flag.
					PDC1 = PTPER;
					PDC2 = PTPER;
					PDC3 = PTPER;
					Flags.Restart = 1;
					// Turn the PWM output back on that was disabled in the FLTA ISR		
					OVDCON = 0x3F00;
					// Turn off the status LED
					LED1 = 0;
					// Reset the power module.
					FAULT_RESET = 1;
					Nop();
					Nop();
					Nop();
					FAULT_RESET = 0;
					// Clear the PWM fault flag
					Flags.PWMFault = 0;
					}
				// Clear the button status flag.
				Flags.Button1 = 0;	
				}
			}
		
		// Button2 turns the voltage boost on and off
		if(Flags.Button2)
			{
			LED2 = 1;
			if(!BUTTON2)
				{
				LED2 = 0;
				if(IEC0bits.T1IE)
					{
					IEC0bits.T1IE = 0;
					PFC_FIRE = 0;
					BRAKE_FIRE = 0;
					}
				else
					{
					IEC0bits.T1IE = 1;
					BRAKE_FIRE = 1;
					}
				Flags.Button2 = 0;
				}
			}
		
		// Button3 turns the debug mode on and off
		if(Flags.Button3)
			{
			if(!BUTTON3)
				{
				Flags.TestMode = !Flags.TestMode;
				if(Flags.TestMode)	LED3 = 1;
				else LED3 = 0;
				Flags.Button3 = 0;
				}
			}
		
		// Button #4 is used to set the direction of the motor.			
		if(Flags.Button4)
			{
			// Wait until the button is released before doing anything.
			// Start a direction change if one is not already in progress.
			if(!BUTTON4  && !Flags.DirChange)
				{
				LED4 = 1;
				// Set the direction change flag.
				Flags.DirChange = 1;
				// Tell the motion profile to decelerate the motor
				Flags.Accelerate = 0;
				// Save the current Speed setting
				OldSpeed = Speed;
				// Clear the button status flag
				Flags.Button4 = 0;
				}
			}
		Flags.SlowEvent = 0;
		}		// end if(SlowEvent)
   	}			// end while(1)
}				// end main

//---------------------------------------------------------------------

void Setup(void)
{
// Initialize variables
Speed = 0;
OldSpeed = 0;
SlowEventCount = SLOW_EVENT_PERIOD;
MediumEventCount = MEDIUM_EVENT_PERIOD;

// Initialize PORTs

PORTA = 0;				
PORTB = 0;				// Initialize PORTs
PORTC = 0;
PORTD = 0;
PORTE = 0;
PORTG = 0;
TRISA = 0x39FF;
TRISB = 0xFFFF;
TRISC = 0xFFFF;
TRISD = 0xF7CF;			// RD11 is output for PWM_OUTPUT_ENABLE line
						// RD5 is PFC_FIRE line
						// RD4 is BRAKE_FIRE line
TRISE = 0xFDFF;			// RE9 is output for FAULT_RESET line
TRISG = 0xFFFF;

// Initialize PWM
PTPER = 230;		// Value gives 16KHZ center aligned PWM at 7.38MIPS
PDC1 = 0;
PDC2 = 0;
PDC3 = 0;
PDC4 = 0;
PWMCON1 = 0x0077;	// Enable PWM 1,2,3 pairs for complementary mode
DTCON1 = 0x000F;	// Value provides 2us dead time at 7.38 MIPS
DTCON2 = 0;
FLTACON = 0x0007;	// Fault A enabled for latched mode on PWM1, 2, and 3
FLTBCON = 0;		// Fault B not used.
OVDCON	= 0x3F00;	// Enable PWM1H,1L, 2H, 2L, 3L, 3H for PWM
PTCON = 0x8002;		// Enable PWM for center aligned operation
IFS2bits.PWMIF = 0;	
IEC2bits.PWMIE = 1;	// Enable PWM interrupts.
IFS2bits.FLTAIF = 0;// Clear the fault A interrupt flag.
IEC2bits.FLTAIE = 1;// Enable interrupts for Fault A

// Initialize ADC

ADCON1 = 0;
ADCON2 = 0;
ADCON3 = 0;
ADPCFG = 0;
ADCHS = 0x0007;
ADCON1bits.ADON = 1;

// Reset any active faults on the motor control power module.
FAULT_RESET = 1;
// Initialize SPI1 for slave mode
SPI1CON = 0x0040;			// Slave mode, CKP = 1
SPI1STAT = 0x8000;			// Enable SPI
FAULT_RESET = 0;

// Configure Timer1, but don't enable interrupts
TMR1 = 0;
PR1 = 60;
T1CON = 0x8000;
IFS0bits.T1IF = 0;
IEC0bits.T1IE = 0;

// Enable the driver IC on the motor control PCB
PWM_OUTPUT_ENABLE = 0;
// Ensure PFC switch is off.
PFC_FIRE = 0;
// Turn brake off.
BRAKE_FIRE = 0;
// Ensure FLTA flag is cleared
FLTA_FLAG = 0;
}

//---------------------------------------------------------------------

int ReadADC(unsigned int channel)
{
int Delay;

if(channel > 0x000F) return(0);
ADCHS = channel;
ADCON1bits.SAMP = 1;
for(Delay = 0; Delay < 20; Delay++);
IFS0bits.ADIF = 0;
ADCON1bits.SAMP = 0;
while(!IFS0bits.ADIF);
return(ADCBUF0);

}

//---------------------------------------------------------------------
// The PWM ISR just sets a software flag to trigger SVM calculations
// in the main software loop.

void __attribute__((__interrupt__)) _PWMInterrupt(void)
{
SlowEventCount--;
if(SlowEventCount == 0)
	{
	Flags.SlowEvent = 1;
	SlowEventCount = SLOW_EVENT_PERIOD;
	}
MediumEventCount--;
if(MediumEventCount == 0)
	{
	Flags.MediumEvent = 1;
	MediumEventCount = MEDIUM_EVENT_PERIOD;
	}
Flags.PWMEvent = 1;
IFS2bits.PWMIF = 0;
}

//---------------------------------------------------------------------
// The FLTA ISR responds to events on the PWM fault pin.
// This ISR code just turns off all the PWM outputs via the OVDCON
// register and signals the main loop that a problem has occurred.

void __attribute__((__interrupt__)) _FLTAInterrupt(void)
{
// Keep all outputs disabled until we figure out what is going on!
OVDCON = 0;
PFC_FIRE = 0;
// Signal a fault to the main loop.
Flags.PWMFault = 1;
// Clear the FLTA interrupt flag.
IFS2bits.FLTAIF = 0;
}

//---------------------------------------------------------------------
// The Timer1 ISR is used to drive the voltage boost circuit

void __attribute__((__interrupt__)) _T1Interrupt(void)
{
if(++BoostCount > 4)
	{
	PFC_FIRE = 1;
	BoostCount = 0;
	}
else 
	PFC_FIRE = 0;
	
// Clear the Timer1 interrupt flag.
IFS0bits.T1IF = 0;
}

//---------------------------------------------------------------------
// This is a generic delay routine 

void Delay(unsigned int count)
{
unsigned int j;

for(j=0;j<count;j++);

}

//*********************************************************************
// The function SVM() determines which sector the input angle is
// located in.  The CalcTimes() function is then called to calculate
// the space vector time segments.  The SVM() function then loads the
// appropriate duty cycle values depending on the type of SVM to be
// generated.
//*********************************************************************

void SVM(void)
{

if(Phase < VECTOR2)
	{
	CalcTimes(VECTOR1);			// Calculate t0, t1, and t2.
	
	h_t0 = t0 >> 1;				// Calculate duty cycles for Sector 1
	PDC1 = t1 + t2 + h_t0;
	PDC2 = t2 + h_t0;
	PDC3 = h_t0;
	}

else if(Phase < VECTOR3)
	{
	CalcTimes(VECTOR2);			// Calculate t0, t1, and t2.
	
	h_t0 = t0 >> 1;				// Calculate duty cycles for Sector 2
	PDC1 = t1 + h_t0;
	PDC2 = t1 + t2 + h_t0;
	PDC3 = h_t0;
	}

else if(Phase < VECTOR4)
	{
	CalcTimes(VECTOR3);			// Calculate t0, t1, and t2.
	
	h_t0 = t0 >> 1;				// Calculate duty cycles for Sector 3
	PDC1 = h_t0;
	PDC2 = t1 + t2 + h_t0;
	PDC3 = t2 + h_t0;
	}

else if(Phase < VECTOR5)		
	{
	CalcTimes(VECTOR4);			// Calculate t0, t1, and t2.
	
	h_t0 = t0 >> 1;				// Calculate duty cycles for Sector 4
	PDC1 = h_t0;
	PDC2 = t1 + h_t0;
	PDC3 = t1 + t2 + h_t0;
	}

else if(Phase < VECTOR6)
	{
	CalcTimes(VECTOR5);			// Calculate t0, t1, and t2.
	
	h_t0 = t0 >> 1;				// Calculate duty cycles for Sector 5
	PDC1 = t2 + h_t0;
	PDC2 = h_t0;
	PDC3 = t1 + t2 + h_t0;
	}

else
	{
	CalcTimes(VECTOR6);			// Calculate t0, t1, and t2.
	
	h_t0 = t0 >> 1;				// Calculate duty cycles for Sector 6
	PDC1 = t1 + t2 + h_t0;
	PDC2 = h_t0;
	PDC3 = t1 + h_t0;
	}
}			// end SVM()

//*********************************************************************
// The CalcTimes() function determines the SVM segment times based on 
// the current phase angle, and modulation index.
// The phase angle is normalized to a 60 degree range.
//*********************************************************************

void CalcTimes(unsigned int vector)
{
unsigned int angle1, angle2;

angle2 = Phase - vector;        //  Reference SVM angle to the current sector
angle1 = SIXTY_DEG - angle2;	// Calculate second angle referenced to sector

angle1 >>= 6;					// Scale angles to align with LUT
angle2 >>= 6;					// if using a 16-bit phase angle.

t1 = sinetable[(unsigned char)angle1];	// Look up values from table.
t2 = sinetable[(unsigned char)angle2];

asm("   push.d  W4             ; Save W4 and W5 \n"

    "   mov     _PTPER,W4      ; get PWM timebase period \n"
    "   mov     _Amplitude,W5  ; get SVM amplitude \n"
    "   mpy     W4*W5,A        ; do the multiply \n"
    "   sac.r   A,W5           ; Store PTPER*Amplitude in W5 \n"

    "   mov     _t1,W4         ; Get t1 \n"
    "   mpy     W4*W5,A        ; Scale t1 \n"
    "   sac.r   A,W4           ; Store the accumulator result \n"
    "   mov     W4,_t1         ; Save in t1 \n"

    "   mov     _t2,W4         ; Get t2 \n"
    "   mpy     W4*W5,A        ; Scale t1 \n"
    "   sac.r   A,W4           ; Store the accumulator result \n"
    "   mov     W4,_t2         ; Save in t2 \n"

    "   pop.d   W4             ; Restore W4 and W5 \n"
);

t0 = PTPER - t1 - t2;		// Calculate t0 null time from period and t1,t2
}							


// end of file
