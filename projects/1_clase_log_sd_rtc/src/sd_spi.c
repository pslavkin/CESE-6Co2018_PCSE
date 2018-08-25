#include "sd_spi.h"   // <= own header (optional)
#include "sapi.h"     // <= sAPI header
#include "ff.h"       // <= Biblioteca FAT FS
/*==================[definiciones y macros]==================================*/
#define FILENAME "hola.txt"
/*==================[definiciones de datos internos]=========================*/
static FATFS   fs;                         // <-- FatFs work area needed for each volume
static FIL     fp;                         // <-- File object needed for each open file

void diskTickHook( void *ptr );            // FUNCION que se ejecuta cada vezque ocurre un Tick

int main( void ){
   boardConfig();                          // Inicializar y configurar la plataforma
   spiConfig( SPI0 );                      // SPI configuration

   tickConfig      ( 10                 );
   tickCallbackSet ( diskTickHook, NULL ); // Inicializar el conteo de Ticks con resolucion de 10ms,
                                           // con tickHook diskTickHook

   UINT nbytes;

   // Give a work area to the default drive
   if( f_mount( &fs, "", 0 ) != FR_OK ){
      // If this fails, it means that the function could
      // not register a file system object.
      // Check whether the SD card is correctly connected
      gpioWrite( LEDB, ON ); 
   }
   else {
      uint8_t i=0;

      for( i=0; i<5; i++ ){
         if( f_open( &fp, FILENAME, FA_WRITE | FA_OPEN_APPEND ) == FR_OK ){
            f_write( &fp, "Hola pablo mundo\r\n", 18, &nbytes );
            f_close(&fp);
            if( nbytes == 18 ){
               gpioWrite( LEDG, ON ); // Turn ON LEDG if the write operation was successful
            }
         } else{
            gpioWrite( LEDR, ON );    // Turn ON LEDR if the write operation was fail
         }
      }
   }
   while( TRUE )
   {
      sleepUntilNextInterrupt();
   }
   return 0;
}

void diskTickHook( void *ptr ){ // FUNCION que se ejecuta cada vezque ocurre un Tick
   disk_timerproc();            // Disk timer process
}
