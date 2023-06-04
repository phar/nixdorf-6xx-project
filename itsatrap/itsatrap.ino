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

  // mySPI.beginTransaction(SPISettings(BIT_SPEED, MSBFIRST, SPI_MODE2));
  mySPI.begin();
  // mySPI.setClockDivider(SPI_CLOCK_DIV64); //slow things down if needed
  mySPI.setClockDivider(SPI_CLOCK_DIV128); //slow things down if needed
  mySPI.setBitOrder(MSBFIRST);
  mySPI.setDataMode(SPI_MODE2);
  pinMode(RTS_PIN,OUTPUT);
  pinMode(CTS_PIN, INPUT_PULLUP);
}

#define STATE_FLAG_0 0x01
#define STATE_FLAG_1 0x02 
#define STATE_FLAG_2 0x04   //targets UF7A

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
        case '1':
          Serial.println("one shot");
                                          //terminal connect to mainframe
            term_begin_transfer();        //   i think these two lines can happen in reverse order
            term_sync_bitcounter();       // sync bit counter to ensure we are word aligned


            delay(10);                     // some delay doesnt matter 


//           if(terminal_attention(TERMINAL_ID)){ // not ready yet

            term_write_lowlevel((TERMINAL_ID<<3));   //request to send

            for(int i=0;i<20;i++){
            term_write_lowlevel((TERMINAL_ID<<3));   //request to send
              term_write_lowlevel(TERMINAL_ID<<3|random(0,7));   //terminal attention
              term_write_lowlevel(0x41);                            //send "A"
              delay(20);
            }
            
    
            term_write_lowlevel(0x10);

            delay(10);                     // some delay doesnt matter 
  //         }

            term_end_transfer();          //terminal disconnect from mainframe
          break;

        case '2':
          Serial.println("two shot");
                                          //terminal connect to mainframe
            term_begin_transfer();        //   i think these two lines can happen in reverse order
            term_sync_bitcounter();       // sync bit counter to ensure we are word aligned


            delay(10);                     // some delay doesnt matter 


