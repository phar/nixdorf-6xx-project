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
// #include <SoftSPI.h>

// void term_write_lowlevel(uint8_t word_0,uint8_t word_1);
uint8_t term_write_lowlevel(uint8_t word_0);

void terminal_print(uint8_t terminal_id, char * str);
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

uint8_t swapBitOrder(uint8_t byte) {
    uint8_t result = 0;
    int i;

    for (i = 0; i < 8; i++) {
        if ((byte & (1 << i)) != 0) {
            result |= (1 << (7 - i));
        }
    }

    return result;
}

// SoftSPI mySPI(MISO_PIN,MOSI_PIN,SCK_PIN);
#define mySPI SPI

void setup() {

  Serial.begin(9600);
  mySPI.begin();

  // mySPI.beginTransaction(SPISettings(BIT_SPEED, LSBFIRST, SPI_MODE2));
  mySPI.begin();
  // mySPI.setClockDivider(SPI_CLOCK_DIV64); //slow things down if needed
  mySPI.setClockDivider(SPI_CLOCK_DIV128); //slow things down if needed
  mySPI.setBitOrder(LSBFIRST);
  mySPI.setDataMode(SPI_MODE2);
  pinMode(RTS_PIN,OUTPUT);
  pinMode(CTS_PIN, INPUT_PULLUP);
}

// #define STATE_FLAG_0 0x01
// #define STATE_FLAG_1 0x02 
// #define STATE_FLAG_2 0x04   //targets UF7A

#define STATE_FLAG_0 0x80
#define STATE_FLAG_1 0x40 
#define STATE_FLAG_2 0x20   //targets UF7A


#define TERMINAL_ID 0x0a 

int goflag = false;

void loop() {
int t;
unsigned long s;
int f = 0;
uint8_t word_0 = 0;
uint8_t word_1 = 0;

  if(Serial.available()){
    switch(Serial.read()){    
     case 'E': 
/*
when rts goes low, the codeword is locked in, when it goes high the byte is latched
// */
//             for(int i=0;i<0xff;i++){ 
//               if(isprint(swapBitOrder(i))){
//                  term_write_lowlevel(TERMINAL_ID<<3|STATE_FLAG_1);   //terminal attention
//                   term_clock_rts();
//                   delay(3);
//                   term_write_lowlevel(swapBitOrder(i));
//                   term_clock_rts();
//                   delay(3); 
//               }
//              }     

            delay(100);
            for(int i=0;i<0xff;i++){ 
              if(isprint(i)){
                 term_write_lowlevel(TERMINAL_ID|STATE_FLAG_1);   //terminal attention
                  delay(3);
                  term_write_lowlevel(i);
                  term_clock_rts();
                   delay(3); 
              }
             }             
            delay(100);

          //   for(int i=0;i<0xff;i++){ 
          //     if(isprint(swapBitOrder(i))){
          //        term_write_lowlevel(TERMINAL_ID<<3|STATE_FLAG_1);   //terminal attention
          //         term_begin_transfer();
          //         delay(3);
          //         term_write_lowlevel(swapBitOrder(i));
          //          delay(1); 
          //         term_end_transfer();
          //          delay(2); 
  
          //       }
          //    }             


          //  term_write_lowlevel(TERMINAL_ID<<3|STATE_FLAG_1);   //terminal attention
          //   delay(3);
          //   for(int i=0;i<0xff;i++){ 
          //     if(isprint(swapBitOrder(i))){
          //         term_begin_transfer();
          //         term_write_lowlevel(swapBitOrder(i));
          //          term_end_transfer();
          //          delay(1);   
          //       }
          //    }      
            delay(100);
        case 'F':
          terminal_print(TERMINAL_ID, "hello world!\n");

            delay(100);
            for(int i=0;i<0xff;i++){ 
              if(isprint(i)){
                 term_write_lowlevel(TERMINAL_ID|STATE_FLAG_1);   //terminal attention
                  delay(2);
                  term_write_lowlevel(i);
                  term_clock_rts();
                   delay(4); 
              }
             }  
            terminal_print(TERMINAL_ID,"\n");            
            delay(100);
            for(int i=0;i<0xff;i++){ 
              if(isprint(i)){
                 term_write_lowlevel(TERMINAL_ID|STATE_FLAG_1);   //terminal attention
                  delay(1);
                  term_write_lowlevel(i);
                  term_clock_rts();
                   delay(5); 
              }
             }  
      }
    }

  }




void term_clock_rts(){

    digitalWrite(RTS_PIN, LOW); //logic positive logic verified.. idle state of the line is high
    delayMicroseconds(5);
    digitalWrite(RTS_PIN, HIGH);
}

void term_begin_transfer(){
    digitalWrite(RTS_PIN, LOW);
}

void term_end_transfer(){
    digitalWrite(RTS_PIN, HIGH);
}


void term_sync_bitcounter(){
    mySPI.transfer(0xff);
    mySPI.transfer(0xff);
}


void terminal_println(uint8_t terminal_id, char * instr){
  terminal_print(terminal_id, instr);
  terminal_print(terminal_id, "\n");
}

void terminal_print(uint8_t terminal_id, char * instr){
int e;

  for(e=0;instr[e]!=0;e++){
    term_write_lowlevel(terminal_id|STATE_FLAG_1);   //terminal attention
    delay(1);
    term_write_lowlevel(instr[e]);
    term_clock_rts();
    delay(5);     
  }
}


uint8_t terminal_attention(uint8_t terminal_id){
  int i;


  if(digitalRead(CTS_PIN)) //rts is already high hack in case its needed
    return true;

  term_write_lowlevel((TERMINAL_ID<<3));   //terminal attention
  for(i=0;i<100;i++){
    delay(2);
    if(digitalRead(CTS_PIN)){
      return true;
    }
  }  
  return false;
}

uint8_t term_write_lowlevel(uint8_t word_0){

  // return  mySPI.transfer16((0xfe<<8) | word_0); //9 bit transfer hack seems to work ith the cards state machine without consequence
  return  mySPI.transfer16( (word_0 << 8) | 0x7f); //9 bit transfer hack seems to work ith the cards state machine without consequence
  delay(4);  //will need tightening
}


uint16_t term_read_lowlevel(uint8_t termid, uint8_t cmd){


}