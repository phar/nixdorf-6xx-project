/*

//Arduino Mega SPI pins: 50 (MISO), 51 (MOSI), 52 (SCK), 53 (SS).


  // SPI_MODE0: Clock idle low (CPOL = 0), data sampled on leading edge (CPHA = 0)
  // SPI_MODE1: Clock idle low (CPOL = 0), data sampled on trailing edge (CPHA = 1)
  // SPI_MODE2: Clock idle high (CPOL = 1), data sampled on leading edge (CPHA = 0)
  // SPI_MODE3: Clock idle high (CPOL = 1), data sampled on trailing edge (CPHA = 1)
  

RTS:  pin 7
CTS: pin 6

MOSI: pin 51
MISO: pin 50
SCK:  pin 52


(differential pairs may need to be swapped, these are unconfirmed), we can tune 
params through SPI modes as well

                    /----------------------------------------->D 
__________         |         ___________                         TX                          
      MOSI|-o>-----+----->o-|1  ('04)  2|-o>------------------>H 
          |                 |           |      
M        7|-o>----+------>o-|3         4|-o>------------------>R 
E         |-      |         |           |                       RTS    TERMINAL
G         |-       \------------------------------------------>N         
A         |-                |           |
2      SCK|-o>----+------>o-|5         7|-o>------------------>P
5         |-      |          -----------                        CLK
6         |-       \------------------------------------------>J
0         |-                          
         6|-o<------------------------------------------------<C CTS (positive logic pin only)              
      MISO|-o<------------------------------------------------<B RX  (positive logic pin only)          


just a thought, that might be wrong, but you may need to connect the arduino
to the terminal before powering on the terminal because the bitcounter
is connected directly to the clock lines, and powering or connecting 
or toggling some weird pins state may increment the bit counter and
im not sure theres any way to recover (without some trickery we dont know
about the protocol state machine yet, it might work similar to JTAG)
)

 */

#include <SPI.h>

void term_write_lowlevel(uint8_t word_0,uint8_t word_1);

const int CTS_PIN = 6;
const int RTS_PIN = 7;
#define BIT_SPEED 2000


void setup() {

  Serial.begin(9600);
  SPI.begin();

  //shift protocol does appear to be MSB first we can assume mode2 with sampling on the negative going edge

  SPI.beginTransaction(SPISettings(BIT_SPEED, MSBFIRST, SPI_MODE2));
  pinMode(RTS_PIN,OUTPUT);

}

#define STATE_FLAG_0 0x01
#define STATE_FLAG_1 0x02  
#define STATE_FLAG_2 0x04  //targets UF7A

#define TERMINAL_ID 0b10101 // 21

int goflag = false;

void loop() {
int t;
unsigned long s;
int f = 0;
uint8_t word_0 = 0;
uint8_t word_1 = 0;


    word_0 = 0x00;                  // i dont think this matters for the first byte

    word_1 |= (TERMINAL_ID) << 3;    //set the terminal ID shifted up 3 in MSB
    word_1 |= STATE_FLAG_2;                //request to send command



  if(Serial.available()){
    switch(Serial.read()){
        case '1':
          term_write_lowlevel(word_0,word_1);
          break;

        case 'G': //go command
          Serial.println("sending pattern");
          goflag = 1;
          break;

        case 'S': //stop command
          Serial.println("stopping pattern");
          goflag = 0;
          break;

    }

  }

  if(goflag){

    //ooook, heres my current best guess for protocol

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
  }





void term_write_lowlevel(uint8_t word_0,uint8_t word_1){

    digitalWrite(RTS_PIN, HIGH);
    //delay?
    SPI.transfer(word_0);
    SPI.transfer(word_1);
    //delay?
    digitalWrite(RTS_PIN, LOW);

}

uint16_t term_read_lowlevel(uint8_t termid, uint8_t cmd){


}