//           if(terminal_attention(TERMINAL_ID)){ // not ready yet


            for(int i=0;i<5;i++){
              term_write_lowlevel(TERMINAL_ID<<3|STATE_FLAG_2);   //terminal attention
              term_write_lowlevel(0x41);  
              delay(10);                          //send "A"
            }
            term_write_lowlevel(0x10);

            delay(100);                     // some delay doesnt matter 
  //         }

            term_end_transfer();          //terminal disconnect from mainframe
          break;

        case '3':
          Serial.println("three");
                                          //terminal connect to mainframe
            term_sync_bitcounter();       // sync bit counter to ensure we are word aligned


            term_begin_transfer();        //   i think these two lines can happen in reverse order
            delay(10);                     // some delay doesnt matter 
            for(int e=0;e<8;e++){
              term_write_lowlevel(TERMINAL_ID<<3|e);   //terminal attention
              for(int i=0;i<0xff;i++){
                term_write_lowlevel(i);
              }
              delay(10);
            }
            delay(10);                     // some delay doesnt matter 
           term_end_transfer();          //terminal disconnect from mainframe
            delay(100);
          break;
        
        case '4':
          Serial.println("four");
                                          //terminal connect to mainframe
            term_sync_bitcounter();       // sync bit counter to ensure we are word aligned


            for(int e=0;e<8;e++){
              term_begin_transfer();        //   i think these two lines can happen in reverse order
              delay(10);                     // some delay doesnt matter 
              term_write_lowlevel(TERMINAL_ID<<3|e);   //terminal attention
              for(int i=0;i<0xff;i++){
                term_write_lowlevel(i);
              }
              term_end_transfer();          //terminal disconnect from mainframe
              delay(10);
            }
            delay(100);
            break;

        case '5':
          Serial.println("five");
                                          //terminal connect to mainframe
            term_sync_bitcounter();       // sync bit counter to ensure we are word aligned


            for(int e=0;e<8;e++){
              delay(10);                     // some delay doesnt matter 
              for(int i=0;i<0xff;i++){
                term_begin_transfer();        //   i think these two lines can happen in reverse order
                 term_write_lowlevel(TERMINAL_ID<<3|e);   //terminal attention
                term_write_lowlevel(i);
                delay(1);
                term_end_transfer();          //terminal disconnect from mainframe
                delay(10);
              }
            }
            delay(100);
            break;
        case '6':
          Serial.println("six");
                                          //terminal connect to mainframe
            term_sync_bitcounter();       // sync bit counter to ensure we are word aligned

              for(int i=0;i<0xff;i++){
                // if(isprint(i)){
                  term_begin_transfer();        //   i think these two lines can happen in reverse order
                 term_write_lowlevel(TERMINAL_ID<<3|STATE_FLAG_2);   //terminal attention
                  term_write_lowlevel(TERMINAL_ID<<3|STATE_FLAG_2|STATE_FLAG_1);   //terminal attention
                   term_write_lowlevel(i);
                  term_end_transfer();          //terminal disconnect from mainframe
                  term_begin_transfer();        //   i think these two lines can happen in reverse order
                  term_end_transfer();          //terminal disconnect from mainframe
                // }                
                delay(10);
              }
            delay(100);
            break;
        case '7':
          Serial.println("seven");
                                          //terminal connect to mainframe
            term_sync_bitcounter();       // sync bit counter to ensure we are word aligned

              for(int i=0;i<0xff;i++){
                // if(isprint(i)){
                  term_clock_rts();
                 term_write_lowlevel(TERMINAL_ID<<3|STATE_FLAG_2);   //terminal attention
                  term_clock_rts();
                   term_write_lowlevel(i);
                // }                
                delay(10);
              }
            delay(100);
            break;
        case '8':
          Serial.println("eight");
                                          //terminal connect to mainframe
            term_sync_bitcounter();       // sync bit counter to ensure we are word aligned

              for(int i=0;i<0xff;i++){
                // if(isprint(i)){
                  term_clock_rts();
                 term_write_lowlevel(TERMINAL_ID<<3|STATE_FLAG_1);   //terminal attention
                  term_clock_rts();
                   term_write_lowlevel(swapBitOrder(i));
                // }                
                delay(10);
              }
            delay(100);
            break;
        case '9':
          Serial.println("nine");
                                          //terminal connect to mainframe
            term_sync_bitcounter();       // sync bit counter to ensure we are word aligned

              for(int i=0;i<0xff;i++){
                // if(isprint(i)){
                 term_write_lowlevel(swapBitOrder(TERMINAL_ID<<3|STATE_FLAG_1));   //terminal attention
                  term_clock_rts();
                   term_write_lowlevel(swapBitOrder(i));
                  term_clock_rts();
                // }                
                delay(10);
              }
            delay(100);
            break;
        case 'A':
          Serial.println("aeeee");
                                          //terminal connect to mainframe
            term_sync_bitcounter();       // sync bit counter to ensure we are word aligned

              for(int i=0;i<0xff;i++){
                // if(isprint(i)){
                 term_write_lowlevel(TERMINAL_ID<<3|STATE_FLAG_1);   //terminal attention
                  term_clock_rts();
                   term_write_lowlevel(i);
                  term_clock_rts();
                  delay(1);

                 term_write_lowlevel(TERMINAL_ID<<3|STATE_FLAG_1 |STATE_FLAG_2);   //terminal attention
                  term_clock_rts();
                   term_write_lowlevel(i);
                  term_clock_rts();
                  delay(1);
                // }                
                delay(10);
              }
            delay(100);
            break;


    }

  }

  }




void term_clock_rts(){

    digitalWrite(RTS_PIN, LOW); //logic positive logic verified.. idle state of the line is high
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

  return  mySPI.transfer16((0xfe<<8) | word_0); //9 bit transfer hack seems to work ith the cards state machine without consequence
  delay(4);  //will need tightening
}


uint16_t term_read_lowlevel(uint8_t termid, uint8_t cmd){


}