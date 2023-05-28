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
#include <SoftSPI.h>

// void term_write_lowlevel(uint8_t word_0,uint8_t word_1);
void term_write_lowlevel(uint8_t word_0);

void term_begin_transfer();
void term_end_transfer();
void term_sync_bitcounter();


const int MOSI_PIN = 2; 
const int MISO_PIN = 5; 
const int SCK_PIN = 4;
const int CTS_PIN = 6;
const int RTS_PIN = 7;
const int CLOCK_PIN = 4;
const int BIT_SPEED = 2000;



#define BIT_SPEED 2000

SoftSPI mySPI(MISO_PIN,MOSI_PIN,SCK_PIN);
void setup() {

  Serial.begin(9600);
  mySPI.begin();

  // mySPI.beginTransaction(SPISettings(BIT_SPEED, MSBFIRST, SPI_MODE2));
  mySPI.begin();
  mySPI.setClockDivider(SPI_CLOCK_DIV64); //slow things down if needed

  pinMode(RTS_PIN,OUTPUT);
  pinMode(CTS_PIN, INPUT_PULLUP);
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


    word_0 = 0x80;                  // i dont think this matters for the first byte

    word_1 |= (TERMINAL_ID) << 3;    //set the terminal ID shifted up 3 in MSB
    word_1 |= STATE_FLAG_2;                //request to send command

  if(Serial.available()){
    switch(Serial.read()){
        case '1':
          Serial.println("one shot");
            term_begin_transfer();
            term_sync_bitcounter();
             delay(10);
            term_write_lowlevel(word_0);
            term_end_transfer();
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

      term_begin_transfer();
      term_sync_bitcounter();
      delay(10);
      term_write_lowlevel(word_0);
      term_end_transfer();

      delay(1000);
    }
  }






void term_begin_transfer(){
    digitalWrite(RTS_PIN, HIGH);
}

void term_end_transfer(){
    digitalWrite(RTS_PIN, LOW);
}


void term_sync_bitcounter(){
    term_write_lowlevel(0xff);
    term_write_lowlevel(0xfe;
}

// void term_write_lowlevel(uint8_t word_0,uint8_t word_1){
//   mySPI.transfer(word_0);
//   mySPI.transfer(word_1);
// }

void term_write_lowlevel(uint8_t word_0){
  mySPI.transfer(word_0);
}


uint16_t term_read_lowlevel(uint8_t termid, uint8_t cmd){


}