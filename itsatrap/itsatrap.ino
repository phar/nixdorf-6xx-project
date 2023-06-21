/*

BSYNC:  pin 7
BDIR:    pin 6

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
E         |-      |         |           |                       BSYNC    TERMINAL
G         |-       \------------------------------------------>N         
A         |-                |           |
2      SCK|-o>----+------>o-|5         7|-o>------------------>P
5         |-      |          -----------                        CLK
6         |-       \------------------------------------------>J
0         |-                          
         6|-o<------------------------------------------------<C BDIR (positive logic pin only)              
      MISO|-o<------------------------------------------------<B RX  (positive logic pin only)          
 */

#include <SPI.h>

uint8_t term_write_lowlevel(uint8_t word_0);

void terminal_print(uint8_t terminal_id, char * str);
void sync_bitcounter();


#define  MOSI_PIN  2
#define  MISO_PIN  5 
#define  SCK_PIN  4
#define  BDIR_PIN  6
#define  BSYNC_PIN  7
#define  CLOCK_PIN  4
#define  BIT_SPEED  2000


#define MAGIC_CHARACTER  0xA5
#define CRLF_CHARACTER  0xA8

#define BEEP_CHARACTER  0xA9  //out 0x04 to port 50
#define LED_CHARACTER  0xA7  //out 0x01 to port 50
// #define CRLF_CHARACTER  0xA2
// #define CRLF_CHARACTER  0xA0
// #define CRLF_CHARACTER  0xA3
// #define CRLF_CHARACTER  0xA4  //call mask display (clear screen?)

#define WHITESPACE2_CHARACTER  0xB6
#define WHITESPACE3_CHARACTER  0xB8
#define VERTICAL_TAB_CHARACTER 0x0B
#define BACKSPACE_CHARACTER    0x08
#define LINEFEED_CHARACTER    0x0a

#define mySPI SPI

void setup() {

  Serial.begin(9600);
  SPI.begin();

  SPI.begin();
  SPI.setClockDivider(SPI_CLOCK_DIV128); //slow things down if needed
  SPI.setBitOrder(LSBFIRST);
  SPI.setDataMode(SPI_MODE2);
  pinMode(BSYNC_PIN,OUTPUT);
  pinMode(BDIR_PIN, INPUT_PULLUP);
}


#define STATE_FLAG_0 0x80
#define S_CHAR_TO_TERM 0x40 
#define STATE_FLAG_2 0x20   //targets UF7A


#define TERMINAL_ID 0x0a
#define COMMAND_MODE  0
#define ECHO_MODE     1

int MODE = COMMAND_MODE;

void loop() {
int t;
unsigned long s;
int f = 0;
uint8_t word_0 = 0;
uint8_t word_1 = 0;

  if(Serial.available()){
    if(MODE == COMMAND_MODE){
      switch(Serial.read()){ 
          case 'E':
            Serial.print("echo mode enabled. reboot to re-enter command mode\n");
            MODE = ECHO_MODE;
            break;

          case 'F':
            terminal_print(TERMINAL_ID, "hello world!\n");

              delay(100);
              for(int i=0;i<0xff;i++){ 
                if(isprint(i)){
                  terminal_attention(TERMINAL_ID, S_CHAR_TO_TERM);
                    delay(2);
                    term_write_lowlevel(i);
                    term_bsync();
                    delay(4); 
                }
              }  
              terminal_print(TERMINAL_ID,"\n");            
              delay(100);
              for(int i=0;i<0xff;i++){ 
                if(isprint(i)){
                    terminal_attention(TERMINAL_ID, S_CHAR_TO_TERM);
                    delay(1);
                    term_write_lowlevel(i);
                    term_bsync();
                    delay(5); 
                }
            }  
            break;
            
        case 'G':
          terminal_print(TERMINAL_ID, "hello world!\r\n");
          terminal_print(TERMINAL_ID, "hello world!\n");
          for(int i=0;i<10;i++){
            terminal_print(TERMINAL_ID, "\xa7");
            delay(500);
          }
          break;
          
        case 'H':
          terminal_print(TERMINAL_ID, "hello world!\r\n");
          terminal_print(TERMINAL_ID, "hello world!\xA8");
          terminal_print(TERMINAL_ID, "hello world!\n");
          
          for(int i=0;i<10;i++){
            terminal_print(TERMINAL_ID, "\xa9");
            delay(500);
          }
          break;        
            
        }
      }
  }else if(MODE == ECHO_MODE){
    char c = Serial.read();
    terminal_send(TERMINAL_ID, &c, 1);
  }



  }




void term_bsync(){
    digitalWrite(BSYNC_PIN, LOW); //logic positive logic verified.. idle state of the line is high
    delayMicroseconds(5);
    digitalWrite(BSYNC_PIN, HIGH);
}


void sync_bitcounter(){
    SPI.transfer(0xff);
    SPI.transfer(0xff);
}


void terminal_println(uint8_t terminal_id, char * instr){
  terminal_print(terminal_id, instr);
  terminal_print(terminal_id, "\n");
}

void terminal_print(uint8_t terminal_id, char * instr){
int e;

  terminal_send(terminal_id, instr, strlen(instr));
}

void terminal_send(uint8_t terminal_id, char * buff, uint16_t bufflen){
int e;

  for(e=0;bufflen;e++){
    terminal_attention(terminal_id, S_CHAR_TO_TERM);
    delay(1);
    term_write_lowlevel(buff[e]);
    term_bsync();
    delay(1);    //might be able to yank this out 
  }
}



bool terminal_attention(uint8_t terminal_id, uint8_t command){

   term_write_lowlevel(terminal_id|command);

//fixme, everuthing after tthis is wacky, and im not sure how ot treat recv yet

  if(command & STATE_FLAG_0){ 

  }

  if(command & S_CHAR_TO_TERM){

    return true;
  }
  
  if(command & STATE_FLAG_2){
 
  }


}

uint8_t term_write_lowlevel(uint8_t word_0){

  return  SPI.transfer16( (word_0 << 8) | 0x7f); //9 bit transfer hack seems to work ith the cards state machine without consequence
  delay(4);  //will need tightening
}


uint16_t term_read_lowlevel(uint8_t termid, uint8_t cmd){
}