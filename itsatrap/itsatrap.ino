/*

//Arduino Mega SPI pins: 50 (MISO), 51 (MOSI), 52 (SCK), 53 (SS).


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

(differential pairs may need to be swapped, these are unconfirmed), we can tune 
params through SPI modes as well

                   +------------------------------------------>D 
__________         |         ___________                         TX                          
      MOSI|-o>-----+----->o-|1  ('04)  2|-o>------------------>H 
          |                 |           |      
M        7|-o>----+------>o-|3         4|-o>------------------>N 
E         |-      |         |           |                       RTS    TERMINAL
G         |-      |------------------------------------------->R         
A         |-                |           |
2      SCK|-o>----+------>o-|5         7|-o>------------------>J
5         |-      |          -----------                        CLK
6         |-      +------------------------------------------->P
0         |-               
         8|-o<------------------------------------------------<N TERMSEL              
         6|-o<------------------------------------------------<B CTS              
      MISO|-o<------------------------------------------------<B RX              



 */

#include <SPI.h>



const int CTS_PIN = 6;
const int RTS_PIN = 7;
#define BIT_SPEED 25000


void setup() {

  Serial.begin(9600);
  SPI.begin();

  //shift protocol does appear to be MSB first

  SPI.beginTransaction(SPISettings(BIT_SPEED, MSBFIRST, SPI_MODE2));
  pinMode(RTS_PIN,OUTPUT);

}

#define STATE_FLAG_0 0x01
#define STATE_FLAG_1 0x02  
#define STATE_FLAG_2 0x04  //targets UF7A

#define TERMINAL_ID 0b10101 // 21

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
    word_1 |= (TERMINAL_ID) << 3;    //set the terminal ID shifted up 3 in MSB
    word_1 |= STATE_FLAG_2;                //request to send command

  //read the state of CTS pin
    s = digitalRead(CTS_PIN);
    t = millis();

    digitalWrite(RTS_PIN, LOW);
    SPI.transfer(word_0);
    SPI.transfer(word_1);

    while (millis() - s < 500){ //see if the CTS pin changes states
      if (digitalRead(CTS_PIN) != s){
        f+=1;
      }
    }

    if(f>0){
      Serial.println("the terminal seems to be responding!");
    }
    digitalWrite(RTS_PIN, HIGH);

    delay(1000);
  }



