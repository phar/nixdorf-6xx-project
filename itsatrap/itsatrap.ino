/*

//Arduino Mega SPI pins: 50 (MISO), 51 (MOSI), 52 (SCK), 53 (SS).

we'll need to get the polioarity right, so i havnt labeled them on the term side
  // SPI_MODE0: Clock idle low (CPOL = 0), data sampled on leading edge (CPHA = 0)
  // SPI_MODE1: Clock idle low (CPOL = 0), data sampled on trailing edge (CPHA = 1)
  // SPI_MODE2: Clock idle high (CPOL = 1), data sampled on leading edge (CPHA = 0)
  // SPI_MODE3: Clock idle high (CPOL = 1), data sampled on trailing edge (CPHA = 1)
  

RTS:  pin 7
CTS: pin 6
TERMSEL: pin 8

MOSI: pin 52
MISO: pin 50
SCK:  pin 53

                   |------------------------------------------>D 
__________         |         ___________                         TX                          
      MOSI|-o>-----+------o-|1  ('04)  2|-o------------------->H 
         7|-o>----+-------o-|3         4|-o------------------->N 
          |-      |                                              RTS    TERMINAL
          |-      |------------------------------------------->R         
          |-               
       SCK|-------+-------o-|5         7|-o------------------->J
          |-      |                                             Clk
          |-      +------------------------------------------->P
          |-               
         8|-o<------------------------------------------------<N TERMSEL              
         6|-o<------------------------------------------------<B CTS              
      MISO|-o<------------------------------------------------< RX              



 */

#include <SPI.h>



const int CTS_PIN = 6;
const int RTS_PIN = 7;
const int TERM_PIN = 8;
#define BIT_SPEED 25000


void setup() {

  Serial.begin(9600);
  SPI.begin();

  SPI.beginTransaction(SPISettings(BIT_SPEED, MSBFIRST, SPI_MODE2));
  pinMode(RTS_PIN,OUTPUT);

}

#define STATE_FLAG_0
#define STATE_FLAG_1
#define STATE_FLAG_2
#define TERMINAL_ID 0b10101

void loop() {
int t;
unsigned long s;
int f = 0;
uint8_t word_0;
uint8_t word_1;

  //ooook, heres my current best guess for protocol
    SPI.transfer(0);
    SPI.transfer(0);              // i think this should clear the state machine if anything is wack

  //fixme confirm enddianess 
    word_0 = 0x80;                  // i dont think this matters for the first byte
    word_1 |= (TERMINAL_ID) << 3;    //set the terminal ID
    word_1 |= 0x04;                //request to send command

  //read the state of CTS pin
    s = digitalRead(TERM_PIN);
    t = millis();

    digitalWrite(RTS_PIN, LOW);
    SPI.transfer(word_0);
    SPI.transfer(word_1);

    while (millis() - s < 500){ //see if the CTS pin changes states
      if (digitalRead(TERM_PIN) != s){
        f+=1;
      }
    }

    if(f>0){
      Serial.println("the terminal seems to be responding!");
    }
    digitalWrite(RTS_PIN, HIGH);


    delay(1000);
  }



